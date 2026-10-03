import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/customer_retention_service.dart';
import '../../../core/widgets/hud_chip.dart';
import '../../admin/operations/models/valet_ticket.dart';
import '../../admin/operations/services/ticket_repository.dart';
import '../../admin/operations/services/vehicle_condition_repository.dart';
import '../models/vehicle_intake_model.dart';
import 'attendance_repository.dart';

/// Central singleton service managing driver on-duty state, vehicle intake submissions,
/// and live Firestore sync with resilient offline fallback.
class DriverService extends ChangeNotifier {
  static final DriverService instance = DriverService._internal();

  DriverService._internal() {
    _initFirestoreStream();
  }

  bool _isOnDuty = true;
  bool get isOnDuty => _isOnDuty;

  final List<VehicleIntakeModel> _intakes = [];
  List<VehicleIntakeModel> get intakes => List.unmodifiable(_intakes);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _intakesSubscription;

  void ensureFirestoreStream() {
    if (_intakesSubscription == null && FirebaseService.isInitialized) {
      _initFirestoreStream();
    }
  }

  void _initFirestoreStream() {
    if (!FirebaseService.isInitialized) {
      debugPrint('[DriverService] Firestore not initialized (offline or test).');
      return;
    }

    try {
      final collection = FirebaseFirestore.instance.collection(FirebaseService.intakesCollection);
      _intakesSubscription = collection
          .snapshots()
          .listen(
        (snapshot) {
          _intakes.clear();
          final cutoff = CustomerRetentionService.cutoffDate;
          for (final doc in snapshot.docs) {
            try {
              final intake = VehicleIntakeModel.fromMap(doc.data(), doc.id);
              // Retain only customer records within the last 90 days
              if (!intake.createdAt.isBefore(cutoff)) {
                _intakes.add(intake);
              }
            } catch (e) {
              debugPrint('[DriverService] Error parsing intake doc ${doc.id}: $e');
            }
          }
          _intakes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (error) {
          debugPrint('[DriverService] Firestore stream error: $error');
        },
      );

      // Trigger automatic purge of customer records older than 90 days from the database
      CustomerRetentionService.instance.purgeExpiredRecords();
    } catch (e) {
      debugPrint('[DriverService] Exception setting up Firestore stream: $e');
    }
  }

  /// Toggles the driver's duty status and syncs attendance.
  Future<void> toggleDutyStatus({
    String? valetId,
    String? userId,
    String? organizationId,
    String? locationId,
  }) async {
    _isOnDuty = !_isOnDuty;
    notifyListeners();

    if (valetId != null && valetId.isNotEmpty) {
      try {
        if (_isOnDuty) {
          await AttendanceRepository.instance.checkIn(
            valetId: valetId,
            userId: userId ?? valetId,
            organizationId: organizationId ?? 'default_org',
            locationId: locationId ?? 'default_loc',
          );
        } else {
          await AttendanceRepository.instance.checkOut(valetId: valetId);
        }
      } catch (e) {
        debugPrint('[DriverService] Attendance sync notice: $e');
      }
    }
  }

  /// Sets the driver's duty status explicitly.
  Future<void> setDutyStatus(
    bool status, {
    String? valetId,
    String? userId,
    String? organizationId,
    String? locationId,
  }) async {
    if (_isOnDuty != status) {
      _isOnDuty = status;
      notifyListeners();

      if (valetId != null && valetId.isNotEmpty) {
        try {
          if (_isOnDuty) {
            await AttendanceRepository.instance.checkIn(
              valetId: valetId,
              userId: userId ?? valetId,
              organizationId: organizationId ?? 'default_org',
              locationId: locationId ?? 'default_loc',
            );
          } else {
            await AttendanceRepository.instance.checkOut(valetId: valetId);
          }
        } catch (e) {
          debugPrint('[DriverService] Attendance sync notice: $e');
        }
      }
    }
  }

  /// Registers and submits a new vehicle intake.
  Future<void> submitIntake(
    VehicleIntakeModel intake, {
    String organizationId = 'default_org',
    String locationId = 'default_loc',
  }) async {
    // Add locally immediately for instantaneous UI updates
    _intakes.insert(0, intake);
    _pruneExpiredIntakes();
    notifyListeners();

    // Enforce database retention asynchronously
    CustomerRetentionService.instance.purgeExpiredRecords();

    final numPart = intake.id.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanTicketNum = '#${numPart.isNotEmpty ? numPart : (1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';

    // Record vehicle condition
    final conditionRecord = VehicleConditionRecord(
      id: 'cond_${intake.id}',
      ticketId: cleanTicketNum,
      vehicleNumber: intake.vehicleReg,
      conditionNotes: 'Intake completed with pre-inspection verification.',
      photoUrls: (intake.photoName != null && intake.photoName!.isNotEmpty)
          ? [intake.photoName!]
          : [],
      recordedBy: intake.driverId,
      recordedAt: intake.createdAt,
    );
    await VehicleConditionRepository.instance.recordCondition(conditionRecord);

    // Create ValetTicket
    final valetTicket = ValetTicket(
      id: intake.id,
      ticketNumber: cleanTicketNum,
      licensePlate: intake.vehicleReg,
      carModel: intake.vehicleModel,
      color: 'Silver',
      customerName: intake.customerName,
      customerPhone: intake.customerPhone,
      siteName: intake.siteName.replaceAll(' • Valet Desk', '').trim(),
      siteShort: intake.siteName.split(' ').first,
      locationSlot: 'Valet Deck Intake',
      staffName: intake.driverName,
      staffId: intake.driverId,
      staffRole: 'VALET',
      status: OperationalStatus.inTransit,
      statusText: 'VEHICLE RECEIVED',
      checkInTime: intake.createdAt,
      organizationId: organizationId,
      locationId: locationId,
      assignedValetId: intake.driverId,
      lifecycleStatus: TicketLifecycleStatus.vehicleReceived,
      vehicleReceivedAt: intake.createdAt,
      createdAt: intake.createdAt,
    );

    await TicketRepository.instance.createTicket(valetTicket);

    // Persist to Firestore if available
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('valet_intakes')
            .doc(intake.id)
            .set(intake.toMap());
        debugPrint('[DriverService] Intake ${intake.id} saved to Firestore.');
      } catch (e) {
        debugPrint('[DriverService] Error saving intake to Firestore: $e');
      }
    }
  }

  /// Updates the status and optional metadata of an intake in-memory and in Firestore.
  Future<void> updateIntakeStatus(
    String intakeId,
    String status, {
    Map<String, dynamic>? extraData,
  }) async {
    final index = _intakes.indexWhere((i) => i.id == intakeId);
    if (index >= 0) {
      final current = _intakes[index];
      final updatedKeyTag = extraData?['keyTag'] as String? ?? current.keyTag;
      final updatedPaymentStatus = extraData?['paymentStatus'] as String? ?? current.paymentStatus;
      final updatedPaymentMode = extraData?['paymentMode'] as String? ?? current.paymentMode;
      final updatedPaymentAmount = (extraData?['paymentAmount'] as num?)?.toDouble() ?? current.paymentAmount;
      final updatedPaidAt = extraData?['paidAt'] is DateTime ? extraData!['paidAt'] as DateTime : current.paidAt;
      final dynamic reqAtRaw = extraData?['retrievalRequestedAt'];
      final DateTime? updatedReqAt = reqAtRaw is DateTime
          ? reqAtRaw
          : (reqAtRaw is String
              ? DateTime.tryParse(reqAtRaw)
              : (status == 'retrieval_requested' && current.retrievalRequestedAt == null
                  ? DateTime.now()
                  : current.retrievalRequestedAt));
      final updatedAssignedDriverId = extraData?['assignedDriverId'] as String? ?? current.assignedDriverId;
      final updatedAssignedDriverName = extraData?['assignedDriverName'] as String? ?? current.assignedDriverName;

      _intakes[index] = current.copyWith(
        status: status,
        keyTag: updatedKeyTag,
        paymentStatus: updatedPaymentStatus,
        paymentMode: updatedPaymentMode,
        paymentAmount: updatedPaymentAmount,
        paidAt: updatedPaidAt,
        retrievalRequestedAt: updatedReqAt,
        assignedDriverId: updatedAssignedDriverId,
        assignedDriverName: updatedAssignedDriverName,
      );
      notifyListeners();
    } else {
      final dynamic reqAtRaw = extraData?['retrievalRequestedAt'];
      final DateTime? reqAt = reqAtRaw is DateTime
          ? reqAtRaw
          : (reqAtRaw is String
              ? DateTime.tryParse(reqAtRaw)
              : (status == 'retrieval_requested' ? DateTime.now() : null));

      _intakes.insert(
        0,
        VehicleIntakeModel(
          id: intakeId,
          customerName: extraData?['customerName'] as String? ?? 'Guest Customer',
          customerPhone: extraData?['customerPhone'] as String? ?? '',
          vehicleReg: extraData?['vehicleReg'] as String? ?? '',
          vehicleModel: extraData?['vehicleModel'] as String? ?? 'Valet Vehicle',
          driverId: extraData?['driverId'] as String? ?? '',
          driverName: extraData?['driverName'] as String? ?? '',
          siteName: extraData?['siteName'] as String? ?? 'Valet Deck',
          status: status,
          createdAt: DateTime.now(),
          keyTag: extraData?['keyTag'] as String?,
          paymentStatus: extraData?['paymentStatus'] as String? ?? 'unpaid',
          paymentMode: extraData?['paymentMode'] as String? ?? '',
          paymentAmount: (extraData?['paymentAmount'] as num?)?.toDouble(),
          retrievalRequestedAt: reqAt,
          assignedDriverId: extraData?['assignedDriverId'] as String?,
          assignedDriverName: extraData?['assignedDriverName'] as String?,
        ),
      );
      notifyListeners();
    }

    if (FirebaseService.isInitialized) {
      try {
        final updatePayload = <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          ...?extraData,
        };

        await FirebaseFirestore.instance
            .collection('valet_intakes')
            .doc(intakeId)
            .set(updatePayload, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection(FirebaseService.ticketsCollection)
            .doc(intakeId)
            .set({
              'statusText': status == 'waiting_for_parking'
                  ? 'WAITING FOR PARKING'
                  : status.toUpperCase(),
              'waitingForParkingAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              ...?extraData,
            }, SetOptions(merge: true));

        debugPrint('[DriverService] Intake $intakeId updated to $status in Firestore.');
      } catch (e) {
        debugPrint('[DriverService] Error updating intake status in Firestore: $e');
      }
    }
  }

  /// Records payment directly on the intake and syncs to Firestore
  Future<void> updateIntakePayment(
    String intakeId, {
    required String paymentMode,
    required double amount,
    String? siteName,
  }) async {
    final statusStr = paymentMode == 'cash' ? 'paid_cash' : 'paid_online';
    final now = DateTime.now();

    final index = _intakes.indexWhere((i) => i.id == intakeId);
    if (index >= 0) {
      final current = _intakes[index];
      _intakes[index] = current.copyWith(
        paymentStatus: statusStr,
        paymentMode: paymentMode,
        paymentAmount: amount,
        paidAt: now,
      );
      notifyListeners();
    }

    if (FirebaseService.isInitialized) {
      try {
        final payload = <String, dynamic>{
          'paymentStatus': statusStr,
          'paymentMode': paymentMode,
          'paymentAmount': amount,
          'paidAt': FieldValue.serverTimestamp(),
          'paidSite': ?siteName,
        };

        await FirebaseFirestore.instance
            .collection('valet_intakes')
            .doc(intakeId)
            .set(payload, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection(FirebaseService.ticketsCollection)
            .doc(intakeId)
            .set(payload, SetOptions(merge: true));
        debugPrint('[DriverService] Payment for $intakeId synced to Firestore ($statusStr).');
      } catch (e) {
        debugPrint('[DriverService] Error updating payment in Firestore: $e');
      }
    }
  }

  /// Deletes an intake from in-memory and Firestore store.
  Future<void> deleteIntake(String intakeId) async {
    _intakes.removeWhere((i) => i.id == intakeId);
    notifyListeners();
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('valet_intakes')
            .doc(intakeId)
            .delete();
      } catch (e) {
        debugPrint('[DriverService] Error deleting intake: $e');
      }
    }
  }

  /// Prunes in-memory intakes older than the 90-day retention window.
  void _pruneExpiredIntakes() {
    final cutoff = CustomerRetentionService.cutoffDate;
    _intakes.removeWhere((i) => i.createdAt.isBefore(cutoff));
  }

  /// Manually enforces the customer details retention policy (90 days) on memory and database.
  Future<int> enforceRetentionPolicy({int days = CustomerRetentionService.retentionDays}) async {
    _pruneExpiredIntakes();
    notifyListeners();
    return CustomerRetentionService.instance.purgeExpiredRecords(days: days);
  }

  /// Clears in-memory intakes (used in test fixtures).
  void clearIntakes() {
    _intakes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _intakesSubscription?.cancel();
    super.dispose();
  }
}
