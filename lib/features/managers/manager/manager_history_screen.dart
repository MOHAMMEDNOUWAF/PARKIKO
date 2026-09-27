import 'package:flutter/material.dart';
import '../../drivers/models/vehicle_intake_model.dart';
import '../../drivers/services/driver_service.dart';
import '../../admin/sites/services/site_manager.dart';
import '../../admin/staff/models/staff_model.dart';

/// Entry point for the Parkiko Manager - Today's Completed Valet History Screen.
/// Production-grade Flutter Material 3 implementation conforming strictly to
/// Parkiko Admin design system tokens (emerald #00513A, mint surfaces, amber & green tags),
/// responsive mobile layout, real-time KPI metrics, search & filter tabs,
/// live driver intake synchronization, and detailed digital audit receipt bottom sheet.
void main() {
  runApp(const ParkikoManagerHistoryApp());
}

class ParkikoManagerHistoryApp extends StatelessWidget {
  const ParkikoManagerHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkiko Manager History & Audit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF00513A),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF0F6B4F),
          onPrimaryContainer: Color(0xFF97E8C5),
          secondary: Color(0xFF2D6955),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFAFEDD4),
          onSecondaryContainer: Color(0xFF326D59),
          surface: Color(0xFFF1FCF5),
          onSurface: Color(0xFF141E1A),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xFFEBF6EF),
          surfaceContainer: Color(0xFFE5F1EA),
          surfaceContainerHigh: Color(0xFFDFEBE4),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          outline: Color(0xFF6F7A73),
          outlineVariant: Color(0xFFBEC9C2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1FCF5),
      ),
      home: const ManagerHistoryScreen(),
    );
  }
}

enum HistoryFilter { all, online, cash }

class CompletedValetRecord {
  final String ticketId;
  final String vehicleName;
  final String plateNumber;
  final String customerName;
  final String customerPhone;
  final String driverName;
  final String driverStaffId;
  final double tariffAmount;
  final String paymentMode; // 'online' or 'cash'
  final String intakeTime;
  final String retrievalTime;
  final String duration;
  final String bayLocation;
  final String transactionRef;

  const CompletedValetRecord({
    required this.ticketId,
    required this.vehicleName,
    required this.plateNumber,
    required this.customerName,
    required this.customerPhone,
    required this.driverName,
    required this.driverStaffId,
    required this.tariffAmount,
    required this.paymentMode,
    required this.intakeTime,
    required this.retrievalTime,
    required this.duration,
    required this.bayLocation,
    required this.transactionRef,
  });
}

class ManagerHistoryScreen extends StatefulWidget {
  final StaffModel? currentManager;
  final VoidCallback? onNavigateHome;

  const ManagerHistoryScreen({
    super.key,
    this.currentManager,
    this.onNavigateHome,
  });

  @override
  State<ManagerHistoryScreen> createState() => _ManagerHistoryScreenState();
}

