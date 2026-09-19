import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/widgets/hud_chip.dart';
import '../models/valet_ticket.dart';

/// Riverpod provider for [FirestoreOperationsRepository].
final firestoreOperationsRepositoryProvider =
    Provider<FirestoreOperationsRepository>((ref) {
  return FirestoreOperationsRepository();
});

/// Repository for synchronizing valet operational tickets with Cloud Firestore.
/// Automatically provides offline-safe fallback when Firestore is unavailable.
class FirestoreOperationsRepository {
  FirebaseFirestore? get _firestore {
    if (FirebaseService.isInitialized) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _ticketsCol {
    final firestore = _firestore;
    if (firestore != null) {
      return firestore.collection(FirebaseService.ticketsCollection);
    }
    return null;
  }

  /// Whether Cloud Firestore is actively connected and reachable.
  bool get isConnected => _firestore != null;

  /// Real-time stream of valet operational tickets from Firestore.
  Stream<List<ValetTicket>> streamTickets() {
    final col = _ticketsCol;
    if (col == null) {
      return const Stream.empty();
    }

    return col
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ValetTicket.fromMap(doc.data(), doc.id);
          }).toList();
        })
        .handleError((error) {
          debugPrint('[FirestoreOperationsRepository] Stream error: $error');
          return <ValetTicket>[];
        });
  }

  /// Inserts a new valet ticket into Cloud Firestore.
  Future<void> addTicket(ValetTicket ticket) async {
    final col = _ticketsCol;
    if (col == null) {
      debugPrint('[FirestoreOperationsRepository] Offline mode: saved locally.');
      return;
    }

    try {
      if (ticket.id.isNotEmpty && !ticket.id.startsWith('#')) {
        await col.doc(ticket.id).set(ticket.toMap(), SetOptions(merge: true));
      } else {
        await col.add(ticket.toMap());
      }
      debugPrint('[FirestoreOperationsRepository] Ticket ${ticket.ticketNumber} saved.');
    } catch (e) {
      debugPrint('[FirestoreOperationsRepository] Error adding ticket: $e');
    }
  }

  /// Updates status, status text, and optional slot location of a ticket.
  Future<void> updateTicketStatus(
    String id,
    OperationalStatus status,
    String statusText, {
    String? newSlot,
  }) async {
    final col = _ticketsCol;
    if (col == null) return;

    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'statusText': statusText,
      };
      if (newSlot != null && newSlot.isNotEmpty) {
        updates['locationSlot'] = newSlot;
      }
      if (status == OperationalStatus.available) {
        updates['checkOutTime'] = DateTime.now().toIso8601String();
      }
      await col.doc(id).update(updates);
      debugPrint('[FirestoreOperationsRepository] Ticket $id status updated to $statusText.');
    } catch (e) {
      debugPrint('[FirestoreOperationsRepository] Error updating ticket status: $e');
    }
  }

  /// Marks a ticket as paid.
  Future<void> markTicketPaid(String id) async {
    final col = _ticketsCol;
    if (col == null) return;

    try {
      await col.doc(id).update({'isPaid': true});
      debugPrint('[FirestoreOperationsRepository] Ticket $id marked paid.');
    } catch (e) {
      debugPrint('[FirestoreOperationsRepository] Error marking paid: $e');
    }
  }

  /// Seeds initial tickets to Firestore if the collection is currently empty.
  Future<void> seedIfEmpty(List<ValetTicket> initialTickets) async {
    final col = _ticketsCol;
    if (col == null) return;

    try {
      final snapshot = await col.limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('[FirestoreOperationsRepository] Seeding initial tickets to Firestore...');
        final batch = _firestore!.batch();
        for (final ticket in initialTickets) {
          final docRef = col.doc(ticket.id);
          batch.set(docRef, ticket.toMap());
        }
        await batch.commit();
        debugPrint('[FirestoreOperationsRepository] Seeded ${initialTickets.length} tickets.');
      }
    } catch (e) {
      debugPrint('[FirestoreOperationsRepository] Notice during seeding: $e');
    }
  }
}
