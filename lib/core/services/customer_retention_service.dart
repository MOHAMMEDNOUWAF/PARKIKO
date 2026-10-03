import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// Central service managing the customer data retention policy (last 90 days).
/// Automatically purges records older than 90 days from the Firestore database
/// and filters in-memory representations so only the last 90 days of customer
/// details are retained.
class CustomerRetentionService {
  CustomerRetentionService._();
  static final CustomerRetentionService instance = CustomerRetentionService._();

  /// Default retention duration for customer records in days.
  static const int retentionDays = 90;

  /// Returns the cutoff DateTime beyond which customer details are expired.
  static DateTime get cutoffDate =>
      DateTime.now().subtract(const Duration(days: retentionDays));

  /// Checks if a date falls within the 90-day retention window.
  static bool isWithinRetention(DateTime date) {
    return !date.isBefore(cutoffDate);
  }

  /// Purges customer details and records older than 90 days from the Firestore database.
  /// Scans and cleans:
  /// - `valet_intakes` collection (where `createdAt` < 90 days ago)
  /// - `tickets` collection (where `createdAt` < 90 days ago)
  /// - `vehicle_conditions` collection (where `recordedAt` < 90 days ago)
  ///
  /// Returns the total count of documents purged from the database.
  Future<int> purgeExpiredRecords({int days = retentionDays}) async {
    if (!FirebaseService.isInitialized) {
      debugPrint('[CustomerRetentionService] Skipping database purge: Firebase offline or not initialized.');
      return 0;
    }

    int totalPurged = 0;
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final cutoffTs = Timestamp.fromDate(cutoff);
      final firestore = FirebaseFirestore.instance;

      // 1. Purge expired customer intakes ('valet_intakes')
      try {
        final intakeSnap = await firestore
            .collection(FirebaseService.intakesCollection)
            .where('createdAt', isLessThan: cutoffTs)
            .get();

        if (intakeSnap.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final doc in intakeSnap.docs) {
            batch.delete(doc.reference);
            totalPurged++;
          }
          await batch.commit();
          debugPrint('[CustomerRetentionService] Purged ${intakeSnap.docs.length} expired valet_intakes (> $days days).');
        }
      } catch (e) {
        debugPrint('[CustomerRetentionService] Error purging expired valet_intakes: $e');
      }

      // 2. Purge expired tickets ('tickets')
      try {
        final ticketSnap = await firestore
            .collection(FirebaseService.ticketsCollection)
            .where('createdAt', isLessThan: cutoffTs)
            .get();

        if (ticketSnap.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final doc in ticketSnap.docs) {
            batch.delete(doc.reference);
            totalPurged++;
          }
          await batch.commit();
          debugPrint('[CustomerRetentionService] Purged ${ticketSnap.docs.length} expired tickets (> $days days).');
        }
      } catch (e) {
        debugPrint('[CustomerRetentionService] Error purging expired tickets: $e');
      }

      // 3. Purge expired vehicle condition logs ('vehicle_conditions')
      try {
        final condSnap = await firestore
            .collection(FirebaseService.vehicleConditionsCollection)
            .where('recordedAt', isLessThan: cutoffTs)
            .get();

        if (condSnap.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final doc in condSnap.docs) {
            batch.delete(doc.reference);
            totalPurged++;
          }
          await batch.commit();
          debugPrint('[CustomerRetentionService] Purged ${condSnap.docs.length} expired vehicle conditions (> $days days).');
        }
      } catch (e) {
        debugPrint('[CustomerRetentionService] Error purging expired vehicle conditions: $e');
      }
    } catch (e) {
      debugPrint('[CustomerRetentionService] Error executing customer data retention purge: $e');
    }

    return totalPurged;
  }
}
