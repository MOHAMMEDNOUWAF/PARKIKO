import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/customer_retention_service.dart';
import '../../../../core/widgets/hud_chip.dart';
import '../models/valet_ticket.dart';
import 'audit_repository.dart';

/// Exception thrown when a valet tries to claim a pickup job that has already been claimed.
class JobAlreadyClaimedException implements Exception {
  final String message;
  const JobAlreadyClaimedException([this.message = 'This pickup job has already been claimed by another valet.']);
  @override
  String toString() => message;
}

/// Exception thrown when a valet tries to claim a vehicle retrieval that has already been claimed.
class RetrievalAlreadyClaimedException implements Exception {
  final String message;
  const RetrievalAlreadyClaimedException([this.message = 'This retrieval request has already been claimed by another valet.']);
  @override
  String toString() => message;
}

/// Exception thrown when an illegal status change is attempted.
class InvalidStatusTransitionException implements Exception {
  final String message;
  const InvalidStatusTransitionException(this.message);
  @override
  String toString() => message;
}

/// Exception thrown when a ticket is not found in Firestore or in-memory store.
class TicketNotFoundException implements Exception {
  final String message;
  const TicketNotFoundException([this.message = 'The requested valet ticket was not found.']);
  @override
  String toString() => message;
}

/// Repository for valet ticket lifecycle transitions, atomic concurrency control,
/// and role/location-scoped data retrieval.
class TicketRepository {
  static final TicketRepository instance = TicketRepository._internal();
  TicketRepository._internal();

  final List<ValetTicket> _inMemoryTickets = [];
  final _inMemoryController = StreamController<List<ValetTicket>>.broadcast();

  List<ValetTicket> get inMemoryTickets => List.unmodifiable(_inMemoryTickets);

