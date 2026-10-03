import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/parkiko_logo.dart';
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
  waitingForParking,
  parked,
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
  final DateTime? intakeTime;
  final String siteName;

  bool get isPaid =>
      status == PaymentStatus.paidCash ||
      status == PaymentStatus.paidOnline ||
      status == PaymentStatus.retrieving ||
      status == PaymentStatus.retrieved;

  bool get isUnpaid => !isPaid;

  ValetVehicleItem({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.customerPhone,
    required this.driverName,
    required this.driverStaffId,
    required this.tariffAmount,
    this.status = PaymentStatus.unpaid,
    this.intakeTime,
    this.siteName = '',
  });
}

enum VehiclePaymentFilter { all, unpaid, paid }

class ManagerDashboardScreen extends StatefulWidget {
  final StaffModel? currentManager;
  final VoidCallback? onLogout;
  final bool seedDemoData;

  const ManagerDashboardScreen({
    super.key,
    this.currentManager,
    this.onLogout,
    this.seedDemoData = false,
  });

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _activeNavIndex = 0; // 0: Home, 1: History

  // Filter state for Paid / Unpaid / All
  VehiclePaymentFilter _paymentFilter = VehiclePaymentFilter.all;

  // Static persistent map so payment status survives widget rebuilds & stream updates
  static final Map<String, PaymentStatus> _persistentPaymentStatuses = {};

  // Operational metrics
  int _activeDrivers = 0;

  static final List<ValetVehicleItem> _sampleVehicles = [];

  int get _paidCount => _vehicles.where((v) => v.isPaid).length;

  int get _unpaidCount => _vehicles.where((v) => v.isUnpaid).length;

  List<ValetVehicleItem> get _filteredVehicles {
    switch (_paymentFilter) {
      case VehiclePaymentFilter.paid:
        return _vehicles.where((v) => v.isPaid).toList();
      case VehiclePaymentFilter.unpaid:
        return _vehicles.where((v) => v.isUnpaid).toList();
      case VehiclePaymentFilter.all:
        return _vehicles;
    }
  }

