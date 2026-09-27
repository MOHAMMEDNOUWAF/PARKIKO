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

  ValetTicketsNotifier([this._repository]) : super(_initialSampleTickets) {
    _initFirestoreSync();
  }

  void _initFirestoreSync() {
    final repo = _repository;
    if (repo != null && repo.isConnected) {
      if (_initialSampleTickets.isNotEmpty) {
        repo.seedIfEmpty(_initialSampleTickets);
      }

      _subscription = repo.streamTickets().listen(
        (remoteTickets) {
          if (remoteTickets.isNotEmpty) {
            state = remoteTickets;
          }
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

  static final List<ValetTicket> _initialSampleTickets = <ValetTicket>[
    ValetTicket(
      id: 'ticket-gh-101',
      ticketNumber: '#1089',
      licensePlate: 'MH 02 CD 4589',
      carModel: 'Mercedes-Benz E-Class',
      color: 'Obsidian Black',
      customerName: 'Vikram Malhotra',
      customerPhone: '+91 98201 44520',
      siteName: 'Grand Hyatt & Convention',
      siteShort: 'Grand Hyatt',
      locationSlot: 'Bay A-14 (Basement 1)',
      staffName: 'Rahul Sharma',
      staffId: 'STF-01',
      staffRole: 'VALET',
      status: OperationalStatus.occupied,
      statusText: 'PARKED',
      lifecycleStatus: TicketLifecycleStatus.parked,
      checkInTime: DateTime.now().subtract(const Duration(minutes: 42)),
      amount: 250.0,
      isPaid: false,
    ),
    ValetTicket(
      id: 'ticket-gh-102',
      ticketNumber: '#1092',
      licensePlate: 'KA 01 MJ 8821',
      carModel: 'BMW 5 Series',
      color: 'Alpine White',
      customerName: 'Ananya Iyer',
      customerPhone: '+91 98450 11920',
      siteName: 'Grand Hyatt & Convention',
      siteShort: 'Grand Hyatt',
      locationSlot: 'Porch Lane (Ready)',
      staffName: 'Amit Kumar',
      staffId: 'STF-02',
      staffRole: 'VALET',
      status: OperationalStatus.available,
      statusText: 'RETRIEVED',
      lifecycleStatus: TicketLifecycleStatus.vehicleReady,
      checkInTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      amount: 250.0,
      isPaid: true,
    ),
    ValetTicket(
      id: 'ticket-gh-103',
      ticketNumber: '#1085',
      licensePlate: 'DL 3C AW 9012',
      carModel: 'Audi A6',
      color: 'Mythos Black',
      customerName: 'Rajesh Singhania',
      customerPhone: '+91 99100 88234',
      siteName: 'Grand Hyatt & Convention',
      siteShort: 'Grand Hyatt',
      locationSlot: 'Released to Customer',
      staffName: 'Rahul Sharma',
      staffId: 'STF-01',
      staffRole: 'VALET',
      status: OperationalStatus.custom,
      statusText: 'COMPLETED',
      lifecycleStatus: TicketLifecycleStatus.completed,
      checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      checkOutTime: DateTime.now().subtract(const Duration(minutes: 10)),
      amount: 250.0,
      isPaid: true,
    ),
    ValetTicket(
      id: 'ticket-gh-104',
      ticketNumber: '#1095',
      licensePlate: 'MH 01 BK 3341',
      carModel: 'Porsche Cayenne',
      color: 'Carmine Red',
      customerName: 'Sameer Mehta',
      customerPhone: '+91 98210 99450',
      siteName: 'Grand Hyatt & Convention',
      siteShort: 'Grand Hyatt',
      locationSlot: 'Bay B-08 (Basement 2)',
      staffName: 'Suresh Verma',
      staffId: 'STF-03',
      staffRole: 'VALET',
      status: OperationalStatus.occupied,
      statusText: 'PARKED',
      lifecycleStatus: TicketLifecycleStatus.parked,
      checkInTime: DateTime.now().subtract(const Duration(minutes: 25)),
      amount: 300.0,
      isPaid: false,
    ),
    ValetTicket(
      id: 'ticket-gh-105',
      ticketNumber: '#1097',
      licensePlate: 'TS 09 EG 7714',
      carModel: 'Range Rover Velar',
      color: 'Santorini Black',
      customerName: 'Rohan Reddy',
      customerPhone: '+91 97000 33211',
      siteName: 'Grand Hyatt & Convention',
      siteShort: 'Grand Hyatt',
      locationSlot: 'Porch Lane (Ready)',
      staffName: 'Amit Kumar',
      staffId: 'STF-02',
      staffRole: 'VALET',
      status: OperationalStatus.available,
      statusText: 'RETRIEVED',
      lifecycleStatus: TicketLifecycleStatus.vehicleReady,
      checkInTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      amount: 300.0,
      isPaid: true,
    ),
    ValetTicket(
      id: 'ticket-ph-201',
      ticketNumber: '#2041',
      licensePlate: 'MH 04 EF 7820',
      carModel: 'Volvo XC90',
      color: 'Crystal White',
      customerName: 'Priya Kapoor',
      customerPhone: '+91 98205 66710',
      siteName: 'Phoenix Palladium Mall',
      siteShort: 'Phoenix',
      locationSlot: 'Deck P2 - Zone C',
      staffName: 'Vicky Patil',
      staffId: 'STF-04',
      staffRole: 'VALET',
      status: OperationalStatus.occupied,
      statusText: 'PARKED',
      lifecycleStatus: TicketLifecycleStatus.parked,
      checkInTime: DateTime.now().subtract(const Duration(minutes: 50)),
      amount: 150.0,
      isPaid: false,
    ),
    ValetTicket(
      id: 'ticket-ph-202',
      ticketNumber: '#2044',
      licensePlate: 'MH 03 BK 5521',
      carModel: 'Jaguar XF',
      color: 'Firenze Red',
      customerName: 'Kabir Deshmukh',
      customerPhone: '+91 98190 44211',
      siteName: 'Phoenix Palladium Mall',
      siteShort: 'Phoenix',
      locationSlot: 'Porch Lane (Ready)',
      staffName: 'Vicky Patil',
      staffId: 'STF-04',
      staffRole: 'VALET',
      status: OperationalStatus.available,
      statusText: 'RETRIEVED',
      lifecycleStatus: TicketLifecycleStatus.vehicleReady,
      checkInTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      amount: 150.0,
      isPaid: true,
    ),
    ValetTicket(
      id: 'ticket-ph-203',
      ticketNumber: '#2038',
      licensePlate: 'MH 12 PQ 1199',
      carModel: 'Mercedes GLC',
      color: 'Cavansite Blue',
      customerName: 'Siddharth Joshi',
      customerPhone: '+91 98220 88123',
      siteName: 'Phoenix Palladium Mall',
      siteShort: 'Phoenix',
      locationSlot: 'Released to Customer',
      staffName: 'Sunil Jadhav',
      staffId: 'STF-05',
      staffRole: 'VALET',
      status: OperationalStatus.custom,
      statusText: 'COMPLETED',
      lifecycleStatus: TicketLifecycleStatus.completed,
      checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      checkOutTime: DateTime.now().subtract(const Duration(minutes: 20)),
      amount: 150.0,
      isPaid: true,
    ),
    ValetTicket(
      id: 'ticket-ph-204',
      ticketNumber: '#2048',
      licensePlate: 'MH 02 AB 9940',
      carModel: 'BMW 330i',
      color: 'Sunset Orange',
      customerName: 'Neha Sharma',
      customerPhone: '+91 98330 12399',
      siteName: 'Phoenix Palladium Mall',
      siteShort: 'Phoenix',
      locationSlot: 'Deck P1 - Zone A',
      staffName: 'Sunil Jadhav',
      staffId: 'STF-05',
      staffRole: 'VALET',
      status: OperationalStatus.occupied,
      statusText: 'PARKED',
      lifecycleStatus: TicketLifecycleStatus.parked,
      checkInTime: DateTime.now().subtract(const Duration(minutes: 15)),
      amount: 150.0,
      isPaid: false,
    ),
  ];

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

