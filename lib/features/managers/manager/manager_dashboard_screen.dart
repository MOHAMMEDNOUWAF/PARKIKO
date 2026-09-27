import 'package:flutter/material.dart';
import '../../drivers/models/vehicle_intake_model.dart';
import '../../drivers/services/driver_service.dart';
import '../../admin/sites/services/site_manager.dart';
import '../../admin/staff/models/staff_model.dart';
import '../../admin/staff/services/staff_manager.dart';
import 'manager_history_screen.dart';
import 'manager_login_screen.dart';
import 'manager_payment_stats.dart';

/// Entry point for the Parkiko Manager Operational Dashboard.
/// Production-grade Flutter Material 3 implementation conforming to
/// Parkiko Admin design system tokens, responsive mobile architecture,
/// dynamic driver intake synchronization, and interactive payment collection workflow.
void main() {
  runApp(const ParkikoManagerApp());
}

class ParkikoManagerApp extends StatelessWidget {
  const ParkikoManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkiko Manager Operational Dashboard',
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
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF93000A),
          outline: Color(0xFF6F7A73),
          outlineVariant: Color(0xFFBEC9C2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1FCF5),
      ),
      home: const ManagerAuthWrapper(),
    );
  }
}

/// Authentication wrapper displaying ManagerLoginScreen when unauthenticated,
/// or navigating to ManagerDashboardScreen upon successful login.
class ManagerAuthWrapper extends StatefulWidget {
  const ManagerAuthWrapper({super.key});

  @override
  State<ManagerAuthWrapper> createState() => _ManagerAuthWrapperState();
}

class _ManagerAuthWrapperState extends State<ManagerAuthWrapper> {
  StaffModel? _authenticatedManager;

  @override
  Widget build(BuildContext context) {
    if (_authenticatedManager == null) {
      return ManagerLoginScreen(
        onLoginSuccess: (manager) {
          setState(() {
            _authenticatedManager = manager;
          });
        },
      );
    }

    return ManagerDashboardScreen(
      currentManager: _authenticatedManager,
      onLogout: () {
        setState(() {
          _authenticatedManager = null;
        });
      },
    );
  }
}

enum PaymentStatus {
  unpaid,
  paidCash,
  paidOnline,
  retrieving,
  retrieved,
}

class ValetVehicleItem {
  final String id;
  final String vehicleName;
  final String plateNumber;
  final String customerPhone;
  final String driverName;
  final String driverStaffId;
  final double tariffAmount;
  PaymentStatus status;

  ValetVehicleItem({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.customerPhone,
    required this.driverName,
    required this.driverStaffId,
    required this.tariffAmount,
    this.status = PaymentStatus.unpaid,
  });
}

class ManagerDashboardScreen extends StatefulWidget {
  final StaffModel? currentManager;
  final VoidCallback? onLogout;

  const ManagerDashboardScreen({
    super.key,
    this.currentManager,
    this.onLogout,
  });

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _activeNavIndex = 0; // 0: Home, 1: History

  // Operational metrics
  int _paidCount = 18;
  int _activeDrivers = 8;

  // Active list of vehicles managed by the deck manager (merged with live driver intakes)
  final List<ValetVehicleItem> _vehicles = [];

