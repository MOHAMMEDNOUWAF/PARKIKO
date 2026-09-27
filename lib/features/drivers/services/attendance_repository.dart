import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../models/attendance_model.dart';

class DuplicateCheckInException implements Exception {
  final String message;
  const DuplicateCheckInException([this.message = 'An active shift check-in already exists for this valet.']);
  @override
  String toString() => message;
}

class NoActiveCheckInException implements Exception {
  final String message;
  const NoActiveCheckInException([this.message = 'No active shift check-in found to check out from.']);
  @override
  String toString() => message;
}

/// Manages valet shift attendance in `attendance/{attendanceId}` with strict single-active-check-in validation.
class AttendanceRepository {
  static final AttendanceRepository instance = AttendanceRepository._internal();
  AttendanceRepository._internal();

  final List<AttendanceRecord> _inMemoryAttendance = [];
  final _inMemoryController = StreamController<List<AttendanceRecord>>.broadcast();

  List<AttendanceRecord> get inMemoryAttendance => List.unmodifiable(_inMemoryAttendance);

  /// Formats date to YYYY-MM-DD
  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Begins shift: validates no active check-in exists, then records check-in.
  Future<AttendanceRecord> checkIn({
    required String valetId,
    required String userId,
    required String organizationId,
    required String locationId,
  }) async {
    final today = _formatDate(DateTime.now());

    if (!FirebaseService.isInitialized) {
      // In-memory duplicate active check-in check
      final hasActive = _inMemoryAttendance.any(
        (a) => a.valetId == valetId && a.status == AttendanceStatus.working && a.checkOutAt == null,
      );
      if (hasActive) {
        throw const DuplicateCheckInException();
      }

      final docId = 'att_${valetId}_${DateTime.now().millisecondsSinceEpoch}';
      final record = AttendanceRecord(
        id: docId,
        valetId: valetId,
        userId: userId,
        organizationId: organizationId,
        locationId: locationId,
        date: today,
        checkInAt: DateTime.now(),
        status: AttendanceStatus.working,
      );

      _inMemoryAttendance.add(record);
      _inMemoryController.add(List.unmodifiable(_inMemoryAttendance));
      return record;
    }

    final collection = FirebaseFirestore.instance.collection('attendance');

    // Query active check-ins for this valet
    final activeQuery = await collection
        .where('valetId', isEqualTo: valetId)
        .where('status', isEqualTo: AttendanceStatus.working.value)
        .get();

    if (activeQuery.docs.isNotEmpty) {
      throw const DuplicateCheckInException();
    }

    final docId = 'att_${valetId}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final record = AttendanceRecord(
      id: docId,
      valetId: valetId,
      userId: userId,
      organizationId: organizationId,
      locationId: locationId,
      date: today,
      checkInAt: now,
      status: AttendanceStatus.working,
    );

    await collection.doc(docId).set({
      'id': docId,
      'valetId': valetId,
      'userId': userId,
      'organizationId': organizationId,
      'locationId': locationId,
      'date': today,
      'checkInAt': FieldValue.serverTimestamp(),
      'checkOutAt': null,
      'status': AttendanceStatus.working.value,
    });

    return record;
  }

  /// Ends shift: updates the active check-in with check-out timestamp and status COMPLETED.
  Future<AttendanceRecord> checkOut({required String valetId}) async {
    if (!FirebaseService.isInitialized) {
      final index = _inMemoryAttendance.indexWhere(
        (a) => a.valetId == valetId && a.status == AttendanceStatus.working && a.checkOutAt == null,
      );
      if (index < 0) {
        throw const NoActiveCheckInException();
      }

      final current = _inMemoryAttendance[index];
      final updated = current.copyWith(
        checkOutAt: DateTime.now(),
        status: AttendanceStatus.completed,
      );
      _inMemoryAttendance[index] = updated;
      _inMemoryController.add(List.unmodifiable(_inMemoryAttendance));
      return updated;
    }

    final collection = FirebaseFirestore.instance.collection('attendance');
    final activeQuery = await collection
        .where('valetId', isEqualTo: valetId)
        .where('status', isEqualTo: AttendanceStatus.working.value)
        .limit(1)
        .get();

    if (activeQuery.docs.isEmpty) {
      throw const NoActiveCheckInException();
    }

    final activeDoc = activeQuery.docs.first;
    final now = DateTime.now();

    await collection.doc(activeDoc.id).update({
      'checkOutAt': FieldValue.serverTimestamp(),
      'status': AttendanceStatus.completed.value,
    });

    final currentRecord = AttendanceRecord.fromMap(activeDoc.data(), activeDoc.id);
    return currentRecord.copyWith(
      checkOutAt: now,
      status: AttendanceStatus.completed,
    );
  }

  /// Checks if the valet currently has an active shift.
  Future<AttendanceRecord?> getActiveCheckIn(String valetId) async {
    if (!FirebaseService.isInitialized) {
      try {
        return _inMemoryAttendance.firstWhere(
          (a) => a.valetId == valetId && a.status == AttendanceStatus.working && a.checkOutAt == null,
        );
      } catch (_) {
        return null;
      }
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('valetId', isEqualTo: valetId)
        .where('status', isEqualTo: AttendanceStatus.working.value)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AttendanceRecord.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  /// Streams attendance records for a specific valet.
  Stream<List<AttendanceRecord>> streamAttendanceForValet(String valetId) {
    if (!FirebaseService.isInitialized) {
      return _inMemoryController.stream.map(
        (list) => list.where((a) => a.valetId == valetId).toList(),
      );
    }

    return FirebaseFirestore.instance
        .collection('attendance')
        .where('valetId', isEqualTo: valetId)
        .orderBy('checkInAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  void clearInMemory() {
    _inMemoryAttendance.clear();
    _inMemoryController.add([]);
  }
}
