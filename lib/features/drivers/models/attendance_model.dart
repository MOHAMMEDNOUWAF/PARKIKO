enum AttendanceStatus {
  working,
  completed,
  onBreak;

  String get value {
    switch (this) {
      case AttendanceStatus.working:
        return 'WORKING';
      case AttendanceStatus.completed:
        return 'COMPLETED';
      case AttendanceStatus.onBreak:
        return 'ON_BREAK';
    }
  }

  static AttendanceStatus fromString(String? raw) {
    if (raw == null) return AttendanceStatus.working;
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'WORKING') return AttendanceStatus.working;
    if (normalized == 'COMPLETED') return AttendanceStatus.completed;
    if (normalized == 'ON_BREAK') return AttendanceStatus.onBreak;
    return AttendanceStatus.working;
  }
}

/// Represents a staff/valet attendance record stored in `attendance/{attendanceId}`.
class AttendanceRecord {
  final String id;
  final String valetId;
  final String userId;
  final String organizationId;
  final String locationId;
  final String date; // YYYY-MM-DD
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final AttendanceStatus status;

  const AttendanceRecord({
    required this.id,
    required this.valetId,
    required this.userId,
    required this.organizationId,
    required this.locationId,
    required this.date,
    required this.checkInAt,
    this.checkOutAt,
    this.status = AttendanceStatus.working,
  });

  AttendanceRecord copyWith({
    DateTime? checkOutAt,
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      id: id,
      valetId: valetId,
      userId: userId,
      organizationId: organizationId,
      locationId: locationId,
      date: date,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'valetId': valetId,
      'userId': userId,
      'organizationId': organizationId,
      'locationId': locationId,
      'date': date,
      'checkInAt': checkInAt.toIso8601String(),
      'checkOutAt': checkOutAt?.toIso8601String(),
      'status': status.value,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        final dynamic ts = val;
        return ts.toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return AttendanceRecord(
      id: docId ?? map['id'] as String? ?? '',
      valetId: map['valetId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? 'default_org',
      locationId: map['locationId'] as String? ?? 'default_loc',
      date: map['date'] as String? ?? '',
      checkInAt: parseDate(map['checkInAt']),
      checkOutAt: parseNullableDate(map['checkOutAt']),
      status: AttendanceStatus.fromString(map['status'] as String?),
    );
  }
}
