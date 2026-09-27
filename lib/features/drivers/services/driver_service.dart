import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_service.dart';
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

  void _initFirestoreStream() {
    if (!FirebaseService.isInitialized) {
      debugPrint('[DriverService] Firestore not initialized (offline or test).');
      return;
    }

    try {
      final collection = FirebaseFirestore.instance.collection('valet_intakes');
      _intakesSubscription = collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _intakes.clear();
          for (final doc in snapshot.docs) {
            try {
              _intakes.add(VehicleIntakeModel.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('[DriverService] Error parsing intake doc ${doc.id}: $e');
            }
          }
          notifyListeners();
        },
        onError: (error) {
          debugPrint('[DriverService] Firestore stream error: $error');
        },
      );
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
    notifyListeners();

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
