import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/valet_ticket.dart';
import '../../../core/widgets/hud_chip.dart';

final operationsFilterProvider = StateProvider<String>((ref) => 'all');
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedSiteProvider = StateProvider<String>((ref) => 'All Sites (4 Properties)');

final valetTicketsProvider = StateNotifierProvider<ValetTicketsNotifier, List<ValetTicket>>((ref) {
  return ValetTicketsNotifier();
});

class ValetTicketsNotifier extends StateNotifier<List<ValetTicket>> {
  ValetTicketsNotifier() : super(_initialSampleTickets);

  static final List<ValetTicket> _initialSampleTickets = [
    ValetTicket(
      id: '1',
      ticketNumber: '#VP-1080',
      licensePlate: 'MH-01-DE-4411',
      carModel: 'BMW 330i',
      color: 'Alpine White',
      customerName: 'Rohit Malhotra',
      customerPhone: '+91 98201 44552',
      siteName: 'Aerocity Grand (Terminal T2)',
      siteShort: 'Aerocity T2',
      locationSlot: 'Porch Lane 2 (Slot #A-14)',
      staffName: 'Arjun S.',
      staffId: '#STF-104',
      staffRole: 'T2 Valet Staff',
      status: OperationalStatus.available,
      statusText: 'RETRIEVED',
      checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      checkOutTime: DateTime.now().add(const Duration(minutes: 2)),
      amount: 250.0,
      isPaid: true,
    ),
    ValetTicket(
      id: '2',
      ticketNumber: '#VP-1082',
      licensePlate: 'MH-02-EE-8899',
      carModel: 'Mercedes GLC',
      color: 'Obsidian Black',
      customerName: 'Priya Sen',
      customerPhone: '+91 98334 11223',
      siteName: 'CyberHub Plaza (Deck A)',
      siteShort: 'CyberHub',
      locationSlot: 'Deck A - B1 (Slot #B-08)',
      staffName: 'Vikram S.',
      staffId: '#STF-082',
      staffRole: 'CyberHub Valet',
      status: OperationalStatus.occupied,
      statusText: 'PARKED',
      checkInTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      amount: 150.0,
      isPaid: false,
    ),
    ValetTicket(
      id: '3',
      ticketNumber: '#VP-1077',
      licensePlate: 'KA-04-MB-2020',
      carModel: 'Audi A6',
      color: 'Ibis White',
      customerName: 'Amit S.',
      customerPhone: '+91 97110 55667',
      siteName: 'South City Mall (Porch B)',
      siteShort: 'South City Mall',
      locationSlot: 'Porch B - Bay 1 (Ready)',
      staffName: 'Rakesh N.',
      staffId: '#STF-099',
      staffRole: 'Porch Lead',
      status: OperationalStatus.available,
      statusText: 'RETRIEVED',
      checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      amount: 200.0,
      isPaid: true,
    ),
    ValetTicket(
      id: '4',
      ticketNumber: '#VP-1065',
      licensePlate: 'DL-08-CC-1212',
      carModel: 'Tata Nexon EV',
      color: 'Daytona Grey',
      customerName: 'Kunal Verma',
      customerPhone: '+91 99100 88221',
      siteName: 'Aerocity Grand (Terminal T2)',
      siteShort: 'Aerocity T2',
      locationSlot: 'EV Deck Level 1 (#EV-02)',
      staffName: 'Deepak M.',
      staffId: '#STF-110',
      staffRole: 'EV Specialist',
      status: OperationalStatus.occupied,
      statusText: 'PARKED',
      checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 40)),
      amount: 450.0,
      isPaid: true,
    ),
    ValetTicket(
      id: '5',
      ticketNumber: '#VP-1050',
      licensePlate: 'HR-26-DK-9009',
      carModel: 'Porsche Cayenne',
      color: 'Jet Black Metallic',
      customerName: 'Ananya Roy',
      customerPhone: '+91 98111 22334',
      siteName: 'Terminal 2 Executive Deck',
      siteShort: 'T2 Executive',
      locationSlot: 'Handed Over at Gate 3',
      staffName: 'Suresh K.',
      staffId: '#STF-071',
      staffRole: 'Senior Valet',
      status: OperationalStatus.custom,
      statusText: 'COMPLETED',
      checkInTime: DateTime.now().subtract(const Duration(hours: 4, minutes: 10)),
      checkOutTime: DateTime.now().subtract(const Duration(minutes: 25)),
      amount: 500.0,
      isPaid: true,
    ),
  ];

  void addTicket(ValetTicket ticket) {
    state = [ticket, ...state];
  }

  void updateTicketStatus(String id, OperationalStatus status, String statusText, {String? newSlot}) {
    state = [
      for (final ticket in state)
        if (ticket.id == id)
          ticket.copyWith(
            status: status,
            statusText: statusText,
            locationSlot: newSlot,
            checkOutTime: status == OperationalStatus.available ? DateTime.now() : ticket.checkOutTime,
          )
        else
          ticket,
    ];
  }

  void markPaid(String id) {
    state = [
      for (final ticket in state)
        if (ticket.id == id) ticket.copyWith(isPaid: true) else ticket,
    ];
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
    if (site != 'All Sites (4 Properties)' && !ticket.siteName.contains(site) && !ticket.siteShort.contains(site)) {
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