  // Default seed vehicles in case driver service has not logged any yet
  final List<ValetVehicleItem> _sampleVehicles = [
    ValetVehicleItem(
      id: 'V-001',
      vehicleName: 'BMW X5 xDrive',
      plateNumber: 'MH 01 DX 4022',
      customerPhone: '+91 98201 44521',
      driverName: 'Rahul Verma',
      driverStaffId: 'ST-108',
      tariffAmount: 250.0,
      status: PaymentStatus.unpaid,
    ),
    ValetVehicleItem(
      id: 'V-002',
      vehicleName: 'Audi Q7 Prestige',
      plateNumber: 'DL 03 CA 9918',
      customerPhone: '+91 97112 88394',
      driverName: 'Vikram Singh',
      driverStaffId: 'ST-082',
      tariffAmount: 250.0,
      status: PaymentStatus.unpaid,
    ),
    ValetVehicleItem(
      id: 'V-003',
      vehicleName: 'Mercedes E-Class',
      plateNumber: 'MH 02 BG 3311',
      customerPhone: '+91 98920 61120',
      driverName: 'Tanmay Sharma',
      driverStaffId: 'ST-044',
      tariffAmount: 250.0,
      status: PaymentStatus.unpaid,
    ),
    ValetVehicleItem(
      id: 'V-004',
      vehicleName: 'Toyota Fortuner',
      plateNumber: 'KA 05 MN 1092',
      customerPhone: '+91 94480 23190',
      driverName: 'Amit Kumar',
      driverStaffId: 'ST-044',
      tariffAmount: 250.0,
      status: PaymentStatus.unpaid,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _syncWithServices();
    DriverService.instance.addListener(_syncWithServices);
    StaffManager.instance.addListener(_syncWithServices);
    SiteManager.instance.addListener(_syncWithServices);
  }

  @override
  void dispose() {
    DriverService.instance.removeListener(_syncWithServices);
    StaffManager.instance.removeListener(_syncWithServices);
    SiteManager.instance.removeListener(_syncWithServices);
    super.dispose();
  }

  /// Syncs vehicles dynamically from live Driver Intakes and active drivers
  void _syncWithServices() {
    if (!mounted) return;

    final driverService = DriverService.instance;
    final staffManager = StaffManager.instance;

    // 1. Update active driver count
    final onDutyDrivers = staffManager.drivers.where((d) => d.isOnDuty).length;
    final activeCount = onDutyDrivers > 0 ? onDutyDrivers : 8;

    // 2. Build live vehicle items from Driver Service intakes
    final liveIntakes = driverService.intakes;
    final List<ValetVehicleItem> combined = [];

    // Map existing payment statuses so they are preserved across stream updates
    final Map<String, PaymentStatus> existingStatuses = {
      for (final v in _vehicles) v.id: v.status,
    };

    for (final VehicleIntakeModel intake in liveIntakes) {
      PaymentStatus st = existingStatuses[intake.id] ?? PaymentStatus.unpaid;
      if (intake.status == 'retrieval_requested') {
        st = PaymentStatus.retrieving;
      } else if (intake.status == 'completed') {
        st = PaymentStatus.retrieved;
      }

      combined.add(
        ValetVehicleItem(
          id: intake.id,
          vehicleName: intake.vehicleModel.isNotEmpty ? intake.vehicleModel : 'Valet Vehicle',
          plateNumber: intake.vehicleReg.isNotEmpty ? intake.vehicleReg : 'PENDING REG',
          customerPhone: intake.customerPhone.isNotEmpty ? intake.customerPhone : '+91 98000 00000',
          driverName: intake.driverName.isNotEmpty ? intake.driverName : 'Valet Driver',
          driverStaffId: intake.driverId.isNotEmpty ? intake.driverId : 'DRV-01',
          tariffAmount: 250.0,
          status: st,
        ),
      );
    }

    // If driver service has no intakes yet, include sample items for testing
    if (combined.isEmpty) {
      for (final sample in _sampleVehicles) {
        final st = existingStatuses[sample.id] ?? sample.status;
        combined.add(
          ValetVehicleItem(
            id: sample.id,
            vehicleName: sample.vehicleName,
            plateNumber: sample.plateNumber,
            customerPhone: sample.customerPhone,
            driverName: sample.driverName,
            driverStaffId: sample.driverStaffId,
            tariffAmount: sample.tariffAmount,
            status: st,
          ),
        );
      }
    }

    setState(() {
      _activeDrivers = activeCount;
      _vehicles.clear();
      _vehicles.addAll(combined);
    });
  }

  int get _unpaidCount =>
      _vehicles.where((v) => v.status == PaymentStatus.unpaid).length;

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

  void _showPaymentModal(ValetVehicleItem vehicle) {
    String selectedMode = 'online';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                    // Handle bar
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

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: Color(0xFFBA1A1A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Collect Valet Payment',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF141E1A),
                                  ),
                                ),
                                Text(
                                  vehicle.vehicleName,
                                  style: const TextStyle(
                                    fontSize: 12,
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

                    // Vehicle & Customer Brief (From Driver Intake)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1FCF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFAFEDD4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDAE5DE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  vehicle.plateNumber,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF141E1A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Driver: ${vehicle.driverName} (${vehicle.driverStaffId})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3F4944),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Fee Due',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6F7A73),
                                ),
                              ),
                              Text(
                                '₹${vehicle.tariffAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00513A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Options (Cash vs Online)
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141E1A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // Cash Option
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedMode = 'cash';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedMode == 'cash'
                                    ? const Color(0xFFFFF8E1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedMode == 'cash'
                                      ? const Color(0xFFFFA000)
                                      : const Color(0xFFBEC9C2),
                                  width: selectedMode == 'cash' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.payments,
                                    color: selectedMode == 'cash'
                                        ? const Color(0xFFFFA000)
                                        : const Color(0xFF6F7A73),
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Cash Collection',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF141E1A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Desk Handover',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF6F7A73),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Online Option (UPI / POS)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                selectedMode = 'online';
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedMode == 'online'
                                    ? const Color(0xFFFFF8E1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedMode == 'online'
                                      ? const Color(0xFFFFA000)
                                      : const Color(0xFFBEC9C2),
                                  width: selectedMode == 'online' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.qr_code_2,
                                    color: selectedMode == 'online'
                                        ? const Color(0xFFFFA000)
                                        : const Color(0xFF6F7A73),
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Online / UPI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF141E1A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Dynamic QR / POS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF6F7A73),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Confirm CTA
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmPayment(vehicle, selectedMode);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB45309), // Amber 700
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm ₹${vehicle.tariffAmount.toStringAsFixed(0)} ${selectedMode == 'cash' ? 'Cash' : 'Online'} Payment',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmPayment(ValetVehicleItem vehicle, String mode) {
    setState(() {
      vehicle.status =
          (mode == 'cash') ? PaymentStatus.paidCash : PaymentStatus.paidOnline;
      _paidCount += 1;
    });

    ManagerPaymentStats.instance.recordPayment(
      vehicleName: vehicle.vehicleName,
      plateNumber: vehicle.plateNumber,
      amount: vehicle.tariffAmount,
      mode: mode,
      driverName: vehicle.driverName,
      driverStaffId: vehicle.driverStaffId,
      siteName: _currentSiteName,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFAFEDD4), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payment received via ${mode.toUpperCase()} for ${vehicle.plateNumber}. Synced to Admin Ledger.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00513A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _initiateVehicleRetrieval(ValetVehicleItem vehicle) {
    setState(() {
      vehicle.status = PaymentStatus.retrieving;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.key, color: Color(0xFFFDE68A), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vehicle Retrieval dispatched! Runner notified for ${vehicle.plateNumber}.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF141E1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleLogout() {
    if (widget.onLogout != null) {
      widget.onLogout!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ManagerLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final managerName = widget.currentManager?.name ?? 'Deck Operations Lead';

    return Scaffold(
      // Top App Bar
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            // Parkiko brand square avatar badge
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
            Expanded(
              child: Column(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F1EA),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFAFEDD4)),
                        ),
                        child: const Text(
                          'DECK MGR',
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
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 7, color: Color(0xFF00513A)),
                      const SizedBox(width: 4),
                      Text(
                        '$managerName • Duty Active',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3F4944),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF6F7A73), size: 20),
            tooltip: 'Logout of Manager Deck',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Logout Manager Deck?'),
                  content: const Text('Are you sure you want to end your current manager session?'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA1A1A),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _handleLogout();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // Main Scrollable Area
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

                    // 2. Three Metric Counter Tiles (Paid, Unpaid, Active Drivers)
                    _buildMetricTilesRow(),
                    const SizedBox(height: 18),

                    // 3. Section Title Bar
                    _buildSectionHeader(),
                    const SizedBox(height: 10),

                    // 4. List of Vehicle Cards with Red/Amber Alert States & Dynamic CTAs
                    ..._vehicles.map((v) => _buildVehicleCard(v)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 5. Docked 2-Tab Bottom Navigation Bar (Home & History)
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
                  'Sub-level Deck B1 • Auto Allocation Mode',
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
                Icon(Icons.circle, size: 6, color: Color(0xFF00513A)),
                SizedBox(width: 4),
                Text(
                  'Live Sync',
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

  /// 3-Column Metric Tiles: Paid, Unpaid, Active Drivers
  Widget _buildMetricTilesRow() {
    return Row(
      children: [
        // 1. Paid Tile
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      'Paid',
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
                        Icons.check,
                        size: 12,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_paidCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00513A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'cleared',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6F7A73),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'All receipts synced',
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

        // 2. Unpaid Tile (Red Alert Accent)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFA4A4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Unpaid',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFDAD6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payments,
                        size: 12,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_unpaidCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'pending',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Awaiting collection',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFFBA1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Active Drivers Tile (Live From StaffManager)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      'Drivers',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5F1EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.badge,
                        size: 12,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_activeDrivers',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00513A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'active',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6F7A73),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'All on duty',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF6F7A73),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Section Header with Red/Amber Alert Indicator
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.circle, size: 8, color: Color(0xFFBA1A1A)),
            SizedBox(width: 6),
            Text(
              'UNPAID VEHICLES (PENDING COLLECTION)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFBA1A1A),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$_unpaidCount Pending',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBA1A1A),
            ),
          ),
        ),
      ],
    );
  }

