import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/firebase_service.dart';

enum KeyStatus {
  keyReceived,
  keyStored,
  keyIssued,
  keyReturned;

  String get value {
    switch (this) {
      case KeyStatus.keyReceived:
        return 'KEY_RECEIVED';
      case KeyStatus.keyStored:
        return 'KEY_STORED';
      case KeyStatus.keyIssued:
        return 'KEY_ISSUED';
      case KeyStatus.keyReturned:
        return 'KEY_RETURNED';
    }
  }

  static KeyStatus fromString(String? raw) {
    if (raw == null) return KeyStatus.keyReceived;
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'KEY_STORED') return KeyStatus.keyStored;
    if (normalized == 'KEY_ISSUED') return KeyStatus.keyIssued;
    if (normalized == 'KEY_RETURNED') return KeyStatus.keyReturned;
    return KeyStatus.keyReceived;
  }
}

class KeyRecord {
  final String id;
  final String ticketId;
  final String keyTag;
  final KeyStatus status;
  final String storageSlot;
  final String handledBy;
  final DateTime updatedAt;

  const KeyRecord({
    required this.id,
    required this.ticketId,
    required this.keyTag,
    required this.status,
    required this.storageSlot,
    required this.handledBy,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'keyTag': keyTag,
      'status': status.value,
      'storageSlot': storageSlot,
      'handledBy': handledBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory KeyRecord.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    return KeyRecord(
      id: docId ?? map['id'] as String? ?? '',
      ticketId: map['ticketId'] as String? ?? '',
      keyTag: map['keyTag'] as String? ?? '',
      status: KeyStatus.fromString(map['status'] as String?),
      storageSlot: map['storageSlot'] as String? ?? '',
      handledBy: map['handledBy'] as String? ?? '',
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}

class KeyRecordRepository {
  static final KeyRecordRepository instance = KeyRecordRepository._internal();
  KeyRecordRepository._internal();

  final List<KeyRecord> _inMemoryKeys = [];
  List<KeyRecord> get inMemoryKeys => List.unmodifiable(_inMemoryKeys);

  Future<void> updateKeyStatus({
    required String ticketId,
    required String keyTag,
    required KeyStatus status,
    required String storageSlot,
    required String handledBy,
  }) async {
    final recordId = 'key_${ticketId.replaceAll('#', '')}';
    final record = KeyRecord(
      id: recordId,
      ticketId: ticketId,
      keyTag: keyTag,
      status: status,
      storageSlot: storageSlot,
      handledBy: handledBy,
      updatedAt: DateTime.now(),
    );

    final idx = _inMemoryKeys.indexWhere((k) => k.ticketId == ticketId);
    if (idx >= 0) {
      _inMemoryKeys[idx] = record;
    } else {
      _inMemoryKeys.add(record);
    }

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection('key_records')
            .doc(recordId)
            .set(record.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('[KeyRecordRepository] Error saving key record: $e');
      }
    }
  }

  Future<KeyRecord?> getKeyRecordForTicket(String ticketId) async {
    if (!FirebaseService.isInitialized) {
      try {
        return _inMemoryKeys.firstWhere((k) => k.ticketId == ticketId);
      } catch (_) {
        return null;
      }
    }

    final query = await FirebaseFirestore.instance
        .collection('key_records')
        .where('ticketId', isEqualTo: ticketId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return KeyRecord.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  void clearInMemory() {
    _inMemoryKeys.clear();
  }
}
