import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/valet_ticket.dart';
import '../services/firestore_operations_repository.dart';
import '../../../../core/widgets/hud_chip.dart';

final operationsFilterProvider = StateProvider<String>((ref) => 'all');
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedSiteProvider = StateProvider<String>((ref) => 'All Sites (0 Properties)');

final valetTicketsProvider =
    StateNotifierProvider<ValetTicketsNotifier, List<ValetTicket>>((ref) {
  final repository = ref.watch(firestoreOperationsRepositoryProvider);
  return ValetTicketsNotifier(repository);
});

class ValetTicketsNotifier extends StateNotifier<List<ValetTicket>> {
  final FirestoreOperationsRepository? _repository;
  StreamSubscription<List<ValetTicket>>? _subscription;

  ValetTicketsNotifier([this._repository]) : super(const []) {
    _initFirestoreSync();
  }

  void _initFirestoreSync() {
    final repo = _repository;
    if (repo != null && repo.isConnected) {
      _subscription = repo.streamTickets().listen(
        (remoteTickets) {
          state = remoteTickets;
        },
        onError: (_) {},
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }



  void addTicket(ValetTicket ticket) {
    state = [ticket, ...state];
    _repository?.addTicket(ticket);
  }

  void updateTicketStatus(
    String id,
    OperationalStatus status,
    String statusText, {
    String? newSlot,
  }) {
    state = [
      for (final ticket in state)
        if (ticket.id == id)
          ticket.copyWith(
            status: status,
            statusText: statusText,
            locationSlot: newSlot,
            checkOutTime: status == OperationalStatus.available || status == OperationalStatus.custom
                ? DateTime.now()
                : ticket.checkOutTime,
          )
        else
          ticket,
    ];
    _repository?.updateTicketStatus(id, status, statusText, newSlot: newSlot);
  }

  void markPaid(String id) {
    state = [
      for (final ticket in state)
        if (ticket.id == id) ticket.copyWith(isPaid: true) else ticket,
    ];
    _repository?.markTicketPaid(id);
  }
}

final filteredTicketsProvider = Provider<List<ValetTicket>>((ref) {
  final tickets = ref.watch(valetTicketsProvider);
  final filter = ref.watch(operationsFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final site = ref.watch(selectedSiteProvider);

  return tickets.where((ticket) {
    // Status filter
    if (filter == 'parked' && ticket.status != OperationalStatus.occupied) {
      return false;
    }
    if (filter == 'retrieved' && ticket.status != OperationalStatus.available) {
      return false;
    }
    if (filter == 'completed' && ticket.status != OperationalStatus.custom) {
      return false;
    }

    // Site filter
    if (!site.startsWith('All Sites') &&
        !ticket.siteName.toLowerCase().contains(site.toLowerCase()) &&
        !ticket.siteShort.toLowerCase().contains(site.toLowerCase())) {
      return false;
    }

    // Search query
    if (query.isNotEmpty) {
      final matchesPlate = ticket.licensePlate.toLowerCase().contains(query);
      final matchesTicket = ticket.ticketNumber.toLowerCase().contains(query);
      final matchesCustomer = ticket.customerName.toLowerCase().contains(query);
      final matchesModel = ticket.carModel.toLowerCase().contains(query);
      if (!matchesPlate && !matchesTicket && !matchesCustomer && !matchesModel) {
        return false;
      }
    }

    return true;
  }).toList();
});

