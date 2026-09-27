import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';

class VehicleConditionRecord {
  final String id;
  final String ticketId;
  final String vehicleNumber;
  final String conditionNotes;
  final List<String> photoUrls;
  final String recordedBy;
  final DateTime recordedAt;

  const VehicleConditionRecord({
    required this.id,
    required this.ticketId,
    required this.vehicleNumber,
    required this.conditionNotes,
    required this.photoUrls,
    required this.recordedBy,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'vehicleNumber': vehicleNumber,
      'conditionNotes': conditionNotes,
      'photoUrls': photoUrls,
      'recordedBy': recordedBy,
      'recordedAt': FieldValue.serverTimestamp(),
    };
  }

  factory VehicleConditionRecord.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
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

    return VehicleConditionRecord(
      id: docId ?? map['id'] as String? ?? '',
      ticketId: map['ticketId'] as String? ?? '',
      vehicleNumber: map['vehicleNumber'] as String? ?? '',
      conditionNotes: map['conditionNotes'] as String? ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      recordedBy: map['recordedBy'] as String? ?? '',
      recordedAt: parseDate(map['recordedAt']),
    );
  }
}

class VehicleConditionRepository {
  static final VehicleConditionRepository instance = VehicleConditionRepository._internal();
  VehicleConditionRepository._internal();

  final List<VehicleConditionRecord> _inMemoryRecords = [];
  List<VehicleConditionRecord> get inMemoryRecords => List.unmodifiable(_inMemoryRecords);

  Future<void> recordCondition(VehicleConditionRecord record) async {
    _inMemoryRecords.add(record);

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('vehicle_conditions')
            .doc(record.id)
            .set(record.toMap());
      } catch (e) {
        debugPrint('[VehicleConditionRepository] Error recording condition: $e');
      }
    }
  }

  Future<VehicleConditionRecord?> getConditionForTicket(String ticketId) async {
    if (!FirebaseService.isInitialized) {
      try {
        return _inMemoryRecords.firstWhere((r) => r.ticketId == ticketId);
      } catch (_) {
        return null;
      }
    }

    final query = await FirebaseFirestore.instance
        .collection('vehicle_conditions')
        .where('ticketId', isEqualTo: ticketId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return VehicleConditionRecord.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  void clearInMemory() {
    _inMemoryRecords.clear();
  }
}