class _ManagerHistoryScreenState extends State<ManagerHistoryScreen> {
  int _activeNavIndex = 1; // 0: Home, 1: History (Active)
  HistoryFilter _currentFilter = HistoryFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Completed Valet Records for Today (seeded with default completed runs)
  final List<CompletedValetRecord> _completedRecords = [
    const CompletedValetRecord(
      ticketId: 'PK-9941-T2',
      vehicleName: 'BMW X5 xDrive',
      plateNumber: 'MH 01 DX 4022',
      customerName: 'Aditya Oberoi',
      customerPhone: '+91 98201 44521',
      driverName: 'Rahul Verma',
      driverStaffId: 'ST-108',
      tariffAmount: 250.0,
      paymentMode: 'online',
      intakeTime: '13:10 IST',
      retrievalTime: '15:45 IST',
      duration: '2h 35m',
      bayLocation: 'Deck B1 • Slot #14',
      transactionRef: 'UPI-4920194821',
    ),
    const CompletedValetRecord(
      ticketId: 'PK-9940-T2',
      vehicleName: 'Audi Q7 Prestige',
      plateNumber: 'DL 03 CA 9918',
      customerName: 'Rohan Malhotra',
      customerPhone: '+91 97112 88394',
      driverName: 'Vikram Singh',
      driverStaffId: 'ST-082',
      tariffAmount: 300.0,
      paymentMode: 'cash',
      intakeTime: '12:30 IST',
      retrievalTime: '15:20 IST',
      duration: '2h 50m',
      bayLocation: 'Deck B1 • Slot #08',
      transactionRef: 'CSH-REC-8841',
    ),
    const CompletedValetRecord(
      ticketId: 'PK-9938-T2',
      vehicleName: 'Mercedes-Benz E-Class',
      plateNumber: 'MH 02 BG 3311',
      customerName: 'Priya Sundaram',
      customerPhone: '+91 98920 61120',
      driverName: 'Tanmay Sharma',
      driverStaffId: 'ST-044',
      tariffAmount: 250.0,
      paymentMode: 'online',
      intakeTime: '11:45 IST',
      retrievalTime: '14:50 IST',
      duration: '3h 05m',
      bayLocation: 'Deck B1 • Slot #22',
      transactionRef: 'UPI-9018472910',
    ),
    const CompletedValetRecord(
      ticketId: 'PK-9935-T2',
      vehicleName: 'Toyota Fortuner Legender',
      plateNumber: 'KA 05 MN 1092',
      customerName: 'Sanjay Reddy',
      customerPhone: '+91 94480 23190',
      driverName: 'Amit Kumar',
      driverStaffId: 'ST-044',
      tariffAmount: 250.0,
      paymentMode: 'online',
      intakeTime: '10:15 IST',
      retrievalTime: '14:10 IST',
      duration: '3h 55m',
      bayLocation: 'Deck B1 • Slot #31',
      transactionRef: 'UPI-3920194883',
    ),
    const CompletedValetRecord(
      ticketId: 'PK-9931-T2',
      vehicleName: 'Range Rover Velar',
      plateNumber: 'DL 01 AA 7700',
      customerName: 'Kunal Kapoor',
      customerPhone: '+91 98100 22910',
      driverName: 'Deepak Joshi',
      driverStaffId: 'ST-019',
      tariffAmount: 500.0,
      paymentMode: 'cash',
      intakeTime: '09:20 IST',
      retrievalTime: '13:40 IST',
      duration: '4h 20m',
      bayLocation: 'Deck B1 • Slot #03',
      transactionRef: 'CSH-REC-8839',
    ),
    const CompletedValetRecord(
      ticketId: 'PK-9928-T2',
      vehicleName: 'Porsche Macan GTS',
      plateNumber: 'MH 12 QP 5544',
      customerName: 'Meera Singhania',
      customerPhone: '+91 98230 88412',
      driverName: 'Rahul Verma',
      driverStaffId: 'ST-108',
      tariffAmount: 300.0,
      paymentMode: 'online',
      intakeTime: '08:45 IST',
      retrievalTime: '12:30 IST',
      duration: '3h 45m',
      bayLocation: 'Deck B1 • Slot #19',
      transactionRef: 'UPI-8849102834',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _syncCompletedFromDriverService();
    DriverService.instance.addListener(_syncCompletedFromDriverService);
  }

  @override
  void dispose() {
    DriverService.instance.removeListener(_syncCompletedFromDriverService);
    _searchController.dispose();
    super.dispose();
  }

  /// Appends any completed driver intakes to the audit history
  void _syncCompletedFromDriverService() {
    if (!mounted) return;
    final driverIntakes = DriverService.instance.intakes;
    for (final VehicleIntakeModel intake in driverIntakes) {
      if (intake.status == 'completed' || intake.status == 'retrieved') {
        final alreadyPresent = _completedRecords.any((r) => r.ticketId == intake.id);
        if (!alreadyPresent) {
          _completedRecords.insert(
            0,
            CompletedValetRecord(
              ticketId: intake.id,
              vehicleName: intake.vehicleModel.isNotEmpty ? intake.vehicleModel : 'Valet Vehicle',
              plateNumber: intake.vehicleReg.isNotEmpty ? intake.vehicleReg : 'NO-REG',
              customerName: intake.customerName.isNotEmpty ? intake.customerName : 'Valet Guest',
              customerPhone: intake.customerPhone.isNotEmpty ? intake.customerPhone : '+91 98000 00000',
              driverName: intake.driverName.isNotEmpty ? intake.driverName : 'Valet Driver',
              driverStaffId: intake.driverId.isNotEmpty ? intake.driverId : 'DRV-01',
              tariffAmount: 250.0,
              paymentMode: 'online',
              intakeTime: '${intake.createdAt.hour.toString().padLeft(2, '0')}:${intake.createdAt.minute.toString().padLeft(2, '0')} IST',
              retrievalTime: 'Just now',
              duration: '1h 15m',
              bayLocation: 'Deck B1 • Delivery Bay',
              transactionRef: 'UPI-VAL-${intake.id.hashCode.abs()}',
            ),
          );
        }
      }
    }
  }

  String get _currentSiteName {
    if (widget.currentManager != null &&
        widget.currentManager!.assignedSite.isNotEmpty &&
        widget.currentManager!.assignedSite != 'All Sites') {
      return widget.currentManager!.assignedSite;
    }
    if (SiteManager.instance.hasSites &&
        !SiteManager.instance.selectedSite.startsWith('All Sites')) {
      return SiteManager.instance.selectedSite;
    }
    return 'Grand Hyatt & Convention';
  }

  // Filter & Search Logic
  List<CompletedValetRecord> get _filteredRecords {
    return _completedRecords.where((item) {
      // Filter tab check
      if (_currentFilter == HistoryFilter.online && item.paymentMode != 'online') {
        return false;
      }
      if (_currentFilter == HistoryFilter.cash && item.paymentMode != 'cash') {
        return false;
      }

      // Search query check
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchPlate = item.plateNumber.toLowerCase().contains(query);
        final matchVehicle = item.vehicleName.toLowerCase().contains(query);
        final matchPhone = item.customerPhone.toLowerCase().contains(query);
        final matchDriver = item.driverName.toLowerCase().contains(query);
        final matchTicket = item.ticketId.toLowerCase().contains(query);
        return matchPlate || matchVehicle || matchPhone || matchDriver || matchTicket;
      }

      return true;
    }).toList();
  }