  // Active list of vehicles managed by the deck manager (merged with live driver intakes)
  final List<ValetVehicleItem> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _syncWithServices();
    DriverService.instance.addListener(_syncWithServices);
    StaffManager.instance.addListener(_syncWithServices);
    SiteManager.instance.addListener(_syncWithServices);
    ManagerPaymentStats.instance.addListener(_syncWithServices);
  }

  @override
  void dispose() {
    DriverService.instance.removeListener(_syncWithServices);
    StaffManager.instance.removeListener(_syncWithServices);
    SiteManager.instance.removeListener(_syncWithServices);
    ManagerPaymentStats.instance.removeListener(_syncWithServices);
    super.dispose();
  }

  /// Syncs vehicles dynamically from live Driver Intakes and active drivers
  void _syncWithServices() {
    if (!mounted) return;

    final driverService = DriverService.instance;
    final staffManager = StaffManager.instance;

    // 1. Update active driver count
    final onDutyDrivers = staffManager.drivers.where((d) => d.isOnDuty).length;
    final activeCount = onDutyDrivers;

    // 2. Build live vehicle items from Driver Service intakes
    final liveIntakes = driverService.intakes;
    final List<ValetVehicleItem> combined = [];

    // Map existing payment statuses so they are preserved across stream updates
    final Map<String, PaymentStatus> existingStatuses = {
      for (final v in _vehicles) v.id: v.status,
    };

    String cleanPlate(String plate) =>
        plate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

    for (final VehicleIntakeModel intake in liveIntakes) {
      final cleanReg = cleanPlate(intake.vehicleReg);

      // 1. Check intake's direct persistent payment status (from Firestore / DriverService)
      PaymentStatus? st;
      if (intake.paymentStatus == 'paid_cash' ||
          (intake.isPaid && intake.paymentMode.toLowerCase() == 'cash')) {
        st = PaymentStatus.paidCash;
      } else if (intake.paymentStatus == 'paid_online' ||
          (intake.isPaid && intake.paymentMode.toLowerCase() == 'online')) {
        st = PaymentStatus.paidOnline;
      } else if (intake.isPaid) {
        st = (intake.paymentMode.toLowerCase() == 'online')
            ? PaymentStatus.paidOnline
            : PaymentStatus.paidCash;
      }

      // 2. Check static persistent cache (by ID or plate)
      st ??= _persistentPaymentStatuses[intake.id] ??
          _persistentPaymentStatuses[intake.vehicleReg] ??
          (cleanReg.isNotEmpty ? _persistentPaymentStatuses[cleanReg] : null) ??
          existingStatuses[intake.id];

      // 3. Check if a payment was registered in ManagerPaymentStats
      if (st == null ||
          (!st.toString().contains('paid') &&
              st != PaymentStatus.retrieving &&
              st != PaymentStatus.retrieved)) {
        final paymentRec = ManagerPaymentStats.instance
            .findPaymentForVehicle(intake.id, intake.vehicleReg);
        if (paymentRec != null) {
          st = (paymentRec.mode.toLowerCase() == 'cash')
              ? PaymentStatus.paidCash
              : PaymentStatus.paidOnline;
        }
      }

      final wasPaid = st != null &&
          (st == PaymentStatus.paidCash ||
              st == PaymentStatus.paidOnline ||
              st == PaymentStatus.retrieving ||
              st == PaymentStatus.retrieved);

      if (wasPaid) {
        // Cache it in persistent map so it's instantly preserved
        _persistentPaymentStatuses[intake.id] = st;
        _persistentPaymentStatuses[intake.vehicleReg] = st;
        if (cleanReg.isNotEmpty) {
          _persistentPaymentStatuses[cleanReg] = st;
        }

        // If the intake itself advanced to retrieval or completed, reflect that
        if (intake.status == 'retrieval_requested') {
          st = PaymentStatus.retrieving;
          _persistentPaymentStatuses[intake.id] = st;
        } else if (intake.status == 'completed') {
          st = PaymentStatus.retrieved;
          _persistentPaymentStatuses[intake.id] = st;
        }
      } else {
        if (intake.status == 'parked') {
          st = PaymentStatus.parked;
        } else if (intake.status == 'waiting_for_parking') {
          st = PaymentStatus.waitingForParking;
        } else if (intake.status == 'retrieval_requested') {
          st = PaymentStatus.retrieving;
        } else if (intake.status == 'completed') {
          st = PaymentStatus.retrieved;
        } else {
          st = PaymentStatus.unpaid;
        }
      }

      combined.add(
        ValetVehicleItem(
          id: intake.id,
          vehicleName: intake.vehicleModel.isNotEmpty ? intake.vehicleModel : 'Valet Vehicle',
          plateNumber: intake.vehicleReg.isNotEmpty ? intake.vehicleReg : 'PENDING REG',
          customerPhone: intake.customerPhone.isNotEmpty ? intake.customerPhone : '+91 98000 00000',
          driverName: intake.driverName.isNotEmpty ? intake.driverName : 'Valet Driver',
          driverStaffId: intake.driverId.isNotEmpty ? intake.driverId : 'DRV-01',
          tariffAmount: _getTariffForSite(intake.siteName),
          status: st,
          intakeTime: intake.createdAt,
          siteName: intake.siteName.isNotEmpty ? intake.siteName : _currentSiteName,
        ),
      );
    }

    if (widget.seedDemoData && combined.isEmpty) {
      for (final sample in _sampleVehicles) {
        final existingStatus = existingStatuses[sample.id];
        if (existingStatus != null) {
          combined.add(ValetVehicleItem(
            id: sample.id,
            vehicleName: sample.vehicleName,
            plateNumber: sample.plateNumber,
            customerPhone: sample.customerPhone,
            driverName: sample.driverName,
            driverStaffId: sample.driverStaffId,
            tariffAmount: _getTariffForSite(_currentSiteName),
            status: existingStatus,
            intakeTime: sample.intakeTime,
          ));
        } else {
          combined.add(sample);
        }
      }
    }

    setState(() {
      _activeDrivers = activeCount;
      _vehicles.clear();
      _vehicles.addAll(combined);
    });
  }

  int get _waitingForParkingCount =>
      _vehicles.where((v) => v.status == PaymentStatus.waitingForParking).length;

  int get _parkedCount =>
      _vehicles.where((v) => v.status == PaymentStatus.parked).length;

  /// Resolves the valet tariff amount directly from the Admin's site configuration.
  /// Matches candidate site name (e.g. from intake.siteName), manager's assigned site,
  /// or currently selected site in [SiteManager.instance.sites].
  double _getTariffForSite([String? siteCandidate]) {
    final sites = SiteManager.instance.sites;

    String clean(String s) => s
        .toLowerCase()
        .replaceAll('• valet desk', '')
        .replaceAll('valet desk', '')
        .replaceAll('• deck b1', '')
        .replaceAll('deck b1', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 1. Check candidate from intake
    if (siteCandidate != null && siteCandidate.trim().isNotEmpty) {
      final target = siteCandidate.trim();
      final targetClean = clean(target);

      // Exact match
      for (final site in sites) {
        if (site.name.trim() == target || site.id.trim() == target) {
          return site.baseFee;
        }
      }

      // Case-insensitive match
      for (final site in sites) {
        if (site.name.trim().toLowerCase() == target.toLowerCase()) {
          return site.baseFee;
        }
      }

      // Normalized / partial match
      if (targetClean.isNotEmpty) {
        for (final site in sites) {
          final siteClean = clean(site.name);
          if (siteClean == targetClean ||
              siteClean.contains(targetClean) ||
              targetClean.contains(siteClean)) {
            return site.baseFee;
          }
        }
      }
    }

    // 2. Check current manager's assigned site (from widget.currentManager)
    final mgrSite = widget.currentManager?.assignedSite;
    if (mgrSite != null && mgrSite.isNotEmpty && mgrSite != 'All Sites') {
      final mgrClean = clean(mgrSite);
      for (final site in sites) {
        final siteClean = clean(site.name);
        if (site.name.toLowerCase() == mgrSite.toLowerCase() ||
            (siteClean.isNotEmpty &&
                (siteClean == mgrClean ||
                    siteClean.contains(mgrClean) ||
                    mgrClean.contains(siteClean)))) {
          return site.baseFee;
        }
      }
    }

    // 3. Check current dashboard active site name
    final currentSite = _currentSiteName;
    if (currentSite.isNotEmpty && currentSite != 'All Sites') {
      final curClean = clean(currentSite);
      for (final site in sites) {
        final siteClean = clean(site.name);
        if (site.name.toLowerCase() == currentSite.toLowerCase() ||
            (siteClean.isNotEmpty &&
                (siteClean == curClean ||
                    siteClean.contains(curClean) ||
                    curClean.contains(siteClean)))) {
          return site.baseFee;
        }
      }
    }

    // 4. Try current selected site model in SiteManager
    final currentModel = SiteManager.instance.currentSiteModel;
    if (currentModel != null) {
      return currentModel.baseFee;
    }

    // 5. If sites list is non-empty, use the first configured site's base fee
    if (sites.isNotEmpty) {
      return sites.first.baseFee;
    }

    // Default fallback to standard site tariff
    return 250.0;
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
                          Expanded(
                            child: Column(
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
                                  vehicle.intakeTime != null
                                      ? 'Driver: ${vehicle.driverName} (${vehicle.driverStaffId}) • Intake: ${DateFormat('hh:mm a').format(vehicle.intakeTime!)}'
                                      : 'Driver: ${vehicle.driverName} (${vehicle.driverStaffId})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF3F4944),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
    final newStatus =
        (mode == 'cash') ? PaymentStatus.paidCash : PaymentStatus.paidOnline;
    final cleanReg = vehicle.plateNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    setState(() {
      vehicle.status = newStatus;
      _persistentPaymentStatuses[vehicle.id] = newStatus;
      _persistentPaymentStatuses[vehicle.plateNumber] = newStatus;
      if (cleanReg.isNotEmpty) {
        _persistentPaymentStatuses[cleanReg] = newStatus;
      }
    });

    final resolvedSite = vehicle.siteName.isNotEmpty ? vehicle.siteName : _currentSiteName;

    ManagerPaymentStats.instance.recordPayment(
      vehicleName: vehicle.vehicleName,
      plateNumber: vehicle.plateNumber,
      amount: vehicle.tariffAmount,
      mode: mode,
      driverName: vehicle.driverName,
      driverStaffId: vehicle.driverStaffId,
      siteName: resolvedSite,
    );

    // Explicitly update DriverService intake payment model & Firestore
    DriverService.instance.updateIntakePayment(
      vehicle.id,
      paymentMode: mode,
      amount: vehicle.tariffAmount,
      siteName: resolvedSite,
    );

    // Sync payment metadata to DriverService / Firestore
    DriverService.instance.updateIntakeStatus(
      vehicle.id,
      (vehicle.status == PaymentStatus.parked) ? 'parked' : 'waiting_for_parking',
      extraData: {
        'paymentMode': mode,
        'paymentStatus': mode == 'cash' ? 'paid_cash' : 'paid_online',
        'paymentAmount': vehicle.tariffAmount,
        'paidSite': resolvedSite,
      },
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
    final cleanReg = vehicle.plateNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    setState(() {
      vehicle.status = PaymentStatus.retrieving;
      _persistentPaymentStatuses[vehicle.id] = PaymentStatus.retrieving;
      _persistentPaymentStatuses[vehicle.plateNumber] = PaymentStatus.retrieving;
      if (cleanReg.isNotEmpty) {
        _persistentPaymentStatuses[cleanReg] = PaymentStatus.retrieving;
      }
    });

    final reqTime = DateTime.now();
    DriverService.instance.updateIntakeStatus(
      vehicle.id,
      'retrieval_requested',
      extraData: {
        'retrievalRequestedAt': reqTime,
      },
    );

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
            const ParkikoLogo(size: 34),
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
                    const SizedBox(height: 14),

                    // 2.5 Filter Tabs (All, Unpaid, Paid)
                    _buildFilterTabs(),
                    const SizedBox(height: 4),

                    // 3. Section Title Bar
                    _buildSectionHeader(),
                    const SizedBox(height: 10),

                    // 4. List of Vehicle Cards with Red/Amber Alert States & Dynamic CTAs
                    if (_filteredVehicles.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filteredVehicles.map((v) => _buildVehicleCard(v)),
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

  /// Empty state when no vehicles are active on deck or matching filter
  Widget _buildEmptyState() {
    final isFiltered = _paymentFilter != VehiclePaymentFilter.all;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(80)),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off_outlined : Icons.directions_car_filled_outlined,
            size: 40,
            color: const Color(0xFF6F7A73),
          ),
          const SizedBox(height: 10),
          Text(
            isFiltered
                ? 'No ${_paymentFilter == VehiclePaymentFilter.paid ? "Paid" : "Unpaid"} Vehicles'
                : 'No Active Vehicles on Deck',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF141E1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFiltered
                ? 'Tap another filter above or reset to view all vehicles.'
                : 'Vehicles checked in by drivers will appear here live in real-time.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A73)),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _paymentFilter = VehiclePaymentFilter.all;
                });
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Show All Vehicles'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00513A),
              ),
            ),
          ],
        ],
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
                Text(
                  'Sub-level Deck B1 • ₹${_getTariffForSite(_currentSiteName).toStringAsFixed(0)} Tariff Rate',
                  style: const TextStyle(
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

  /// 3-Column Metric Tiles: Paid, Unpaid, Active Drivers (Interactive Filters)
  Widget _buildMetricTilesRow() {
    final isPaidSelected = _paymentFilter == VehiclePaymentFilter.paid;
    final isUnpaidSelected = _paymentFilter == VehiclePaymentFilter.unpaid;

    return Row(
      children: [
        // 1. Paid Tile (Clickable Filter)
        Expanded(
          child: InkWell(
            key: const Key('tile_filter_paid'),
            onTap: () {
              setState(() {
                _paymentFilter = isPaidSelected
                    ? VehiclePaymentFilter.all
                    : VehiclePaymentFilter.paid;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isPaidSelected ? const Color(0xFFF1FCF5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPaidSelected
                      ? const Color(0xFF00513A)
                      : const Color(0xFFBEC9C2).withAlpha(128),
                  width: isPaidSelected ? 2 : 1,
                ),
                boxShadow: isPaidSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00513A).withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Paid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00513A),
                            ),
                          ),
                          if (isPaidSelected) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00513A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                  Text(
                    isPaidSelected ? 'Tap to view all' : 'All receipts synced',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: const Color(0xFF00513A),
                      fontWeight: isPaidSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 2. Unpaid Tile (Red Alert Accent - Clickable Filter)
        Expanded(
          child: InkWell(
            key: const Key('tile_filter_unpaid'),
            onTap: () {
              setState(() {
                _paymentFilter = isUnpaidSelected
                    ? VehiclePaymentFilter.all
                    : VehiclePaymentFilter.unpaid;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isUnpaidSelected ? const Color(0xFFFFF8F7) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnpaidSelected
                      ? const Color(0xFFBA1A1A)
                      : const Color(0xFFFFA4A4),
                  width: isUnpaidSelected ? 2 : 1,
                ),
                boxShadow: isUnpaidSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFBA1A1A).withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Unpaid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBA1A1A),
                            ),
                          ),
                          if (isUnpaidSelected) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBA1A1A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                  Text(
                    isUnpaidSelected ? 'Tap to view all' : 'Awaiting collection',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: const Color(0xFFBA1A1A),
                      fontWeight: isUnpaidSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
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

  /// Filter tabs above the vehicle card list
  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            count: _vehicles.length,
            isSelected: _paymentFilter == VehiclePaymentFilter.all,
            onTap: () => setState(() => _paymentFilter = VehiclePaymentFilter.all),
            selectedColor: const Color(0xFF141E1A),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Unpaid',
            count: _unpaidCount,
            isSelected: _paymentFilter == VehiclePaymentFilter.unpaid,
            onTap: () => setState(() => _paymentFilter = VehiclePaymentFilter.unpaid),
            selectedColor: const Color(0xFFBA1A1A),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Paid',
            count: _paidCount,
            isSelected: _paymentFilter == VehiclePaymentFilter.paid,
            onTap: () => setState(() => _paymentFilter = VehiclePaymentFilter.paid),
            selectedColor: const Color(0xFF00513A),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required Color selectedColor,
  }) {
    return InkWell(
      key: Key('filter_tab_${label.toLowerCase()}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFBEC9C2).withAlpha(128),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withAlpha(30),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF3F4944),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(60)
                    : const Color(0xFFE5F1EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF00513A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Header with Red/Amber Alert Indicator
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                _parkedCount > 0
                    ? Icons.local_parking_rounded
                    : (_waitingForParkingCount > 0 ? Icons.hourglass_top_rounded : Icons.circle),
                size: _parkedCount > 0 || _waitingForParkingCount > 0 ? 12 : 8,
                color: _parkedCount > 0
                    ? const Color(0xFFBA1A1A)
                    : (_waitingForParkingCount > 0 ? const Color(0xFFD97706) : const Color(0xFFBA1A1A)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _parkedCount > 0
                      ? 'PARKED VEHICLES (UNPAID)'
                      : (_waitingForParkingCount > 0
                          ? 'ACTIVE INTAKES & PENDING'
                          : 'UNPAID VEHICLES (PENDING COLLECTION)'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _parkedCount > 0
                        ? const Color(0xFFBA1A1A)
                        : (_waitingForParkingCount > 0 ? const Color(0xFF92400E) : const Color(0xFFBA1A1A)),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 6,
          children: [
            if (_parkedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB4AB)),
                ),
                child: Text(
                  '$_parkedCount Parked',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ),
            if (_waitingForParkingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  '$_waitingForParkingCount Waiting',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
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
        ),
      ],
    );
  }

  /// Vehicle Card with Left Indicator Stripe, Required Meta (From Driver Intake), and Dynamic Action Button
  Widget _buildVehicleCard(ValetVehicleItem vehicle) {
    final bool isUnpaid = vehicle.status == PaymentStatus.unpaid;
    final bool isWaiting = vehicle.status == PaymentStatus.waitingForParking;
    final bool isParked = vehicle.status == PaymentStatus.parked;
    final bool isRetrieving = vehicle.status == PaymentStatus.retrieving;
    final bool isPaid = vehicle.status == PaymentStatus.paidCash || vehicle.status == PaymentStatus.paidOnline;

    // Card Colors based on Payment State:
    // Waiting for parking -> Yellow
    // Parked (unpaid) or Unpaid -> Red
    // Paid (Cash/Online) or Retrieving -> Green
    final Color stripeColor = (isUnpaid || isParked)
        ? const Color(0xFFBA1A1A)
        : (isWaiting
            ? const Color(0xFFF59E0B)
            : const Color(0xFF00513A));

    final Color cardBorderColor = (isUnpaid || isParked)
        ? const Color(0xFFFFDAD6)
        : (isWaiting
            ? const Color(0xFFFDE68A)
            : (isPaid || isRetrieving ? const Color(0xFFAFEDD4) : const Color(0xFFFCD34D)));

    final Color cardBgColor = (isUnpaid || isParked)
        ? const Color(0xFFFFF8F7)
        : (isWaiting
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF1FCF5));

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

                    // Row 2: Vehicle License Plate & Intake Time
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                              letterSpacing: 0.5,
                              color: Color(0xFF141E1A),
                            ),
                          ),
                        ),
                        if (vehicle.intakeTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 11,
                                  color: Color(0xFF475569),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Intake: ${DateFormat('hh:mm a').format(vehicle.intakeTime!)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 3: Customer Mobile Number (From Driver)
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: (isUnpaid || isParked)
                              ? const Color(0xFFBA1A1A)
                              : (isWaiting ? const Color(0xFFD97706) : const Color(0xFF00513A)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vehicle.customerPhone,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (isUnpaid || isParked)
                                ? const Color(0xFF141E1A)
                                : (isWaiting ? const Color(0xFF92400E) : const Color(0xFF00513A)),
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

  /// Status Badge (Red UNPAID/PARKED vs Green PAID vs Green RETRIEVING vs Yellow WAITING)
  Widget _buildStatusBadge(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB4AB)),
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
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFAFEDD4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF00513A)),
              SizedBox(width: 4),
              Text(
                'PAID (CASH)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00513A),
                ),
              ),
            ],
          ),
        );

      case PaymentStatus.paidOnline:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFAFEDD4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF00513A)),
              SizedBox(width: 4),
              Text(
                'PAID (ONLINE)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00513A),
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

      case PaymentStatus.waitingForParking:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 9, color: Color(0xFFB45309)),
              SizedBox(width: 4),
              Text(
                'WAITING FOR PARKING',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );

      case PaymentStatus.parked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB4AB)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_parking_rounded, size: 10, color: Color(0xFFBA1A1A)),
              SizedBox(width: 4),
              Text(
                'PARKED',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFBA1A1A),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
    }
  }

  /// Dynamic Action Button
  /// If Unpaid, WaitingForParking, or Parked -> "Collect Payment"
  /// If Paid -> "Vehicle Retrieval" (Amber/Emerald)
  /// If Retrieving -> "In Delivery Bay" (Disabled/Mint)
  Widget _buildActionButton(ValetVehicleItem vehicle) {
    if (vehicle.status == PaymentStatus.unpaid ||
        vehicle.status == PaymentStatus.waitingForParking ||
        vehicle.status == PaymentStatus.parked) {
      final isWaiting = vehicle.status == PaymentStatus.waitingForParking;
      return ElevatedButton(
        onPressed: () => _showPaymentModal(vehicle),
        style: ElevatedButton.styleFrom(
          backgroundColor: isWaiting
              ? const Color(0xFFD97706)
              : const Color(0xFFBA1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          backgroundColor: const Color(0xFF00513A),
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
                  const ParkikoLogo(size: 16),
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
