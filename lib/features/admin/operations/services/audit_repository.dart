import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';

/// Models an immutable audit event recorded in the `ticketEvents` collection.
class TicketAuditEvent {
  final String id;
  final String ticketId;
  final String organizationId;
  final String locationId;
  final String performedBy;
  final String performedByRole;
  final String action;
  final String fromStatus;
  final String toStatus;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const TicketAuditEvent({
    required this.id,
    required this.ticketId,
    required this.organizationId,
    required this.locationId,
    required this.performedBy,
    required this.performedByRole,
    required this.action,
    required this.fromStatus,
    required this.toStatus,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'organizationId': organizationId,
      'locationId': locationId,
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'action': action,
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };
  }

  factory TicketAuditEvent.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      try {
        final dynamic ts = val;
        return ts.toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return TicketAuditEvent(
      id: docId ?? map['id'] as String? ?? '',
      ticketId: map['ticketId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      locationId: map['locationId'] as String? ?? '',
      performedBy: map['performedBy'] as String? ?? '',
      performedByRole: map['performedByRole'] as String? ?? 'VALET',
      action: map['action'] as String? ?? '',
      fromStatus: map['fromStatus'] as String? ?? '',
      toStatus: map['toStatus'] as String? ?? '',
      timestamp: parseTime(map['timestamp']),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// AuditRepository manages tracking operational actions to `ticketEvents/{eventId}`.
class AuditRepository {
  static final AuditRepository instance = AuditRepository._internal();
  AuditRepository._internal();

  final List<TicketAuditEvent> _inMemoryEvents = [];
  List<TicketAuditEvent> get inMemoryEvents => List.unmodifiable(_inMemoryEvents);

  /// Logs an operational action to Firestore `ticketEvents` collection with fallback to memory.
  Future<void> logEvent({
    required String ticketId,
    required String organizationId,
    required String locationId,
    required String performedBy,
    required String performedByRole,
    required String action,
    required String fromStatus,
    required String toStatus,
    Map<String, dynamic>? metadata,
  }) async {
    final eventId = 'evt_${DateTime.now().millisecondsSinceEpoch}_${ticketId.replaceAll('#', '')}';
    final event = TicketAuditEvent(
      id: eventId,
      ticketId: ticketId,
      organizationId: organizationId,
      locationId: locationId,
      performedBy: performedBy,
      performedByRole: performedByRole,
      action: action,
      fromStatus: fromStatus,
      toStatus: toStatus,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _inMemoryEvents.add(event);

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('ticketEvents')
            .doc(eventId)
            .set(event.toMap());
        debugPrint('[AuditRepository] Logged event $eventId for ticket $ticketId: $fromStatus -> $toStatus');
      } catch (e) {
        debugPrint('[AuditRepository] Error writing audit event to Firestore: $e');
      }
    }
  }

  /// Streams audit events for a specific ticket.
  Stream<List<TicketAuditEvent>> streamEventsForTicket(String ticketId) {
    if (!FirebaseService.isInitialized) {
      return Stream.value(
        _inMemoryEvents.where((e) => e.ticketId == ticketId).toList(),
      );
    }

    return FirebaseFirestore.instance
        .collection('ticketEvents')
        .where('ticketId', isEqualTo: ticketId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TicketAuditEvent.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  void clearInMemory() {
    _inMemoryEvents.clear();
  }
}
