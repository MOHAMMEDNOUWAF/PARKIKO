import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/parkiko_logo.dart';
import '../../admin/sites/services/site_manager.dart';
import '../../admin/staff/models/staff_model.dart';
import '../../admin/staff/services/staff_manager.dart';
import '../../drivers/models/vehicle_intake_model.dart';
import '../../drivers/services/driver_service.dart';
import 'assistant_manager_stats.dart';

/// Parkiko Valet Ops - Assistant Manager Screen.
/// Conforms to Flutter Material 3, strict Parkiko Admin/Ops design tokens,
/// responsive mobile layout, urgent retrieval dispatching, parked vehicle retrieval,
/// live shift history log, and dynamic interactive toasts.
void main() {
  runApp(const ParkikoAssistantManagerApp());
}

class ParkikoAssistantManagerApp extends StatelessWidget {
  const ParkikoAssistantManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkiko Valet Ops - Assistant Manager',
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
          surfaceContainerHighest: Color(0xFFDAE5DE),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF93000A),
          outline: Color(0xFF6F7A73),
          outlineVariant: Color(0xFFBEC9C2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1FCF5),
      ),
      home: const AssistantManagerScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class QuickRunnerChipData {
  final String code;
  final String label;

  const QuickRunnerChipData(this.code, this.label);
}

class UrgentRetrievalItem {
  final String id;
  final String orderNumber;
  final String vehicleName;
  final String plateNumber;
  final String guestName;
  final String sourceTag; // e.g. 'WhatsApp e-Pass', 'Manager Curbside', 'Bay Call'
  final IconData sourceIcon;
  final Color sourceBg;
  final Color sourceTextColor;
  final String paymentText; // 'PAID ₹250 (UPI)', 'UNPAID ₹300 (Collect)'
  final bool isPaid;
  final String timerText;
  final String runnerStatusText;
  final String runnerPlaceholder;
  final List<QuickRunnerChipData> quickChips;
  final bool isAutoRunner;
  final TextEditingController runnerController;
  final FocusNode focusNode;

  UrgentRetrievalItem({
    required this.id,
    required this.orderNumber,
    required this.vehicleName,
    required this.plateNumber,
    required this.guestName,
    required this.sourceTag,
    required this.sourceIcon,
    required this.sourceBg,
    required this.sourceTextColor,
    required this.paymentText,
    required this.isPaid,
    required this.timerText,
    this.runnerStatusText = '5 available now',
    this.runnerPlaceholder = '108',
    this.quickChips = const [],
    this.isAutoRunner = false,
    String initialRunner = '',
  })  : runnerController = TextEditingController(text: initialRunner),
        focusNode = FocusNode();
}

class ParkedVehicleItem {
  final String id;
  final String vehicleName;
  final String plateNumber;
  final String guestName;
  final String parkedBy;
  final String parkedAgo;
  final String slotPosition;
  final String vaultBox;
  final String paymentText;
  final bool isPaid;
  final bool isEv;
  final String status; // 'waiting_for_parking', 'parked', 'retrieval_requested', 'completed'
  final DateTime? retrievalRequestedAt;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String siteName;
  final String customerPhone;
  final DateTime? intakeTime;

  bool get isWaitingForParking => status == 'waiting_for_parking';
  bool get isParked => status == 'parked';
  bool get isParkedReady => status == 'parked';
  bool get isRetrievalRequested => status == 'retrieval_requested';
  bool get isCompleted => status == 'completed';

  const ParkedVehicleItem({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.guestName,
    required this.parkedBy,
    required this.parkedAgo,
    required this.slotPosition,
    required this.vaultBox,
    required this.paymentText,
    required this.isPaid,
    this.isEv = false,
    this.status = 'parked',
    this.retrievalRequestedAt,
    this.assignedDriverId,
    this.assignedDriverName,
    this.siteName = '',
    this.customerPhone = '',
    this.intakeTime,
  });

  ParkedVehicleItem copyWith({
    String? id,
    String? vehicleName,
    String? plateNumber,
    String? guestName,
    String? parkedBy,
    String? parkedAgo,
    String? slotPosition,
    String? vaultBox,
    String? paymentText,
    bool? isPaid,
    bool? isEv,
    String? status,
    DateTime? retrievalRequestedAt,
    String? assignedDriverId,
    String? assignedDriverName,
    String? siteName,
    String? customerPhone,
    DateTime? intakeTime,
  }) {
    return ParkedVehicleItem(
      id: id ?? this.id,
      vehicleName: vehicleName ?? this.vehicleName,
      plateNumber: plateNumber ?? this.plateNumber,
      guestName: guestName ?? this.guestName,
      parkedBy: parkedBy ?? this.parkedBy,
      parkedAgo: parkedAgo ?? this.parkedAgo,
      slotPosition: slotPosition ?? this.slotPosition,
      vaultBox: vaultBox ?? this.vaultBox,
      paymentText: paymentText ?? this.paymentText,
      isPaid: isPaid ?? this.isPaid,
      isEv: isEv ?? this.isEv,
      status: status ?? this.status,
      retrievalRequestedAt: retrievalRequestedAt ?? this.retrievalRequestedAt,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      siteName: siteName ?? this.siteName,
      customerPhone: customerPhone ?? this.customerPhone,
      intakeTime: intakeTime ?? this.intakeTime,
    );
  }
}

