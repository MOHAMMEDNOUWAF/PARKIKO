import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'assistant_manager_stats.dart';

/// Entry point for the Parkiko Valet Ops - Assistant Manager Screen.
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
  });
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

  const AssistantManagerScreen({
    super.key,
    this.onBack,
    this.onLogout,
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

  // Urgent list state
  final List<UrgentRetrievalItem> _urgentItems = [];

  // Parked ready list state
  final List<ParkedVehicleItem> _parkedItems = [];

  // History log state
  final List<HistoryDispatchItem> _historyItems = [];

  // Floating Toast notification state
  String? _toastMessage;
  Timer? _toastTimer;

  // History badge indicator for new dispatches
  int _newHistoryBadgeCount = 0;

  /// Push current list counts to the shared stats singleton so that
  /// LiveOperationsScreen (admin) can read them without coupling.
  void _pushStats() {
    AssistantManagerStats.instance.update(
      parked: _parkedItems.length,
      retrieved: _urgentItems.length,
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

    // Pulse animation controller for urgent cards & ping indicators
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial Urgent items matching HTML
    _urgentItems.addAll([
      UrgentRetrievalItem(
        id: 'urgent-1',
        orderNumber: 'Order #VK-882',
        vehicleName: 'BMW X5 xDrive40i',
        plateNumber: 'MH 01 DX 4022',
        guestName: 'Rajesh Varma',
        sourceTag: 'WhatsApp e-Pass',
        sourceIcon: Icons.chat_bubble_outline_rounded,
        sourceBg: const Color(0xFFD1FAE5),
        sourceTextColor: const Color(0xFF065F46),
        paymentText: 'PAID ₹250 (UPI)',
        isPaid: true,
        timerText: '01:42s',
        runnerStatusText: '5 available now',
        runnerPlaceholder: '108',
        quickChips: const [
          QuickRunnerChipData('108', 'PK-108 (Rohan)'),
          QuickRunnerChipData('082', 'PK-082 (Farhan)'),
        ],
      ),
      UrgentRetrievalItem(
        id: 'urgent-2',
        orderNumber: 'Order #VK-885',
        vehicleName: 'Mercedes GLC 300',
        plateNumber: 'DL 01 AA 7700',
        guestName: 'Dr. Ananya Roy',
        sourceTag: 'Manager Curbside',
        sourceIcon: Icons.person_outline_rounded,
        sourceBg: const Color(0xFFAFEDD4),
        sourceTextColor: const Color(0xFF326D59),
        paymentText: 'UNPAID ₹300 (Collect)',
        isPaid: false,
        timerText: '00:54s',
        runnerStatusText: 'Immediate priority',
        runnerPlaceholder: '091',
        quickChips: const [
          QuickRunnerChipData('091', 'PK-091 (Tariq)'),
          QuickRunnerChipData('108', 'PK-108 (Rohan)'),
        ],
      ),
    ]);

    // Push initial counts (before first setState)
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushStats());

    // Initial Parked items matching HTML
    _parkedItems.addAll([
      const ParkedVehicleItem(
        id: 'parked-1',
        vehicleName: 'Audi A6 TFSI Matrix',
        plateNumber: 'KA 03 MX 9012',
        guestName: 'Priya Sharma',
        parkedBy: 'PK-044',
        parkedAgo: '18m ago',
        slotPosition: 'Deck B1 • Slot #33',
        vaultBox: 'Box #33',
        paymentText: 'PAID ₹250',
        isPaid: true,
        isEv: false,
      ),
      const ParkedVehicleItem(
        id: 'parked-2',
        vehicleName: 'Hyundai Ioniq 5 EV',
        plateNumber: 'MH 02 EV 4410',
        guestName: 'Vikramaditya Roy',
        parkedBy: 'PK-019',
        parkedAgo: '34m ago',
        slotPosition: 'Deck B1 • EV-Slot #12',
        vaultBox: 'Box #12',
        paymentText: 'UNPAID ₹250',
        isPaid: false,
        isEv: true,
      ),
    ]);

    // Initial History log items matching HTML
    _historyItems.addAll([
      const HistoryDispatchItem(
        id: 'hist-1',
        orderNumber: 'Order #VK-879',
        vehicleName: 'Range Rover Velar',
        plateNumber: 'DL 08 CC 1024',
        guestName: 'Aditya Singhal',
        runnerLabel: 'PK-082 (Farhan)',
        timeLabel: '12m ago',
        paymentText: 'PAID ₹250',
        handoverTime: '01:25s',
        isJustDispatched: false,
      ),
      const HistoryDispatchItem(
        id: 'hist-2',
        orderNumber: 'Order #VK-875',
        vehicleName: 'Porsche Macan GTS',
        plateNumber: 'MH 12 QP 5544',
        guestName: 'Meera Singhania',
        runnerLabel: 'PK-108 (Rohan)',
        timeLabel: '28m ago',
        paymentText: 'PAID ₹300',
        handoverTime: '02:05s',
        isJustDispatched: false,
      ),
      const HistoryDispatchItem(
        id: 'hist-3',
        orderNumber: 'Order #VK-871',
        vehicleName: 'Toyota Fortuner Legender',
        plateNumber: 'KA 05 MN 1092',
        guestName: 'Sanjay Reddy',
        runnerLabel: 'PK-044 (Amit)',
        timeLabel: '45m ago',
        paymentText: 'PAID ₹250',
        handoverTime: '01:50s',
        isJustDispatched: false,
      ),
    ]);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _toastTimer?.cancel();
    for (final item in _urgentItems) {
      item.runnerController.dispose();
      item.focusNode.dispose();
    }
    super.dispose();
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

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  void _handleRunnerQuickSet(UrgentRetrievalItem item, String code) {
    setState(() {
      item.runnerController.text = code;
      item.runnerController.selection = TextSelection.fromPosition(
        TextPosition(offset: code.length),
      );
    });
  }

  void _clearRunnerInput(UrgentRetrievalItem item) {
    setState(() {
      item.runnerController.clear();
    });
    item.focusNode.requestFocus();
  }

  void _triggerDispatch(UrgentRetrievalItem item) {
    final rawRunner = item.runnerController.text.trim();
    final runnerCode = rawRunner.isNotEmpty ? rawRunner : '108';
    final runnerLabel = 'PK-$runnerCode';

    // Format current time
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    final newHistory = HistoryDispatchItem(
      id: 'dispatch-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: item.orderNumber,
      vehicleName: item.vehicleName,
      plateNumber: item.plateNumber,
      guestName: item.guestName,
      runnerLabel: runnerLabel,
      timeLabel: timeStr,
      paymentText: item.paymentText,
      handoverTime: 'Moving to Bay',
      isJustDispatched: true,
    );

    setState(() {
      _urgentItems.removeWhere((u) => u.id == item.id);
      _historyItems.insert(0, newHistory);
      _newHistoryBadgeCount++;
    });

    _showToast('Runner $runnerLabel dispatched! Moved ${item.vehicleName} to History.');

    // Auto-transition to history tab smoothly after 900ms
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _activeNavIndex = 1;
          _newHistoryBadgeCount = 0;
        });
      }
    });
  }

  void _triggerCustomerRetrieval(ParkedVehicleItem parked) {
    _showToast('Retrieval requested! Adding ${parked.vehicleName} to Urgent queue');

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final newItem = UrgentRetrievalItem(
        id: 'urgent-${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: 'Order #VK-890',
        vehicleName: parked.vehicleName,
        plateNumber: parked.plateNumber,
        guestName: 'Fast Track Guest',
        sourceTag: 'Bay Call',
        sourceIcon: Icons.notifications_active_outlined,
        sourceBg: const Color(0xFFD1FAE5),
        sourceTextColor: const Color(0xFF065F46),
        paymentText: 'PAID ₹250',
        isPaid: true,
        timerText: '00:15s',
        runnerStatusText: 'Ready for dispatch',
        isAutoRunner: true,
      );

      setState(() {
        _urgentItems.add(newItem);
      });
    });
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00513A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_parking_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
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
                        children: const [
                          Icon(
                            Icons.location_on,
                            size: 13,
                            color: Color(0xFF00513A),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Grand Hyatt • Deck B1',
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

          // Quick Metrics Summary Bar (3 columns)
          Row(
            children: [
              // Metric 1: Retrievals
              Expanded(
                child: _buildMetricTile(
                  dotColor: const Color(0xFFBA1A1A),
                  isDotPulsing: true,
                  label: 'Retrievals',
                  value: '${_urgentItems.length} Urgent',
                  valueColor: const Color(0xFFBA1A1A),
                ),
              ),
              const SizedBox(width: 8),

              // Metric 2: Parked Ready
              Expanded(
                child: _buildMetricTile(
                  dotColor: const Color(0xFFF59E0B),
                  isDotPulsing: false,
                  label: 'Parked',
                  value: '${_parkedItems.length + 12} Ready',
                  valueColor: const Color(0xFF141E1A),
                ),
              ),
              const SizedBox(width: 8),

              // Metric 3: Runners
              Expanded(
                child: _buildMetricTile(
                  dotColor: const Color(0xFF00513A),
                  isDotPulsing: false,
                  label: 'Runners',
                  value: '5 Idle',
                  valueColor: const Color(0xFF00513A),
                ),
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
  // TAB 1: RETRIEVAL & DISPATCH VIEW
  // ---------------------------------------------------------------------------

  Widget _buildRetrievalView() {
    return SingleChildScrollView(
      key: const ValueKey('view-retrieval'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Urgent Retrievals (Pulsing Red Alert)
          _buildUrgentSection(),

          const SizedBox(height: 16),

          // Section 2: Parked by Driver (Ready - Amber State)
          _buildParkedSection(),
        ],
      ),
    );
  }

  // --- SECTION 1: URGENT RETRIEVALS ---
  Widget _buildUrgentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFBA1A1A),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFBA1A1A)
                                .withAlpha((200 * _pulseAnimation.value).toInt()),
                            blurRadius: 5 * _pulseAnimation.value,
                            spreadRadius: 1 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'URGENT RETRIEVALS (${_urgentItems.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFBA1A1A),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const Text(
              'Avg wait: 02:10s',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6F7A73),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_urgentItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(80)),
            ),
            alignment: Alignment.center,
            child: Column(
              children: const [
                Icon(Icons.check_circle_outline, color: Color(0xFF00513A), size: 36),
                SizedBox(height: 8),
                Text(
                  'All Urgent Retrievals Dispatched!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141E1A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No pending customer queues at curbside right now.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6F7A73)),
                ),
              ],
            ),
          )
        else
          ..._urgentItems.map((item) => _buildUrgentCard(item)),
      ],
    );
  }

  Widget _buildUrgentCard(UrgentRetrievalItem item) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final glowAlpha = (30 + 35 * _pulseAnimation.value).toInt();
        final borderAlpha = (100 + 155 * _pulseAnimation.value).toInt();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.white,
              const Color(0xFFFFF9F9),
              _pulseAnimation.value,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFBA1A1A).withAlpha(borderAlpha),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBA1A1A).withAlpha(glowAlpha),
                blurRadius: 10 * _pulseAnimation.value,
                spreadRadius: 1 * _pulseAnimation.value,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Source Badge, Order #, Payment Badge, Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Source badge (WhatsApp / Curbside / Bay Call)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.sourceBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.sourceIcon, size: 12, color: item.sourceTextColor),
                          const SizedBox(width: 4),
                          Text(
                            item.sourceTag,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: item.sourceTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Order Number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.orderNumber,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                          color: Color(0xFF93000A),
                        ),
                      ),
                    ),

                    // Payment Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.isPaid
                            ? const Color(0xFFAFEDD4)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: item.isPaid
                            ? null
                            : Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isPaid
                                ? Icons.check_circle_rounded
                                : Icons.pending_outlined,
                            size: 11,
                            color: item.isPaid
                                ? const Color(0xFF00513A)
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.paymentText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: item.isPaid
                                  ? const Color(0xFF00513A)
                                  : const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Timer Pill
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFBA1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      item.timerText,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Vehicle Name & License Plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  item.vehicleName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF141E1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1EA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.plateNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141E1A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Guest Name
          Row(
            children: [
              const Text(
                'Guest: ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6F7A73),
                ),
              ),
              Text(
                item.guestName,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141E1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Assign Runner Module
          if (item.isAutoRunner)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assign Runner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141E1A),
                      ),
                    ),
                    Text(
                      item.runnerStatusText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      item.runnerController.text = '108';
                      _triggerDispatch(item);
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text(
                      'Dispatch Auto-Runner PK-108',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00513A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assign Runner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141E1A),
                      ),
                    ),
                    Text(
                      item.runnerStatusText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Fixed Prefix Input Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBEC9C2).withAlpha(120),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Fixed 'PK-' Prefix Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5F1EA),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(11),
                          ),
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFFBEC9C2),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: const Text(
                          'PK-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3F4944),
                          ),
                        ),
                      ),

                      // Numeric TextField
                      Expanded(
                        child: TextField(
                          controller: item.runnerController,
                          focusNode: item.focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (val) {
                            setState(() {});
                          },
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF141E1A),
                          ),
                          decoration: InputDecoration(
                            hintText: item.runnerPlaceholder,
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBEC9C2),
                            ),
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),

                      // Clear button (X) when input is non-empty
                      if (item.runnerController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: const Color(0xFF6F7A73),
                          onPressed: () => _clearRunnerInput(item),
                        ),
                    ],
                  ),
                ),

                if (item.quickChips.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Quick:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6F7A73),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...item.quickChips.map((chip) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildQuickRunnerChip(item, chip.code, chip.label),
                          )),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                // Dispatch Action Button
                _buildDispatchButton(item),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickRunnerChip(
    UrgentRetrievalItem item,
    String code,
    String label,
  ) {
    final isSelected = item.runnerController.text.trim() == code;

    return InkWell(
      onTap: () => _handleRunnerQuickSet(item, code),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFAFEDD4)
              : const Color(0xFFDFEBE4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF00513A)
                : const Color(0xFF141E1A),
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchButton(UrgentRetrievalItem item) {
    final runnerText = item.runnerController.text.trim();
    final bool isEnabled = runnerText.isNotEmpty;

    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: isEnabled ? () => _triggerDispatch(item) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? const Color(0xFF00513A)
              : const Color(0xFFE5F1EA),
          foregroundColor: isEnabled ? Colors.white : const Color(0xFF6F7A73),
          disabledBackgroundColor: const Color(0xFFE5F1EA),
          disabledForegroundColor: const Color(0xFF6F7A73),
          elevation: isEnabled ? 1 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_rounded,
              size: 16,
              color: isEnabled ? Colors.white : const Color(0xFF6F7A73),
            ),
            const SizedBox(width: 6),
            Text(
              isEnabled
                  ? 'Dispatch Runner PK-$runnerText'
                  : 'Enter Runner to Dispatch',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.white : const Color(0xFF6F7A73),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION 2: PARKED BY DRIVER (READY - AMBER STATE) ---
  Widget _buildParkedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PARKED BY DRIVER (READY)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF78350F),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '14 Total Bayed',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Parked Cards List
        ..._parkedItems.map((parked) => _buildParkedCard(parked)),
      ],
    );
  }

  Widget _buildParkedCard(ParkedVehicleItem parked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A).withAlpha(220)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Badges & Parked By Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // PARKED READY
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle_outline,
                          size: 12,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PARKED READY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // EV Charging (Optional)
                  if (parked.isEv)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.bolt,
                            size: 11,
                            color: Color(0xFF065F46),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'EV Charging',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Payment Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: parked.isPaid
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: parked.isPaid
                          ? null
                          : Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          parked.isPaid ? Icons.check : Icons.schedule,
                          size: 11,
                          color: parked.isPaid
                              ? const Color(0xFF065F46)
                              : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          parked.paymentText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: parked.isPaid
                                ? const Color(0xFF065F46)
                                : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Parked by PK-xxx (time)
              Text(
                'By ${parked.parkedBy} (${parked.parkedAgo})',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78350F),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Vehicle Name & Plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFFDE68A).withAlpha(160),
                  ),
                ),
                child: Text(
                  parked.plateNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF451A03),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Guest Name
          Text(
            'Guest: ${parked.guestName}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6F7A73),
            ),
          ),

          const SizedBox(height: 10),

          // Bay Placement & Safe Meta Grid (2 columns)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB).withAlpha(180),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEF3C7)),
            ),
            child: Row(
              children: [
                // Column 1: Slot Position
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          parked.isEv
                              ? Icons.electric_car_rounded
                              : Icons.local_parking_rounded,
                          size: 15,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Slot Position',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              parked.slotPosition,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF451A03),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFFDE68A),
                ),
                const SizedBox(width: 8),

                // Column 2: Vault Key Safe
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vault Key Safe',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              parked.vaultBox,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF451A03),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Trigger Retrieval Action Button
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _triggerCustomerRetrieval(parked),
              icon: const Icon(Icons.output_rounded, size: 16),
              label: const Text(
                'Trigger Retrieval',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF3C7),
                foregroundColor: const Color(0xFF78350F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
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
            color: const Color(0xFF28332E),
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
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Color(0xFFA1F3CF),
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