  /// Vehicle Card with Left Indicator Stripe, Required Meta (From Driver Intake), and Dynamic Action Button
  Widget _buildVehicleCard(ValetVehicleItem vehicle) {
    final bool isUnpaid = vehicle.status == PaymentStatus.unpaid;
    final bool isRetrieving = vehicle.status == PaymentStatus.retrieving;

    // Card Colors based on Payment State
    final Color stripeColor = isUnpaid
        ? const Color(0xFFBA1A1A)
        : (isRetrieving ? const Color(0xFF00513A) : const Color(0xFFD97706)); // Amber 600

    final Color cardBorderColor = isUnpaid
        ? const Color(0xFFBEC9C2).withAlpha(128)
        : const Color(0xFFFCD34D); // Amber 300

    final Color cardBgColor = isUnpaid ? Colors.white : const Color(0xFFFFFBEB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Alert Accent Bar (5dp width)
            Container(
              width: 5,
              color: stripeColor,
            ),

            // Card Body Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Vehicle Name & Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.vehicleName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF141E1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(vehicle.status),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 2: Vehicle License Plate (From Driver)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDAE5DE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vehicle.plateNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: Color(0xFF141E1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 3: Customer Mobile Number (From Driver)
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: isUnpaid
                              ? const Color(0xFFBA1A1A)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.customerPhone,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUnpaid
                                ? const Color(0xFF141E1A)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 4: Assigned Driver Name & ID + Dynamic Action Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Driver Info from intake
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 15,
                                color: Color(0xFF6F7A73),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${vehicle.driverName} (ID: ${vehicle.driverStaffId})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3F4944),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action Button (Morphs from Collect Payment -> Vehicle Retrieval)
                        _buildActionButton(vehicle),
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

  /// Status Badge (Red UNPAID vs Amber PAID vs Green RETRIEVING)
  Widget _buildStatusBadge(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: Color(0xFFBA1A1A)),
              SizedBox(width: 4),
              Text(
                'UNPAID',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
        );

      case PaymentStatus.paidCash:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: Color(0xFFD97706)),
              SizedBox(width: 4),
              Text(
                'PAID (CASH)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        );

      case PaymentStatus.paidOnline:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: Color(0xFFD97706)),
              SizedBox(width: 4),
              Text(
                'PAID (ONLINE)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        );

      case PaymentStatus.retrieving:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFAFEDD4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car, size: 10, color: Color(0xFF00513A)),
              SizedBox(width: 4),
              Text(
                'RETRIEVAL DISPATCHED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00513A),
                ),
              ),
            ],
          ),
        );

      case PaymentStatus.retrieved:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDAE5DE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'HANDED OVER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3F4944),
            ),
          ),
        );
    }
  }

  /// Dynamic Action Button
  /// If Unpaid -> "Collect Payment" (Red)
  /// If Paid -> "Vehicle Retrieval" (Amber/Emerald)
  /// If Retrieving -> "In Delivery Bay" (Disabled/Mint)
  Widget _buildActionButton(ValetVehicleItem vehicle) {
    if (vehicle.status == PaymentStatus.unpaid) {
      return ElevatedButton(
        onPressed: () => _showPaymentModal(vehicle),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBA1A1A), // Red
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Collect Payment',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (vehicle.status == PaymentStatus.paidCash ||
        vehicle.status == PaymentStatus.paidOnline) {
      // Changed to Vehicle Retrieval Button
      return ElevatedButton.icon(
        onPressed: () => _initiateVehicleRetrieval(vehicle),
        icon: const Icon(Icons.key, size: 14),
        label: const Text(
          'Vehicle Retrieval',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD97706), // Amber
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    } else {
      // Retrieving in progress
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.schedule, size: 14, color: Color(0xFF00513A)),
        label: const Text(
          'Runner Dispatched',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF00513A),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFAFEDD4)),
          backgroundColor: const Color(0xFFEBF6EF),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Tab 1: Home
          InkWell(
            onTap: () {
              setState(() {
                _activeNavIndex = 0;
              });
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

          // Tab 2: History
          InkWell(
            onTap: () {
              setState(() {
                _activeNavIndex = 1;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManagerHistoryScreen(
                    currentManager: widget.currentManager,
                    onNavigateHome: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ).then((_) {
                if (mounted) {
                  setState(() {
                    _activeNavIndex = 0;
                  });
                }
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
