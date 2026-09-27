import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a staff member / driver enrolled by an administrator.
class StaffModel {
  final String id;
  final String name;
  final String phone;
  final String role; // 'driver' or 'manager'
  final String assignedSite;
  final String password; // login PIN / password set by admin
  final String metric;
  final bool isOnDuty;
  final String? email;
  final String? licenseNo;
  final DateTime? licenseExpiry;
  final DateTime? createdAt;

  const StaffModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.assignedSite,
    this.password = '1234',
    this.metric = '0 Cars Handled',
    this.isOnDuty = true,
    this.email,
    this.licenseNo,
    this.licenseExpiry,
    this.createdAt,
  });

  bool get isAdmin =>
      role.toLowerCase().contains('admin');
  bool get isAssistantManager =>
      role.toLowerCase().contains('assistant') ||
      role.toLowerCase().contains('asst');
  bool get isManager =>
      !isAssistantManager &&
      (role.toLowerCase().contains('manager') ||
       role.toLowerCase().contains('mgr'));
  bool get isValet =>
      role.toLowerCase().contains('valet') ||
      role.toLowerCase().contains('driver') ||
      (!isAdmin && !isManager && !isAssistantManager);
  bool get isDriver => isValet;

  /// Initial password is the last 4 digits of the registered mobile number.
  String get mobileLast4 {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) {
      return digits.substring(digits.length - 4);
    }
    return password.isNotEmpty ? password : '1234';
  }

  Map<String, dynamic> toMap({bool includePassword = true}) {
    final map = <String, dynamic>{
      'id': id,
      'userId': id,
      'name': name,
      'phone': phone,
      'role': role,
      'assignedSite': assignedSite,
      'metric': metric,
      'isOnDuty': isOnDuty,
      'email': email ?? '',
      'licenseNo': licenseNo ?? '',
      'licenseExpiry': licenseExpiry?.toIso8601String(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
    if (includePassword) {
      map['password'] = password.isNotEmpty ? password : '1234';
    }
    return map;
  }

  factory StaffModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final staffId = (id != null && id.isNotEmpty)
        ? id
        : (map['id'] as String? ?? map['userId'] as String? ?? '');

    return StaffModel(
      id: staffId,
      name: map['name'] as String? ?? 'Staff',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? 'driver',
      assignedSite: map['assignedSite'] as String? ?? 'CyberHub Corporate Plaza',
      password: map['password'] as String? ?? '1234',
      metric: map['metric'] as String? ?? '0 Cars Handled',
      isOnDuty: map['isOnDuty'] as bool? ?? true,
      email: map['email'] as String?,
      licenseNo: map['licenseNo'] as String?,
      licenseExpiry: parseDate(map['licenseExpiry']),
      createdAt: parseDate(map['createdAt']),
    );
  }

  StaffModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? assignedSite,
    String? password,
    String? metric,
    bool? isOnDuty,
    String? email,
    String? licenseNo,
    DateTime? licenseExpiry,
    DateTime? createdAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedSite: assignedSite ?? this.assignedSite,
      password: password ?? this.password,
      metric: metric ?? this.metric,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      email: email ?? this.email,
      licenseNo: licenseNo ?? this.licenseNo,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