class HistoryDispatchItem {
  final String id;
  final String orderNumber;
  final String vehicleName;
  final String plateNumber;
  final String guestName;
  final String runnerLabel;
  final String timeLabel;
  final String paymentText;
  final String handoverTime;
  final bool isJustDispatched;

  const HistoryDispatchItem({
    required this.id,
    required this.orderNumber,
    required this.vehicleName,
    required this.plateNumber,
    required this.guestName,
    required this.runnerLabel,
    required this.timeLabel,
    required this.paymentText,
    required this.handoverTime,
    this.isJustDispatched = false,
  });
}

// ---------------------------------------------------------------------------
// MAIN SCREEN WIDGET
// ---------------------------------------------------------------------------

class AssistantManagerScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final StaffModel? currentAssistantManager;
  final String? assignedSite;
  final bool seedDemoData;

  const AssistantManagerScreen({
    super.key,
    this.onBack,
    this.onLogout,
    this.currentAssistantManager,
    this.assignedSite,
    this.seedDemoData = false,
  });

  @override
  State<AssistantManagerScreen> createState() => _AssistantManagerScreenState();
}

class _AssistantManagerScreenState extends State<AssistantManagerScreen>
    with SingleTickerProviderStateMixin {
  // Navigation: 0 = Retrieval & Dispatch, 1 = History
  int _activeNavIndex = 0;

  // Pulse animation for urgent red alerts
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Parked ready list state (unified single listing for all parked and retrieval vehicles)
  final List<ParkedVehicleItem> _parkedItems = [];

  // Live vehicle intakes (live from Driver Service)
  final List<VehicleIntakeModel> _liveIntakes = [];
  final List<VehicleIntakeModel> _waitingForParkingIntakes = [];

  // History log state
  final List<HistoryDispatchItem> _historyItems = [];

  // Chosen driver by vehicle ID (site only)
  final Map<String, String> _selectedDriverByVehicleId = {};
  final Map<String, String> _selectedDriverNameByVehicleId = {};

  // Live timer ticker for retrieval duration
  Timer? _tickerTimer;

  // Floating Toast notification state
  String? _toastMessage;
  Timer? _toastTimer;
  Timer? _dispatchNavTimer;

  // History badge indicator for new dispatches
  int _newHistoryBadgeCount = 0;

  /// Push current list counts to the shared stats singleton so that
  /// LiveOperationsScreen (admin) can read them without coupling.
  void _pushStats() {
    AssistantManagerStats.instance.update(
      parked: _parkedItems.where((p) => !p.isRetrievalRequested).length,
      retrieved: _parkedItems.where((p) => p.isRetrievalRequested).length,
      completed: _historyItems.length,
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    // Publish updated counts after every state change.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushStats());
  }

  @override
  void initState() {
    super.initState();

    if (widget.seedDemoData) {
      _seedDemoData();
    }

    StaffManager.instance.addListener(_onStaffOrSiteChanged);
    SiteManager.instance.addListener(_onStaffOrSiteChanged);

    // Subscribe to DriverService for live vehicle intakes
    DriverService.instance.addListener(_syncLiveIntakes);
    _syncLiveIntakes();

    // Pulse animation controller for urgent cards & ping indicators
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 1-second live ticker so time elapsed from retrieval ticks smoothly
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _parkedItems.any((p) => p.isRetrievalRequested)) {
        setState(() {});
      }
    });

    // Push initial counts (before first setState)
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushStats());
  }

  void _seedDemoData() {
    _parkedItems.addAll([
      ParkedVehicleItem(
        id: 'parked-urgent-1',
        vehicleName: 'BMW X5 xDrive40i',
        plateNumber: 'MH 01 DX 4022',
        guestName: 'Rohan Verma (VIP)',
        parkedBy: 'Amir (PK-104)',
        parkedAgo: '14m ago',
        slotPosition: 'Deck B1 • Slot #18',
        vaultBox: 'Box #04',
        paymentText: 'PAID ₹250 (UPI)',
        isPaid: true,
        isEv: false,
        status: 'retrieval_requested',
        retrievalRequestedAt: DateTime.now().subtract(const Duration(minutes: 1, seconds: 42)),
        siteName: _currentSiteName,
      ),
      ParkedVehicleItem(
        id: 'parked-urgent-2',
        vehicleName: 'Mercedes GLC 300',
        plateNumber: 'DL 01 AA 7700',
        guestName: 'Sanjay Goel',
        parkedBy: 'Dev (PK-112)',
        parkedAgo: '28m ago',
        slotPosition: 'Deck B1 • Slot #25',
        vaultBox: 'Box #09',
        paymentText: 'UNPAID ₹300 (Collect)',
        isPaid: false,
        isEv: false,
        status: 'retrieval_requested',
        retrievalRequestedAt: DateTime.now().subtract(const Duration(seconds: 38)),
        siteName: _currentSiteName,
      ),
      ParkedVehicleItem(
        id: 'parked-1',
        vehicleName: 'Audi A6 TFSI Matrix',
        plateNumber: 'KA 03 MX 9012',
        guestName: 'Vikram Sethi',
        parkedBy: 'Amir (PK-104)',
        parkedAgo: '18m ago',
        slotPosition: 'Deck B1 • Slot #42',
        vaultBox: 'Box #12',
        paymentText: 'PAID ₹250',
        isPaid: true,
        isEv: false,
        status: 'parked',
        siteName: _currentSiteName,
      ),
      ParkedVehicleItem(
        id: 'parked-2',
        vehicleName: 'Hyundai Ioniq 5 EV',
        plateNumber: 'MH 12 TC 5500',
        guestName: 'Pooja Hegde',
        parkedBy: 'Rohan (PK-108)',
        parkedAgo: '34m ago',
        slotPosition: 'Deck B1 • Bay #09',
        vaultBox: 'Box #08',
        paymentText: 'UNPAID ₹300',
        isPaid: false,
        isEv: true,
        status: 'parked',
        siteName: _currentSiteName,
      ),
    ]);

    _historyItems.addAll([
      const HistoryDispatchItem(
        id: 'hist-1',
        orderNumber: 'Order #VK-879',
        vehicleName: 'Porsche Macan GTS',
        plateNumber: 'MH 02 EF 1290',
        guestName: 'Kabir Singhania',
        runnerLabel: 'PK-108 (Rohan)',
        timeLabel: '2m ago',
        paymentText: 'PAID ₹400',
        handoverTime: 'Handover in 01:20s',
      ),
    ]);
  }

  @override
  void dispose() {
    StaffManager.instance.removeListener(_onStaffOrSiteChanged);
    SiteManager.instance.removeListener(_onStaffOrSiteChanged);
    DriverService.instance.removeListener(_syncLiveIntakes);
    _pulseController.dispose();
    _toastTimer?.cancel();
    _dispatchNavTimer?.cancel();
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _onStaffOrSiteChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Live sync of driver vehicle intakes with 'waiting_for_parking', 'parked', and 'retrieval_requested' statuses
  void _syncLiveIntakes() {
    if (!mounted) return;
    final live = DriverService.instance.intakes;
    setState(() {
      _liveIntakes.clear();
      _liveIntakes.addAll(
        live.where((i) =>
            i.status == 'waiting_for_parking' ||
            i.status == 'parked' ||
            i.status == 'retrieval_requested'),
      );
      _waitingForParkingIntakes.clear();
      _waitingForParkingIntakes.addAll(
        live.where((i) => i.status == 'waiting_for_parking'),
      );

      // Clean up parked items so they accurately mirror live intakes
      _parkedItems.removeWhere((p) =>
          !p.id.startsWith('parked-') &&
          !live.any((i) =>
              i.id == p.id &&
              (i.status == 'waiting_for_parking' ||
                  i.status == 'parked' ||
                  i.status == 'retrieval_requested')));

      final activeIntakes = live.where((i) =>
          i.status == 'waiting_for_parking' ||
          i.status == 'parked' ||
          i.status == 'retrieval_requested');

      for (final intake in activeIntakes) {
        final existingIdx = _parkedItems.indexWhere((p) => p.id == intake.id);
        final boxNum = intake.keyTag != null && intake.keyTag!.isNotEmpty
            ? intake.keyTag!.replaceAll(RegExp(r'[^0-9]'), '')
            : '12';
        final paymentStr = intake.isPaid
            ? 'PAID ₹${(intake.paymentAmount ?? _getTariffForSite(intake.siteName)).toStringAsFixed(0)} (${intake.paymentMode.isNotEmpty ? intake.paymentMode.toUpperCase() : "PAID"})'
            : 'UNPAID ₹${_getTariffForSite(intake.siteName).toStringAsFixed(0)} (Collect)';

        final item = ParkedVehicleItem(
          id: intake.id,
          vehicleName: intake.vehicleModel.isNotEmpty ? intake.vehicleModel : 'Valet Vehicle',
          plateNumber: intake.vehicleReg.isNotEmpty ? intake.vehicleReg : 'KL-XX',
          guestName: intake.customerName.isNotEmpty ? intake.customerName : 'Guest Customer',
          parkedBy: intake.driverName.isNotEmpty
              ? intake.driverName
              : (intake.driverId.isNotEmpty ? intake.driverId : 'Driver'),
          parkedAgo: 'Just now',
          slotPosition: 'Deck B1 • Slot #${boxNum.isNotEmpty ? boxNum : "12"}',
          vaultBox: 'Box #${boxNum.isNotEmpty ? boxNum : "12"}',
          paymentText: paymentStr,
          isPaid: intake.isPaid,
          isEv: false,
          status: intake.status,
          retrievalRequestedAt: intake.retrievalRequestedAt,
          assignedDriverId: intake.assignedDriverId ?? _selectedDriverByVehicleId[intake.id],
          assignedDriverName: intake.assignedDriverName ?? _selectedDriverNameByVehicleId[intake.id],
          siteName: intake.siteName.isNotEmpty ? intake.siteName : _currentSiteName,
          customerPhone: intake.customerPhone,
          intakeTime: intake.createdAt,
        );

        if (existingIdx != -1) {
          _parkedItems[existingIdx] = item;
        } else {
          _parkedItems.insert(0, item);
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE WORKFLOW METHODS
  // ---------------------------------------------------------------------------

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A), size: 22),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141E1A),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of the Assistant Manager terminal?',
          style: TextStyle(fontSize: 13, color: Color(0xFF6F7A73)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6F7A73),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  bool _isToastError = false;

  void _showToast(String message, {bool isError = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _isToastError = isError;
    });
    _toastTimer = Timer(Duration(milliseconds: isError ? 4000 : 3200), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
          _isToastError = false;
        });
      }
    });
  }

  String get _currentSiteName {
    if (widget.assignedSite != null &&
        widget.assignedSite!.isNotEmpty &&
        widget.assignedSite != 'All Sites') {
      return widget.assignedSite!;
    }
    if (widget.currentAssistantManager != null &&
        widget.currentAssistantManager!.assignedSite.isNotEmpty &&
        widget.currentAssistantManager!.assignedSite != 'All Sites') {
      return widget.currentAssistantManager!.assignedSite;
    }
    if (SiteManager.instance.hasSites &&
        !SiteManager.instance.selectedSite.startsWith('All Sites')) {
      return SiteManager.instance.selectedSite;
    }
    return 'Grand Hyatt • Deck B1';
  }

  /// Determines whether two site names represent the same site / property.
  /// Accounts for deck/sub-location suffixes (e.g. 'Grand Hyatt & Convention' vs 'Grand Hyatt • Deck B1').
  bool _isSameSite(String siteA, String siteB) {
    final cleanA = siteA.trim().toLowerCase();
    final cleanB = siteB.trim().toLowerCase();
    if (cleanA.isEmpty && cleanB.isEmpty) return true;
    if (cleanA.isEmpty || cleanB.isEmpty) return false;
    if (cleanA == cleanB) return true;
    if (cleanA == 'all sites' || cleanB == 'all sites') return true;

    String extractBase(String s) {
      var base = s.split('•').first.split('-').first.split('&').first.trim().toLowerCase();
      base = base.replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim();
      return base;
    }

    final baseA = extractBase(cleanA);
    final baseB = extractBase(cleanB);
    if (baseA.isNotEmpty && baseB.isNotEmpty) {
      if (baseA == baseB || baseA.contains(baseB) || baseB.contains(baseA)) {
        return true;
      }
    }

    return cleanA.contains(cleanB) || cleanB.contains(cleanA);
  }

  /// Resolves the valet tariff amount directly from the Admin's site configuration.
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

      for (final site in sites) {
        if (site.name.trim() == target || site.id.trim() == target) {
          return site.baseFee;
        }
      }

      for (final site in sites) {
        if (site.name.trim().toLowerCase() == target.toLowerCase()) {
          return site.baseFee;
        }
      }

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

    // 2. Check current assistant manager's assigned site
    final asstSite = widget.currentAssistantManager?.assignedSite ?? widget.assignedSite;
    if (asstSite != null && asstSite.isNotEmpty && asstSite != 'All Sites') {
      final asstClean = clean(asstSite);
      for (final site in sites) {
        final siteClean = clean(site.name);
        if (site.name.toLowerCase() == asstSite.toLowerCase() ||
            (siteClean.isNotEmpty &&
                (siteClean == asstClean ||
                    siteClean.contains(asstClean) ||
                    asstClean.contains(siteClean)))) {
          return site.baseFee;
        }
      }
    }

    // 3. Check current active site name
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

    return 250.0;
  }

  /// Finds a driver in the staff roster by code/ID (e.g., '108', 'PK-108', 'ST-108').
  StaffModel? _findDriverByCode(String code) {
    final clean = code.trim().toLowerCase().replaceAll('pk-', '').replaceAll('st-', '').replaceAll('-', '');
    for (final d in StaffManager.instance.drivers) {
      final dClean = d.id.toLowerCase().replaceAll('pk-', '').replaceAll('st-', '').replaceAll('-', '');
      if (dClean == clean || d.id.toLowerCase() == code.trim().toLowerCase()) {
        return d;
      }
    }
    return null;
  }

  /// Returns only drivers who belong to the same site as the vehicle / assistant manager.
  List<StaffModel> _getSiteDrivers(String vehicleSite) {
    final targetSite = vehicleSite.isNotEmpty ? vehicleSite : _currentSiteName;
    return StaffManager.instance.drivers
        .where((d) => _isSameSite(d.assignedSite, targetSite))
        .toList();
  }

  void _assignDriverToVehicle(ParkedVehicleItem parked, String driverId) {
    final driver = _findDriverByCode(driverId);
    final targetSite = parked.siteName.isNotEmpty ? parked.siteName : _currentSiteName;
    if (driver != null) {
      if (!_isSameSite(driver.assignedSite, targetSite)) {
        _showToast(
          'Cannot assign: Driver PK-$driverId (${driver.name}) is assigned to ${driver.assignedSite}, not $targetSite.',
          isError: true,
        );
        return;
      }
    }

    final driverName = driver?.name ?? 'Driver $driverId';

    setState(() {
      _selectedDriverByVehicleId[parked.id] = driverId;
      _selectedDriverNameByVehicleId[parked.id] = driverName;
      final idx = _parkedItems.indexWhere((p) => p.id == parked.id);
      if (idx != -1) {
        _parkedItems[idx] = _parkedItems[idx].copyWith(
          assignedDriverId: driverId,
          assignedDriverName: driverName,
        );
      }
    });

    DriverService.instance.updateIntakeStatus(
      parked.id,
      parked.status,
      extraData: {
        'assignedDriverId': driverId,
        'assignedDriverName': driverName,
      },
    );

    _showToast('Assigned Driver PK-$driverId ($driverName) to ${parked.plateNumber}');
  }

  void _handleDispatchRetrieval(ParkedVehicleItem parked) {
    final runnerId = parked.assignedDriverId ?? _selectedDriverByVehicleId[parked.id] ?? '108';
    final runnerName = parked.assignedDriverName ?? _selectedDriverNameByVehicleId[parked.id] ?? runnerId;

    // Check same-site enrollment
    final driver = _findDriverByCode(runnerId);
    if (driver != null) {
      if (!_isSameSite(driver.assignedSite, _currentSiteName)) {
        _showToast(
          'Cannot assign: Driver PK-$runnerId (${driver.name}) is assigned to ${driver.assignedSite}, not $_currentSiteName.',
          isError: true,
        );
        return;
      }
    }

    final runnerLabel = 'PK-$runnerId';
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);

    final newHistory = HistoryDispatchItem(
      id: 'dispatch-${now.millisecondsSinceEpoch}',
      orderNumber: '#RET-${parked.id.replaceAll(RegExp(r'[^0-9]'), '')}',
      vehicleName: parked.vehicleName,
      plateNumber: parked.plateNumber,
      guestName: parked.guestName,
      runnerLabel: '$runnerLabel ($runnerName)',
      timeLabel: timeStr,
      paymentText: parked.paymentText,
      handoverTime: 'Handover in 01:20s',
      isJustDispatched: true,
    );

    setState(() {
      _parkedItems.removeWhere((p) => p.id == parked.id);
      _historyItems.insert(0, newHistory);
      _selectedDriverByVehicleId.remove(parked.id);
      _selectedDriverNameByVehicleId.remove(parked.id);
      _newHistoryBadgeCount++;
    });

    DriverService.instance.updateIntakeStatus(
      parked.id,
      'dispatched',
      extraData: {
        'assignedDriverId': runnerId,
        'assignedDriverName': runnerName,
        'vehicleModel': parked.vehicleName,
        'vehicleReg': parked.plateNumber,
        'customerName': parked.guestName,
        'customerPhone': parked.customerPhone,
        'siteName': parked.siteName,
      },
    );
    _showToast('Runner $runnerLabel dispatched! Moved ${parked.vehicleName} to History.');

    // Auto-transition to history tab smoothly after 900ms
    _dispatchNavTimer?.cancel();
    _dispatchNavTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _activeNavIndex = 1;
          _newHistoryBadgeCount = 0;
        });
      }
    });
  }

  void _handleAssignBayAndPark(ParkedVehicleItem parked) {
    DriverService.instance.updateIntakeStatus(parked.id, 'parked');
    setState(() {
      final idx = _parkedItems.indexWhere((p) => p.id == parked.id);
      if (idx != -1) {
        _parkedItems[idx] = _parkedItems[idx].copyWith(status: 'parked');
      }
    });
    _showToast('Bay assigned & parked: ${parked.plateNumber}');
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FCF5),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main Scrollable Area
            Column(
              children: [
                // Top App Bar
                _buildTopAppBar(),

                // Tab Views
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _activeNavIndex == 0
                        ? _buildRetrievalView()
                        : _buildHistoryView(),
                  ),
                ),

                // Space for docked bottom nav
                const SizedBox(height: 72),
              ],
            ),

            // Toast Floating Banner
            if (_toastMessage != null) _buildToastBanner(),

            // Docked Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP APP BAR & KPI SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildTopAppBar() {
    return Container(
      color: const Color(0xFFF1FCF5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo + Title + Subtitle
              Row(
                children: [
                  const ParkikoLogo(size: 32),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Parkiko',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00513A),
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
                              color: const Color(0xFFDAE5DE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ASST. MGR',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3F4944),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: Color(0xFF00513A),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _currentSiteName,
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
                ],
              ),

              // Status Badge and Logout Action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Supervisor Quick Toggle Status: "Deck Live"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF6EF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFBEC9C2).withAlpha(100),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF059669),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF059669)
                                        .withAlpha((180 * _pulseAnimation.value).toInt()),
                                    blurRadius: 4 * _pulseAnimation.value,
                                    spreadRadius: 1 * _pulseAnimation.value,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Deck Live',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00513A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Logout Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('assistant_manager_logout_button'),
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6).withAlpha(180),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFBA1A1A).withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.logout_rounded,
                              size: 13,
                              color: Color(0xFFBA1A1A),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFBA1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick Metrics Summary Bar (4 columns)
          Row(
            children: [
              // Metric 1: Waiting for Parking / Intakes
              Expanded(
                child: _buildMetricTile(
                  dotColor: _waitingForParkingIntakes.isNotEmpty
                      ? const Color(0xFFD97706)
                      : const Color(0xFF00513A),
                  isDotPulsing: _waitingForParkingIntakes.isNotEmpty,
                  label: 'Waiting',
                  value: _waitingForParkingIntakes.isNotEmpty
                      ? '${_waitingForParkingIntakes.length} Intake'
                      : (_liveIntakes.isNotEmpty
                          ? '${_liveIntakes.where((i) => i.status == 'parked').length} Parked'
                          : '0 Intake'),
                  valueColor: _waitingForParkingIntakes.isNotEmpty
                      ? const Color(0xFF92400E)
                      : const Color(0xFF00513A),
                ),
              ),
              const SizedBox(width: 6),

              // Metric 2: Retrievals
              Expanded(
                child: () {
                  final activeRetrievals = _parkedItems.where((p) => p.isRetrievalRequested).length;
                  return _buildMetricTile(
                    dotColor: activeRetrievals > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF00513A),
                    isDotPulsing: activeRetrievals > 0,
                    label: 'Retrievals',
                    value: '$activeRetrievals Active',
                    valueColor: activeRetrievals > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF00513A),
                  );
                }(),
              ),
              const SizedBox(width: 6),

              // Metric 3: Parked Ready
              Expanded(
                child: _buildMetricTile(
                  dotColor: const Color(0xFF00513A),
                  isDotPulsing: false,
                  label: 'Parked',
                  value: '${_parkedItems.length} Ready',
                  valueColor: const Color(0xFF141E1A),
                ),
              ),
              const SizedBox(width: 6),

              // Metric 4: Runners
              Expanded(
                child: () {
                  final sameSiteDrivers = StaffManager.instance.drivers
                      .where((d) => _isSameSite(d.assignedSite, _currentSiteName))
                      .toList();
                  final onDutyCount = sameSiteDrivers.where((d) => d.isOnDuty).length;
                  return _buildMetricTile(
                    dotColor: onDutyCount > 0 ? const Color(0xFF2D6955) : const Color(0xFF6F7A73),
                    isDotPulsing: false,
                    label: 'Runners',
                    value: '$onDutyCount On-Duty',
                    valueColor: onDutyCount > 0 ? const Color(0xFF00513A) : const Color(0xFF6F7A73),
                  );
                }(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required Color dotColor,
    required bool isDotPulsing,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(100)),
      ),
      child: Row(
        children: [
          if (isDotPulsing)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withAlpha((180 * _pulseAnimation.value).toInt()),
                        blurRadius: 4 * _pulseAnimation.value,
                        spreadRadius: 1 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6F7A73),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: valueColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: PARKED VEHICLES (RETRIEVAL & DISPATCH VIEW)
  // ---------------------------------------------------------------------------

  Widget _buildRetrievalView() {
    // Sort so vehicles with retrieval requested appear FIRST!
    final sortedParkedItems = List<ParkedVehicleItem>.from(_parkedItems);
    sortedParkedItems.sort((a, b) {
      // 1. Retrieval requested vehicles come FIRST
      final aRetrieval = a.isRetrievalRequested;
      final bRetrieval = b.isRetrievalRequested;
      if (aRetrieval && !bRetrieval) return -1;
      if (!aRetrieval && bRetrieval) return 1;

      // 2. Earliest retrieval request first
      if (aRetrieval && bRetrieval) {
        final aTime = a.retrievalRequestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.retrievalRequestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      }

      // 3. Waiting for parking next
      if (a.isWaitingForParking && !b.isWaitingForParking) return -1;
      if (!a.isWaitingForParking && b.isWaitingForParking) return 1;

      return 0;
    });

    final activeRetrievalsCount = sortedParkedItems.where((p) => p.isRetrievalRequested).length;

    if (sortedParkedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(100)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 32,
                  color: Color(0xFF00513A),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deck Clear • No Parked Vehicles',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF141E1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Parked vehicles and customer retrieval requests will appear here in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6F7A73),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('view-retrieval'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Single Unified Listing Header: PARKED VEHICLES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeRetrievalsCount > 0
                          ? const Color(0xFFBA1A1A)
                          : const Color(0xFF00513A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PARKED VEHICLES (${sortedParkedItems.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00513A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeRetrievalsCount > 0
                      ? const Color(0xFFFFDAD6)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeRetrievalsCount > 0
                        ? const Color(0xFFBA1A1A).withAlpha(100)
                        : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Text(
                  activeRetrievalsCount > 0
                      ? '$activeRetrievalsCount Retrieval${activeRetrievalsCount > 1 ? 's' : ''} Active'
                      : '${sortedParkedItems.length} Parked',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: activeRetrievalsCount > 0
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF00513A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedParkedItems.map((item) => _buildParkedCard(item)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PARKED VEHICLE CARD COMPONENT
  // ---------------------------------------------------------------------------

  Widget _buildParkedCard(ParkedVehicleItem parked) {
    final isRetrieval = parked.isRetrievalRequested;
    final isWaiting = parked.isWaitingForParking;

    final targetSite = parked.siteName.isNotEmpty ? parked.siteName : _currentSiteName;
    final siteDrivers = _getSiteDrivers(targetSite);
    final currentAssignedId = parked.assignedDriverId ?? _selectedDriverByVehicleId[parked.id];

    // Elapsed timer calculation for retrieval initiated
    final reqAt = parked.retrievalRequestedAt;
    final elapsedSeconds = reqAt != null
        ? DateTime.now().difference(reqAt).inSeconds
        : 0;
    final elapsedMinutes = elapsedSeconds ~/ 60;
    final elapsedSecRemainder = (elapsedSeconds % 60).toString().padLeft(2, '0');
    final formattedTimer = '$elapsedMinutes:$elapsedSecRemainder';
    final agoText = elapsedMinutes == 0
        ? '${elapsedSeconds}s ago'
        : '${elapsedMinutes}m ago';
    final reqTimeStr = reqAt != null ? DateFormat('hh:mm a').format(reqAt) : '';

    final cardBgColor = isRetrieval
        ? const Color(0xFFFFF1F2)
        : (isWaiting ? const Color(0xFFFFFBEB) : const Color(0xFFFFFDF7));

    final cardBorderColor = isRetrieval
        ? const Color(0xFFFDA4AF)
        : (isWaiting ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: isRetrieval ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: isRetrieval
                ? const Color(0xFFE11D48).withAlpha(16)
                : Colors.black.withAlpha(6),
            blurRadius: isRetrieval ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Status & Retrieval Timer Header
          if (isRetrieval) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDA4AF)),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFBA1A1A),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFBA1A1A)
                                .withAlpha((180 * _pulseAnimation.value).toInt()),
                            blurRadius: 5 * _pulseAnimation.value,
                            spreadRadius: 1.5 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⏱️ RETRIEVAL INITIATED • $formattedTimer elapsed ($agoText)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBA1A1A),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (reqTimeStr.isNotEmpty)
                    Text(
                      reqTimeStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9F1239),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ] else if (isWaiting) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Text(
                    'WAITING FOR BAY ALLOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00513A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'PARKED & SECURED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00513A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Text(
                  parked.parkedAgo,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7A73),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // 2. Vehicle Main Info & Plate
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isRetrieval
                      ? const Color(0xFFFFE4E6)
                      : const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRetrieval
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFF00513A).withAlpha(40),
                  ),
                ),
                child: Icon(
                  parked.isEv ? Icons.electric_car_rounded : Icons.directions_car_rounded,
                  color: isRetrieval ? const Color(0xFFBA1A1A) : const Color(0xFF00513A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            parked.vehicleName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF141E1A),
                            ),
                          ),
                        ),
                        // Payment status chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: parked.isPaid
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: parked.isPaid
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Text(
                            parked.paymentText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: parked.isPaid
                                  ? const Color(0xFF00513A)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Registration Plate Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            parked.plateNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guest: ${parked.guestName}${parked.customerPhone.isNotEmpty ? " • ${parked.customerPhone}" : ""}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6F7A73),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),


          // 4. DRIVER SELECTION BY ID (RESPECTED SITE ONLY - retrieval only)
          if (isRetrieval) ...[
            const SizedBox(height: 10),
            Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBEFDB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_rounded, size: 14, color: Color(0xFF00513A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ASSIGN DRIVER / RUNNER BY ID (${targetSite.toUpperCase()})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00513A),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Text(
                      '${siteDrivers.length} Drivers',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D6955),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (siteDrivers.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'No drivers assigned to "$targetSite" in Staff Directory',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF6F7A73),
                      ),
                    ),
                  ),
                ] else ...[
                  // Dropdown to pick driver by ID
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(140)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: siteDrivers.any((d) => d.id == currentAssignedId)
                            ? currentAssignedId
                            : null,
                        hint: Text(
                          currentAssignedId != null
                              ? 'Selected: ID $currentAssignedId'
                              : 'Select Driver by ID for this site...',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A73)),
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00513A)),
                        items: siteDrivers.map((d) {
                          final isSelected = d.id == currentAssignedId;
                          return DropdownMenuItem<String>(
                            value: d.id,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF00513A) : const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ID: ${d.id}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : const Color(0xFF00513A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${d.name} • ${d.phone}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF141E1A),
                                    ),
                                  ),
                                ),
                                if (d.isOnDuty)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF059669),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _assignDriverToVehicle(parked, val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Quick clickable driver ID chips for rapid assignment
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: siteDrivers.map((d) {
                      final isSelected = d.id == currentAssignedId;
                      return InkWell(
                        onTap: () => _assignDriverToVehicle(parked, d.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00513A) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00513A) : const Color(0xFFBEC9C2).withAlpha(160),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isSelected ? 10 : 4),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.person_outline_rounded,
                                size: 13,
                                color: isSelected ? Colors.white : const Color(0xFF00513A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ID: ${d.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : const Color(0xFF141E1A),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '(${d.name.split(' ').first})',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white70 : const Color(0xFF6F7A73),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          ],

          const SizedBox(height: 12),

          // 5. Context-Aware Action Button
          if (isWaiting) ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                key: Key('btn_assign_bay_${parked.id}'),
                onPressed: () => _handleAssignBayAndPark(parked),
                icon: const Icon(Icons.local_parking_rounded, size: 16),
                label: const Text(
                  'Assign Bay & Park',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00513A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (isRetrieval) ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: currentAssignedId != null
                    ? () => _handleDispatchRetrieval(parked)
                    : () => _showToast('Please select a driver by ID above first', isError: true),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  currentAssignedId != null
                      ? 'Dispatch Runner [ID: $currentAssignedId] to Bay'
                      : 'Select Driver ID Above to Dispatch',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentAssignedId != null
                      ? const Color(0xFF00513A)
                      : const Color(0xFF9E9E9E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 2: HISTORY LOG VIEW
  // ---------------------------------------------------------------------------

  Widget _buildHistoryView() {
    return SingleChildScrollView(
      key: const ValueKey('view-history'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: Color(0xFF00513A),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'DISPATCHED & COMPLETED LOG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF141E1A),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFAFEDD4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_historyItems.length} Dispatches',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00513A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Shift Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF6EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(80)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 14,
                      color: Color(0xFF00513A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Live Shift Audit',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Deck B1 Shift',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141E1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // History Cards List
          if (_historyItems.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(80)),
              ),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.history_rounded, color: Color(0xFF6F7A73), size: 36),
                  SizedBox(height: 8),
                  Text(
                    'No Dispatches Yet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF141E1A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Completed vehicle dispatches will be recorded here.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6F7A73)),
                  ),
                ],
              ),
            )
          else
            ..._historyItems.map((hist) => _buildHistoryCard(hist)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryDispatchItem hist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hist.isJustDispatched
              ? const Color(0xFF00513A).withAlpha(150)
              : const Color(0xFFBEC9C2).withAlpha(120),
          width: hist.isJustDispatched ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Status badge, Order #, Payment, Time ago
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAFEDD4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.done_all,
                          size: 11,
                          color: Color(0xFF00513A),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hist.isJustDispatched ? 'Just Dispatched' : 'Dispatched',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00513A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAE5DE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hist.orderNumber,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check,
                          size: 10,
                          color: Color(0xFF065F46),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hist.paymentText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                hist.timeLabel,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00513A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Vehicle & Plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hist.vehicleName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF141E1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1EA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hist.plateNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141E1A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Guest
          Text(
            'Guest: ${hist.guestName}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6F7A73),
            ),
          ),

          const SizedBox(height: 10),

          // Runner attribution & Handover status
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5F1EA)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: Color(0xFF00513A),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Runner: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6F7A73),
                      ),
                    ),
                    Text(
                      hist.runnerLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: Color(0xFF065F46),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Handover: ${hist.handoverTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOAST BANNER (Dynamic Feedback for Assistant Manager Actions)
  // ---------------------------------------------------------------------------

  Widget _buildToastBanner() {
    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isToastError
                ? const Color(0xFFBA1A1A)
                : const Color(0xFF28332E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isToastError
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                size: 18,
                color: _isToastError ? Colors.white : const Color(0xFFA1F3CF),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _toastMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8F3ED),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DOCKED MINIMAL BOTTOM NAVIGATION
  // ---------------------------------------------------------------------------

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1FCF5).withAlpha(245),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFBEC9C2).withAlpha(80),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEBF6EF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFBEC9C2).withAlpha(80),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              // Tab 1: Retrieval & Dispatch
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _activeNavIndex = 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeNavIndex == 0
                          ? const Color(0xFF00513A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _activeNavIndex == 0
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00513A).withAlpha(40),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 16,
                          color: _activeNavIndex == 0
                              ? Colors.white
                              : const Color(0xFF6F7A73),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Retrieval & Dispatch',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _activeNavIndex == 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _activeNavIndex == 0
                                ? Colors.white
                                : const Color(0xFF3F4944),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab 2: History
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _activeNavIndex = 1;
                      _newHistoryBadgeCount = 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeNavIndex == 1
                          ? const Color(0xFF00513A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _activeNavIndex == 1
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00513A).withAlpha(40),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: _activeNavIndex == 1
                              ? Colors.white
                              : const Color(0xFF6F7A73),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _activeNavIndex == 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _activeNavIndex == 1
                                ? Colors.white
                                : const Color(0xFF3F4944),
                          ),
                        ),
                        if (_newHistoryBadgeCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _activeNavIndex == 1
                                  ? Colors.white
                                  : const Color(0xFF00513A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+$_newHistoryBadgeCount',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: _activeNavIndex == 1
                                    ? const Color(0xFF00513A)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
