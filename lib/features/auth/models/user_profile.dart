import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a trusted Parkiko user profile stored in Firestore at `users/{uid}`.
class UserProfile {
  final String uid;
  final String userId;
  final String name;
  final String role;
  final String status;
  final String? organizationId;
  final List<String> locationIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.userId,
    required this.name,
    required this.role,
    required this.status,
    this.organizationId,
    this.locationIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Whether the user profile has administrative privileges.
  bool get isAdmin => role.trim().toUpperCase() == 'ADMIN';

  /// Whether the user profile has assistant manager privileges.
  bool get isAssistantManager =>
      role.trim().toUpperCase() == 'ASST_MGR' ||
      role.trim().toUpperCase() == 'ASSISTANT_MANAGER' ||
      role.trim().toUpperCase() == 'ASST. MGR' ||
      role.trim().toUpperCase() == 'ASSISTANT MANAGER' ||
      role.trim().toUpperCase().contains('ASSISTANT') ||
      role.trim().toUpperCase().contains('ASST');

  /// Whether the user profile has manager privileges.
  bool get isManager =>
      !isAssistantManager &&
      (role.trim().toUpperCase() == 'MANAGER' ||
          role.trim().toUpperCase() == 'MGR' ||
          role.trim().toUpperCase().contains('MANAGER'));

  /// Whether the user profile has valet operator privileges.
  bool get isValet =>
      role.trim().toUpperCase() == 'VALET' ||
      role.trim().toUpperCase() == 'DRIVER' ||
      role.trim().toUpperCase() == 'STAFF';

  /// Backwards-compatible alias for valet privileges.
  bool get isDriver => isValet;

  /// Whether the profile has recognized clearance to log into Parkiko.
  bool get isAuthorized =>
      isAdmin || isManager || isAssistantManager || isValet;

  /// Whether the user account is currently active.
  bool get isActive => status.trim().toUpperCase() == 'ACTIVE';

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile.fromMap(data, doc.id);
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawLocations = map['locationIds'];
    List<String> locations = [];
    if (rawLocations is List) {
      locations = rawLocations.map((e) => e.toString()).toList();
    }

    return UserProfile(
      uid: map['uid'] as String? ?? uid,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? 'Parkiko User',
      role: map['role'] as String? ?? '',
      status: map['status'] as String? ?? '',
      organizationId: map['organizationId'] as String?,
      locationIds: locations,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'name': name,
      'role': role,
      'status': status,
      'organizationId': organizationId,
      'locationIds': locationIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? userId,
    String? name,
    String? role,
    String? status,
    String? organizationId,
    List<String>? locationIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      locationIds: locationIds ?? this.locationIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'UserProfile(uid: $uid, userId: $userId, role: $role, status: $status)';
}