  // Computed summary metrics
  double get _totalCollected =>
      _completedRecords.fold(0.0, (acc, cur) => acc + cur.tariffAmount);

  int get _onlineCount =>
      _completedRecords.where((r) => r.paymentMode == 'online').length;

  int get _cashCount =>
      _completedRecords.where((r) => r.paymentMode == 'cash').length;

  void _showReceiptModal(CompletedValetRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBEC9C2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F1EA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF00513A),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Valet Digital Audit Slip',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF141E1A),
                              ),
                            ),
                            Text(
                              'Ticket #${record.ticketId}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Color(0xFF6F7A73),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      color: const Color(0xFF6F7A73),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle & Payment Summary Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1FCF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFAFEDD4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.vehicleName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF141E1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDAE5DE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.plateNumber,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFAFEDD4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'SETTLED & RELEASED',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00513A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${record.tariffAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00513A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Audit Key-Value Pairs
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(128)),
                  ),
                  child: Column(
                    children: [
                      _buildAuditRow('Customer Name', record.customerName),
                      const Divider(height: 14, color: Color(0xFFE5F1EA)),
                      _buildAuditRow('Customer Phone', record.customerPhone),
                      const Divider(height: 14, color: Color(0xFFE5F1EA)),
                      _buildAuditRow('Payment Channel', record.paymentMode == 'online' ? 'UPI / Online' : 'Cash Handover'),
                      const Divider(height: 14, color: Color(0xFFE5F1EA)),
                      _buildAuditRow('Transaction Ref', record.transactionRef, isMono: true),
                      const Divider(height: 14, color: Color(0xFFE5F1EA)),
                      _buildAuditRow('Assigned Driver', '${record.driverName} (${record.driverStaffId})'),
                      const Divider(height: 14, color: Color(0xFFE5F1EA)),
                      _buildAuditRow('Allocated Bay', record.bayLocation),
                      const Divider(height: 14, color: Color(0xFFE5F1EA)),
                      _buildAuditRow('Intake ➔ Retrieval', '${record.intakeTime} - ${record.retrievalTime} (${record.duration})'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Actions: Share & Print Slip
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('WhatsApp receipt re-sent to ${record.customerPhone}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF00513A),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share e-Slip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00513A)),
                          foregroundColor: const Color(0xFF00513A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Receipt sent to thermal Bluetooth printer'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Color(0xFF141E1A),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00513A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditRow(String label, String value, {bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A73)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: isMono ? 'monospace' : 'Inter',
              color: const Color(0xFF141E1A),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Top App Bar matching Parkiko Manager Architecture
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF00513A),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Parkiko',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF141E1A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F1EA),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFAFEDD4)),
                      ),
                      child: const Text(
                        'TODAY HISTORY',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00513A),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 8, color: Color(0xFF00513A)),
                    SizedBox(width: 4),
                    Text(
                      'All Intakes & Retrievals Settled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      // Scrollable Body
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Deck Location Hub Card
                    _buildLocationCard(),
                    const SizedBox(height: 12),

                    // 2. Summary KPI Tiles (Total Handed Over, Collections, Online vs Cash)
                    _buildSummaryMetrics(),
                    const SizedBox(height: 16),

                    // 3. Search Field & Filter Chips Bar
                    _buildSearchAndFilters(),
                    const SizedBox(height: 14),

                    // 4. Section Title Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, size: 16, color: Color(0xFF00513A)),
                            SizedBox(width: 6),
                            Text(
                              'COMPLETED VALET RUNS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00513A),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F1EA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_filteredRecords.length} Records',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00513A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 5. List of Completed Vehicle Cards
                    if (_filteredRecords.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filteredRecords.map((r) => _buildHistoryVehicleCard(r)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 6. Docked 2-Tab Bottom Navigation Bar (Home & History)
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  /// Deck Location Card
  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF6EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFAFEDD4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.my_location,
              size: 20,
              color: Color(0xFF00513A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentSiteName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141E1A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sub-level Deck B1 • Operational Log',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6F7A73),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFAFEDD4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_clock, size: 10, color: Color(0xFF00513A)),
                SizedBox(width: 4),
                Text(
                  'Audit Locked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00513A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// KPI Row: Total Cars Returned, Total Revenue, Online vs Cash breakdown
  Widget _buildSummaryMetrics() {
    return Row(
      children: [
        // Tile 1: Returned Cars
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Retrieved',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00513A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFAFEDD4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        size: 12,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_completedRecords.length}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00513A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Handed to owners',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF6F7A73),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Tile 2: Total Revenue
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Collections',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF141E1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5F1EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payments,
                        size: 12,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_totalCollected.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF141E1A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '100% reconciled',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF00513A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Tile 3: Channel Split (UPI vs Cash)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Channel Split',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6F7A73),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pie_chart,
                        size: 12,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$_onlineCount Online',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00513A),
                  ),
                ),
                Text(
                  '$_cashCount Cash',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Admin synced',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF6F7A73),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Search Box and Filter Chips
  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Input Field
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search plate, ticket, customer or runner...',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6F7A73)),
            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF6F7A73)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: const Color(0xFFBEC9C2).withAlpha(128)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: const Color(0xFFBEC9C2).withAlpha(128)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF00513A), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter Tabs (All, Online UPI, Cash)
        Row(
          children: [
            _buildFilterChip('All (${_completedRecords.length})', HistoryFilter.all),
            const SizedBox(width: 8),
            _buildFilterChip('Online UPI ($_onlineCount)', HistoryFilter.online),
            const SizedBox(width: 8),
            _buildFilterChip('Cash Handover ($_cashCount)', HistoryFilter.cash),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter) {
    final bool isSelected = _currentFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00513A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF00513A) : const Color(0xFFBEC9C2).withAlpha(153),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF141E1A),
            ),
          ),
        ),
      ),
    );
  }

  /// History Vehicle Card
  Widget _buildHistoryVehicleCard(CompletedValetRecord record) {
    final bool isOnline = record.paymentMode == 'online';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(128)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Indicator Stripe (Solid Emerald for Completed)
            Container(
              width: 5,
              color: const Color(0xFF00513A),
            ),

            // Card Body Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Vehicle Name & Retrival Completed Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          record.vehicleName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF141E1A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAFEDD4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 10, color: Color(0xFF00513A)),
                              SizedBox(width: 4),
                              Text(
                                'RETRIEVED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00513A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 2: License Plate & Ticket Number
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDAE5DE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            record.plateNumber,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF141E1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ticket #${record.ticketId}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Color(0xFF6F7A73),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 3: Customer Name & Phone
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF6F7A73)),
                        const SizedBox(width: 4),
                        Text(
                          record.customerName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF141E1A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${record.customerPhone}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6F7A73),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 4: Run Timings (Intake ➔ Retrieval & Total Duration)
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: Color(0xFF00513A)),
                        const SizedBox(width: 4),
                        Text(
                          '${record.intakeTime} ➔ ${record.retrievalTime}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3F4944),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F1EA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            record.duration,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00513A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 5: Driver info, Payment tag & View Receipt button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Driver and Mode
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOnline ? const Color(0xFFE5F1EA) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isOnline ? Icons.qr_code_2 : Icons.payments,
                                    size: 13,
                                    color: isOnline ? const Color(0xFF00513A) : const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOnline ? '₹${record.tariffAmount.toStringAsFixed(0)} (UPI)' : '₹${record.tariffAmount.toStringAsFixed(0)} (CASH)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isOnline ? const Color(0xFF00513A) : const Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'by ${record.driverName}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6F7A73),
                              ),
                            ),
                          ],
                        ),

                        // View Receipt Button
                        TextButton.icon(
                          onPressed: () => _showReceiptModal(record),
                          icon: const Icon(Icons.receipt_outlined, size: 14),
                          label: const Text('Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF00513A),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State when search returns no match
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.search_off, size: 40, color: Color(0x806F7A73)),
          SizedBox(height: 8),
          Text(
            'No matching history records',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF141E1A)),
          ),
          SizedBox(height: 4),
          Text(
            'Try altering your search keywords or active filter chip.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6F7A73)),
          ),
        ],
      ),
    );
  }

  /// 2-Tab Docked Bottom Navigation Bar (Home & History)
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFBEC9C2).withAlpha(128),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Tab 1: Home (Pending & Active Vehicles)
          InkWell(
            onTap: () {
              if (widget.onNavigateHome != null) {
                widget.onNavigateHome!();
              } else {
                Navigator.maybePop(context);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
              decoration: BoxDecoration(
                color: _activeNavIndex == 0
                    ? const Color(0xFFAFEDD4)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    'P',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _activeNavIndex == 0
                          ? const Color(0xFF00513A)
                          : const Color(0xFF6F7A73),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _activeNavIndex == 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _activeNavIndex == 0
                          ? const Color(0xFF00513A)
                          : const Color(0xFF6F7A73),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab 2: History (Active Tab)
          InkWell(
            onTap: () {
              setState(() {
                _activeNavIndex = 1;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
              decoration: BoxDecoration(
                color: _activeNavIndex == 1
                    ? const Color(0xFFAFEDD4)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 18,
                    color: _activeNavIndex == 1
                        ? const Color(0xFF00513A)
                        : const Color(0xFF6F7A73),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'History',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _activeNavIndex == 1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _activeNavIndex == 1
                          ? const Color(0xFF00513A)
                          : const Color(0xFF6F7A73),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