  /// Seeds or adds a ticket to the store.
  Future<void> createTicket(ValetTicket ticket) async {
    final existingIdx = _inMemoryTickets.indexWhere((t) => t.id == ticket.id);
    if (existingIdx >= 0) {
      _inMemoryTickets[existingIdx] = ticket;
    } else {
      _inMemoryTickets.add(ticket);
    }
    _pruneExpiredTickets();
    _inMemoryController.add(List.unmodifiable(_inMemoryTickets));

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection(FirebaseService.ticketsCollection)
            .doc(ticket.id)
            .set(ticket.toMap(), SetOptions(merge: true));

        await AuditRepository.instance.logEvent(
          ticketId: ticket.ticketNumber.isNotEmpty ? ticket.ticketNumber : ticket.id,
          organizationId: ticket.organizationId,
          locationId: ticket.locationId,
          performedBy: ticket.staffId.isNotEmpty ? ticket.staffId : 'SYSTEM',
          performedByRole: ticket.staffRole.isNotEmpty ? ticket.staffRole : 'VALET',
          action: 'CREATE_TICKET',
          fromStatus: 'NONE',
          toStatus: ticket.lifecycleStatus.value,
        );
      } catch (e) {
        debugPrint('[TicketRepository] Error creating ticket in Firestore: $e');
      }
    }
  }

  /// Atomically claims a pending pickup job for a valet using Firestore transactions.
  Future<ValetTicket> acceptPickupJob({
    required String ticketId,
    required String valetId,
    required String locationId,
  }) async {
    if (!FirebaseService.isInitialized) {
      // In-memory concurrency check
      final index = _inMemoryTickets.indexWhere((t) => t.id == ticketId || t.ticketNumber == ticketId);
      if (index < 0) throw const TicketNotFoundException();

      final current = _inMemoryTickets[index];
      if (current.assignedValetId != null &&
          current.assignedValetId!.isNotEmpty &&
          current.assignedValetId != valetId) {
        throw const JobAlreadyClaimedException();
      }

      if (current.lifecycleStatus != TicketLifecycleStatus.waitingForPickup &&
          current.lifecycleStatus != TicketLifecycleStatus.created &&
          current.lifecycleStatus != TicketLifecycleStatus.assigned) {
        throw InvalidStatusTransitionException(
          'Cannot accept pickup job in status ${current.lifecycleStatus.value}',
        );
      }

      final updated = current.copyWith(
        assignedValetId: valetId,
        lifecycleStatus: TicketLifecycleStatus.accepted,
        acceptedAt: DateTime.now(),
        status: OperationalStatus.inTransit,
        statusText: 'ACCEPTED',
      );
      _inMemoryTickets[index] = updated;
      _inMemoryController.add(List.unmodifiable(_inMemoryTickets));

      await AuditRepository.instance.logEvent(
        ticketId: updated.ticketNumber.isNotEmpty ? updated.ticketNumber : updated.id,
        organizationId: updated.organizationId,
        locationId: updated.locationId,
        performedBy: valetId,
        performedByRole: 'VALET',
        action: 'ACCEPT_PICKUP_JOB',
        fromStatus: current.lifecycleStatus.value,
        toStatus: TicketLifecycleStatus.accepted.value,
      );

      return updated;
    }

    final docRef = FirebaseFirestore.instance.collection(FirebaseService.ticketsCollection).doc(ticketId);

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw const TicketNotFoundException();
      }

      final data = snapshot.data()!;
      final currentTicket = ValetTicket.fromMap(data, snapshot.id);

      // Verify location isolation
      if (locationId.isNotEmpty &&
          currentTicket.locationId.isNotEmpty &&
          currentTicket.locationId != 'default_loc' &&
          currentTicket.locationId != locationId) {
        throw const InvalidStatusTransitionException('Unauthorized: Valet is not assigned to this location.');
      }

      // Concurrency check: must not be claimed by another valet
      if (currentTicket.assignedValetId != null &&
          currentTicket.assignedValetId!.isNotEmpty &&
          currentTicket.assignedValetId != valetId) {
        throw const JobAlreadyClaimedException();
      }

      if (!currentTicket.lifecycleStatus.canTransitionTo(TicketLifecycleStatus.accepted)) {
        throw InvalidStatusTransitionException(
          'Cannot accept pickup job in status ${currentTicket.lifecycleStatus.value}',
        );
      }

      final now = DateTime.now();
      final updated = currentTicket.copyWith(
        assignedValetId: valetId,
        lifecycleStatus: TicketLifecycleStatus.accepted,
        acceptedAt: now,
        status: OperationalStatus.inTransit,
        statusText: 'ACCEPTED',
      );

      transaction.update(docRef, {
        'assignedValetId': valetId,
        'lifecycleStatus': TicketLifecycleStatus.accepted.value,
        'status': OperationalStatus.inTransit.name,
        'statusText': 'ACCEPTED',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      return updated;
    }).then((updatedTicket) async {
      await AuditRepository.instance.logEvent(
        ticketId: updatedTicket.ticketNumber.isNotEmpty ? updatedTicket.ticketNumber : updatedTicket.id,
        organizationId: updatedTicket.organizationId,
        locationId: updatedTicket.locationId,
        performedBy: valetId,
        performedByRole: 'VALET',
        action: 'ACCEPT_PICKUP_JOB',
        fromStatus: TicketLifecycleStatus.waitingForPickup.value,
        toStatus: TicketLifecycleStatus.accepted.value,
      );
      return updatedTicket;
    });
  }

  /// Confirms that the valet has reached the vehicle and received it from customer.
  Future<ValetTicket> confirmVehicleReceived({
    required String ticketId,
    required String valetId,
  }) async {
    return _transitionStatus(
      ticketId: ticketId,
      valetId: valetId,
      targetStatus: TicketLifecycleStatus.vehicleReceived,
      statusText: 'VEHICLE RECEIVED',
      operationalStatus: OperationalStatus.inTransit,
      actionName: 'CONFIRM_VEHICLE_RECEIVED',
      updateFields: {
        'vehicleReceivedAt': FieldValue.serverTimestamp(),
      },
      applyLocalUpdate: (ticket, now) => ticket.copyWith(
        lifecycleStatus: TicketLifecycleStatus.vehicleReceived,
        vehicleReceivedAt: now,
        statusText: 'VEHICLE RECEIVED',
        status: OperationalStatus.inTransit,
      ),
    );
  }

  /// Begins parking procedure for the vehicle.
  Future<ValetTicket> startParking({
    required String ticketId,
    required String valetId,
  }) async {
    return _transitionStatus(
      ticketId: ticketId,
      valetId: valetId,
      targetStatus: TicketLifecycleStatus.parking,
      statusText: 'PARKING',
      operationalStatus: OperationalStatus.inTransit,
      actionName: 'START_PARKING',
      updateFields: {
        'parkingStartedAt': FieldValue.serverTimestamp(),
      },
      applyLocalUpdate: (ticket, now) => ticket.copyWith(
        lifecycleStatus: TicketLifecycleStatus.parking,
        parkingStartedAt: now,
        statusText: 'PARKING',
        status: OperationalStatus.inTransit,
      ),
    );
  }

  /// Confirms that the vehicle has been safely parked.
  Future<ValetTicket> confirmVehicleParked({
    required String ticketId,
    required String valetId,
    String? locationSlot,
  }) async {
    return _transitionStatus(
      ticketId: ticketId,
      valetId: valetId,
      targetStatus: TicketLifecycleStatus.parked,
      statusText: 'PARKED',
      operationalStatus: OperationalStatus.occupied,
      actionName: 'CONFIRM_VEHICLE_PARKED',
      updateFields: {
        'parkedAt': FieldValue.serverTimestamp(),
        'locationSlot': ?locationSlot,
      },
      applyLocalUpdate: (ticket, now) => ticket.copyWith(
        lifecycleStatus: TicketLifecycleStatus.parked,
        parkedAt: now,
        locationSlot: locationSlot ?? ticket.locationSlot,
        statusText: 'PARKED',
        status: OperationalStatus.occupied,
      ),
    );
  }

  /// Manager/Assistant workflow: requests customer vehicle retrieval.
  Future<ValetTicket> requestRetrieval({
    required String ticketId,
    required String requestedBy,
  }) async {
    return _transitionStatus(
      ticketId: ticketId,
      valetId: requestedBy,
      targetStatus: TicketLifecycleStatus.retrievalRequested,
      statusText: 'RETRIEVAL REQUESTED',
      operationalStatus: OperationalStatus.queue,
      actionName: 'REQUEST_RETRIEVAL',
      updateFields: {
        'retrievalRequestedAt': FieldValue.serverTimestamp(),
      },
      applyLocalUpdate: (ticket, now) => ticket.copyWith(
        lifecycleStatus: TicketLifecycleStatus.retrievalRequested,
        retrievalRequestedAt: now,
        statusText: 'RETRIEVAL REQUESTED',
        status: OperationalStatus.queue,
      ),
    );
  }

  /// Atomically claims a vehicle retrieval request using Firestore transactions.
  Future<ValetTicket> acceptRetrieval({
    required String ticketId,
    required String valetId,
    required String locationId,
  }) async {
    if (!FirebaseService.isInitialized) {
      final index = _inMemoryTickets.indexWhere((t) => t.id == ticketId || t.ticketNumber == ticketId);
      if (index < 0) throw const TicketNotFoundException();

      final current = _inMemoryTickets[index];
      if (current.retrievalValetId != null &&
          current.retrievalValetId!.isNotEmpty &&
          current.retrievalValetId != valetId) {
        throw const RetrievalAlreadyClaimedException();
      }

      if (current.lifecycleStatus != TicketLifecycleStatus.retrievalRequested &&
          current.lifecycleStatus != TicketLifecycleStatus.parked) {
        throw InvalidStatusTransitionException(
          'Cannot claim retrieval in status ${current.lifecycleStatus.value}',
        );
      }

      final updated = current.copyWith(
        retrievalValetId: valetId,
        lifecycleStatus: TicketLifecycleStatus.retrieving,
        retrievalStartedAt: DateTime.now(),
        status: OperationalStatus.inTransit,
        statusText: 'RETRIEVING',
      );
      _inMemoryTickets[index] = updated;
      _inMemoryController.add(List.unmodifiable(_inMemoryTickets));

      await AuditRepository.instance.logEvent(
        ticketId: updated.ticketNumber.isNotEmpty ? updated.ticketNumber : updated.id,
        organizationId: updated.organizationId,
        locationId: updated.locationId,
        performedBy: valetId,
        performedByRole: 'VALET',
        action: 'ACCEPT_RETRIEVAL',
        fromStatus: current.lifecycleStatus.value,
        toStatus: TicketLifecycleStatus.retrieving.value,
      );

      return updated;
    }

    final docRef = FirebaseFirestore.instance.collection(FirebaseService.ticketsCollection).doc(ticketId);

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw const TicketNotFoundException();

      final data = snapshot.data()!;
      final currentTicket = ValetTicket.fromMap(data, snapshot.id);

      if (currentTicket.retrievalValetId != null &&
          currentTicket.retrievalValetId!.isNotEmpty &&
          currentTicket.retrievalValetId != valetId) {
        throw const RetrievalAlreadyClaimedException();
      }

      if (!currentTicket.lifecycleStatus.canTransitionTo(TicketLifecycleStatus.retrieving)) {
        throw InvalidStatusTransitionException(
          'Cannot transition ticket ${currentTicket.id} from ${currentTicket.lifecycleStatus.value} to RETRIEVING',
        );
      }

      final now = DateTime.now();
      final updated = currentTicket.copyWith(
        retrievalValetId: valetId,
        lifecycleStatus: TicketLifecycleStatus.retrieving,
        retrievalStartedAt: now,
        status: OperationalStatus.inTransit,
        statusText: 'RETRIEVING',
      );

      transaction.update(docRef, {
        'retrievalValetId': valetId,
        'lifecycleStatus': TicketLifecycleStatus.retrieving.value,
        'status': OperationalStatus.inTransit.name,
        'statusText': 'RETRIEVING',
        'retrievalStartedAt': FieldValue.serverTimestamp(),
      });

      return updated;
    }).then((updatedTicket) async {
      await AuditRepository.instance.logEvent(
        ticketId: updatedTicket.ticketNumber.isNotEmpty ? updatedTicket.ticketNumber : updatedTicket.id,
        organizationId: updatedTicket.organizationId,
        locationId: updatedTicket.locationId,
        performedBy: valetId,
        performedByRole: 'VALET',
        action: 'ACCEPT_RETRIEVAL',
        fromStatus: TicketLifecycleStatus.retrievalRequested.value,
        toStatus: TicketLifecycleStatus.retrieving.value,
      );
      return updatedTicket;
    });
  }

  /// Confirms that the valet has retrieved the vehicle from the parking bay.
  Future<ValetTicket> confirmVehicleRetrieved({
    required String ticketId,
    required String valetId,
  }) async {
    final updated = await _transitionStatus(
      ticketId: ticketId,
      valetId: valetId,
      targetStatus: TicketLifecycleStatus.vehicleRetrieved,
      statusText: 'VEHICLE RETRIEVED',
      operationalStatus: OperationalStatus.inTransit,
      actionName: 'CONFIRM_VEHICLE_RETRIEVED',
      updateFields: {
        'retrievedAt': FieldValue.serverTimestamp(),
      },
      applyLocalUpdate: (ticket, now) => ticket.copyWith(
        lifecycleStatus: TicketLifecycleStatus.vehicleRetrieved,
        retrievedAt: now,
        statusText: 'VEHICLE RETRIEVED',
        status: OperationalStatus.inTransit,
      ),
    );

    return updated;
  }

  /// Confirms that the vehicle has arrived at the pickup / handover area and is ready.
  Future<ValetTicket> confirmVehicleReady({
    required String ticketId,
    required String valetId,
  }) async {
    return _transitionStatus(
      ticketId: ticketId,
      valetId: valetId,
      targetStatus: TicketLifecycleStatus.vehicleReady,
      statusText: 'VEHICLE READY',
      operationalStatus: OperationalStatus.available,
      actionName: 'CONFIRM_VEHICLE_READY',
      updateFields: {
        'vehicleReadyAt': FieldValue.serverTimestamp(),
      },
      applyLocalUpdate: (ticket, now) => ticket.copyWith(
        lifecycleStatus: TicketLifecycleStatus.vehicleReady,
        vehicleReadyAt: now,
        statusText: 'VEHICLE READY',
        status: OperationalStatus.available,
      ),
    );
  }

  /// Completes customer handover and marks the ticket as COMPLETED.
  Future<ValetTicket> completeHandover({
    required String ticketId,
    required String valetId,
  }) async {
    return _transitionStatus(
      ticketId: ticketId,
      valetId: valetId,
      targetStatus: TicketLifecycleStatus.completed,
      statusText: 'COMPLETED',
      operationalStatus: OperationalStatus.available,
      actionName: 'COMPLETE_HANDOVER',
      updateFields: {
        'handoverAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'checkOutTime': FieldValue.serverTimestamp(),
        'handoverValetId': valetId,
      },
      applyLocalUpdate: (ticket, now) => ticket.copyWith(
        lifecycleStatus: TicketLifecycleStatus.completed,
        handoverAt: now,
        completedAt: now,
        checkOutTime: now,
        handoverValetId: valetId,
        statusText: 'COMPLETED',
        status: OperationalStatus.available,
      ),
    );
  }

  /// Internal status transition helper enforcing validation and audit logs.
  Future<ValetTicket> _transitionStatus({
    required String ticketId,
    required String valetId,
    required TicketLifecycleStatus targetStatus,
    required String statusText,
    required OperationalStatus operationalStatus,
    required String actionName,
    required Map<String, dynamic> updateFields,
    required ValetTicket Function(ValetTicket, DateTime) applyLocalUpdate,
  }) async {
    if (!FirebaseService.isInitialized) {
      final index = _inMemoryTickets.indexWhere((t) => t.id == ticketId || t.ticketNumber == ticketId);
      if (index < 0) throw const TicketNotFoundException();

      final current = _inMemoryTickets[index];
      if (!current.lifecycleStatus.canTransitionTo(targetStatus)) {
        throw InvalidStatusTransitionException(
          'Cannot transition from ${current.lifecycleStatus.value} to ${targetStatus.value}',
        );
      }

      final now = DateTime.now();
      final updated = applyLocalUpdate(current, now);
      _inMemoryTickets[index] = updated;
      _inMemoryController.add(List.unmodifiable(_inMemoryTickets));

      await AuditRepository.instance.logEvent(
        ticketId: current.ticketNumber.isNotEmpty ? current.ticketNumber : current.id,
        organizationId: current.organizationId,
        locationId: current.locationId,
        performedBy: valetId,
        performedByRole: 'VALET',
        action: actionName,
        fromStatus: current.lifecycleStatus.value,
        toStatus: targetStatus.value,
      );

      return updated;
    }

    final docRef = FirebaseFirestore.instance.collection(FirebaseService.ticketsCollection).doc(ticketId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) throw const TicketNotFoundException();

    final current = ValetTicket.fromMap(snapshot.data()!, snapshot.id);
    if (!current.lifecycleStatus.canTransitionTo(targetStatus)) {
      throw InvalidStatusTransitionException(
        'Cannot transition ticket ${current.id} from ${current.lifecycleStatus.value} to ${targetStatus.value}',
      );
    }

    final Map<String, dynamic> firestoreMap = {
      'lifecycleStatus': targetStatus.value,
      'status': operationalStatus.name,
      'statusText': statusText,
      ...updateFields,
    };

    await docRef.update(firestoreMap);

    await AuditRepository.instance.logEvent(
      ticketId: current.ticketNumber.isNotEmpty ? current.ticketNumber : current.id,
      organizationId: current.organizationId,
      locationId: current.locationId,
      performedBy: valetId,
      performedByRole: 'VALET',
      action: actionName,
      fromStatus: current.lifecycleStatus.value,
      toStatus: targetStatus.value,
    );

    final now = DateTime.now();
    return applyLocalUpdate(current, now);
  }

  /// Streams operational tasks assigned to the specific valet at a given location.
  Stream<List<ValetTicket>> streamValetAssignedTasks({
    required String valetId,
    required String locationId,
  }) {
    if (!FirebaseService.isInitialized) {
      return _inMemoryController.stream.map((list) {
        return list.where((t) {
          final isLocationMatch = locationId.isEmpty ||
              t.locationId == 'default_loc' ||
              t.locationId == locationId ||
              t.siteName.toLowerCase().contains(locationId.toLowerCase());

          final isAssignedToValet = t.assignedValetId == valetId ||
              t.retrievalValetId == valetId ||
              t.handoverValetId == valetId;

          final isPendingUnclaimed = (t.lifecycleStatus == TicketLifecycleStatus.waitingForPickup &&
                  (t.assignedValetId == null || t.assignedValetId!.isEmpty)) ||
              (t.lifecycleStatus == TicketLifecycleStatus.retrievalRequested &&
                  (t.retrievalValetId == null || t.retrievalValetId!.isEmpty));

          final isTerminal = t.lifecycleStatus == TicketLifecycleStatus.completed ||
              t.lifecycleStatus == TicketLifecycleStatus.cancelled;

          return isLocationMatch && (isAssignedToValet || isPendingUnclaimed) && !isTerminal;
        }).toList();
      });
    }

    // Live Firestore query scoped to operational active tickets
    return FirebaseFirestore.instance
        .collection(FirebaseService.ticketsCollection)
        .where('locationId', isEqualTo: locationId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ValetTicket.fromMap(doc.data(), doc.id))
          .where((t) {
        final isAssignedToValet = t.assignedValetId == valetId ||
            t.retrievalValetId == valetId ||
            t.handoverValetId == valetId;

        final isPendingUnclaimed = (t.lifecycleStatus == TicketLifecycleStatus.waitingForPickup &&
                (t.assignedValetId == null || t.assignedValetId!.isEmpty)) ||
            (t.lifecycleStatus == TicketLifecycleStatus.retrievalRequested &&
                (t.retrievalValetId == null || t.retrievalValetId!.isEmpty));

        final isTerminal = t.lifecycleStatus == TicketLifecycleStatus.completed ||
            t.lifecycleStatus == TicketLifecycleStatus.cancelled;

        return (isAssignedToValet || isPendingUnclaimed) && !isTerminal;
      }).toList();
    });
  }

  /// Streams the valet's private completed jobs history, isolated by valet ID and location.
  Stream<List<ValetTicket>> streamValetJobHistory({
    required String valetId,
    required String locationId,
  }) {
    if (!FirebaseService.isInitialized) {
      return _inMemoryController.stream.map((list) {
        return list.where((t) {
          final isLocationMatch = locationId.isEmpty ||
              t.locationId == 'default_loc' ||
              t.locationId == locationId ||
              t.siteName.toLowerCase().contains(locationId.toLowerCase());

          final wasHandledByValet = t.assignedValetId == valetId ||
              t.retrievalValetId == valetId ||
              t.handoverValetId == valetId ||
              t.staffId == valetId;

          final isCompleted = t.lifecycleStatus == TicketLifecycleStatus.completed ||
              t.completedAt != null ||
              t.status == OperationalStatus.available;

          return isLocationMatch && wasHandledByValet && isCompleted;
        }).toList();
      });
    }

    return FirebaseFirestore.instance
        .collection(FirebaseService.ticketsCollection)
        .where('locationId', isEqualTo: locationId)
        .where('lifecycleStatus', isEqualTo: TicketLifecycleStatus.completed.value)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ValetTicket.fromMap(doc.data(), doc.id))
          .where((t) {
        return t.assignedValetId == valetId ||
            t.retrievalValetId == valetId ||
            t.handoverValetId == valetId ||
            t.staffId == valetId;
      }).toList();
    });
  }

  /// Prunes in-memory tickets older than the 90-day retention window.
  void _pruneExpiredTickets() {
    final cutoff = CustomerRetentionService.cutoffDate;
    _inMemoryTickets.removeWhere((t) =>
        (t.createdAt != null && t.createdAt!.isBefore(cutoff)) ||
        t.checkInTime.isBefore(cutoff));
  }

  /// Resets in-memory storage (used by unit tests).
  void clearInMemory() {
    _inMemoryTickets.clear();
    _inMemoryController.add([]);
  }
}
