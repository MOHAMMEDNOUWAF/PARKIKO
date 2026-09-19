import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_chip.dart';
import '../../../core/widgets/parkiko_logo.dart';
import '../../operations/providers/operations_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToOps;
  final VoidCallback onQuickIntake;

  const DashboardScreen({
    super.key,
    required this.onNavigateToOps,
    required this.onQuickIntake,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _activeTimeRange = 'today';
  String _selectedLocation = 'Terminal 2 Executive Deck';
  int _totalSlots = 210;
  int _occupiedSlots = 147;
  String _occupancyRate = '70%';

  // Stitch parkiko1 Performance Data
  static const Map<String, Map<String, String>> _performanceData = {
    'today': {
      'periodLabel': 'Today',
      'vehicles': '88',
      'vehiclesBadge': '+12% vs yesterday',
      'parked': '54',
      'parkedBadge': 'Live 61% util',
      'retrieved': '34',
      'retrievedBadge': '99.8% on-time',
      'revenue': '₹42,500',
      'revenueTitle': "TODAY'S REVENUE",
      'revenueBadge': '88% target',
    },
    'month': {
      'periodLabel': 'This Month',
      'vehicles': '2,410',
      'vehiclesBadge': '+8.4% MoM',
      'parked': '1,530',
      'parkedBadge': '74% avg util',
      'retrieved': '880',
      'retrievedBadge': '99.2% on-time',
      'revenue': '₹11,84,200',
      'revenueTitle': "MONTH'S REVENUE",
      'revenueBadge': '94% target',
    },
    'quarter': {
      'periodLabel': 'Last 3 Months',
      'vehicles': '7,850',
      'vehiclesBadge': '+15.2% QoQ',
      'parked': '4,920',
      'parkedBadge': '78% util',
      'retrieved': '2,930',
      'retrievedBadge': '99.5% on-time',
      'revenue': '₹38,45,000',
      'revenueTitle': '3M REVENUE',
      'revenueBadge': '102% target',
    },
  };

  void _openLocationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.hudOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.borderFocused, width: 2),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Terminal / Deck',
                        style: AppTypography.headlineSmall.copyWith(color: AppColors.textHighLuminance),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select your active operational location',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLocationOption(
                name: 'Terminal 2 Executive Deck',
                subtitle: 'Shift Alpha • 210 slots • Premium Valet',
                slots: 210,
                occupied: 147,
                rate: '70%',
                icon: Icons.flight_takeoff,
              ),
              const SizedBox(height: 10),
              _buildLocationOption(
                name: 'Deck A - Valet Ground Deck',
                subtitle: 'Shift Alpha • 120 slots • Express Lane',
                slots: 120,
                occupied: 96,
                rate: '80%',
                icon: Icons.apartment,
              ),
              const SizedBox(height: 10),
              _buildLocationOption(
                name: 'Deck B - Short-stay & Guest',
                subtitle: 'Shift Alpha • 60 slots • Standard Guest',
                slots: 60,
                occupied: 36,
                rate: '60%',
                icon: Icons.store,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationOption({
    required String name,
    required String subtitle,
    required int slots,
    required int occupied,
    required String rate,
    required IconData icon,
  }) {
    final isSelected = _selectedLocation == name;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocation = name;
          _totalSlots = slots;
          _occupiedSlots = occupied;
          _occupancyRate = rate;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to $name ($rate capacity)'),
            backgroundColor: AppColors.cardModule,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withAlpha(80) : AppColors.groundZero,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? AppColors.primary : AppColors.outline, size: 22),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleMedium.copyWith(
                        color: isSelected ? AppColors.textHighLuminance : AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.radio_button_unchecked, color: AppColors.outline, size: 20),
          ],
        ),
      ),
    );
  }

  void _openMetricDetail(String metricKey) {
    String title = '';
    IconData icon = Icons.analytics;
    List<Map<String, String>> details = [];

    switch (metricKey) {
      case 'vehicles':
        title = 'Total Vehicles Scanned';
        icon = Icons.directions_car;
        details = [
          {'label': 'Deck A Main Drive-in', 'val': '52 vehicles (59%)'},
          {'label': 'Deck B Express Ramp', 'val': '36 vehicles (41%)'},
          {'label': 'VIP / Pre-booked Bays', 'val': '14 arrivals'},
          {'label': 'Peak Inflow Rate', 'val': '18 cars/hour (10:30 AM)'},
        ];
        break;
      case 'parked':
        title = 'Active Parked Sessions';
        icon = Icons.local_parking;
        details = [
          {'label': 'Deck A Regular Slots', 'val': '32 of 40 active'},
          {'label': 'Deck B Regular Slots', 'val': '16 of 40 active'},
          {'label': 'EV Bay Charging Slots', 'val': '6 bays occupied'},
          {'label': 'Average Dwell Time', 'val': '3.4 hours'},
        ];
        break;
      case 'retrieved':
        title = 'Retrieved & Handed Over';
        icon = Icons.key;
        details = [
          {'label': 'Direct Valet Curbside', 'val': '28 cars delivered'},
          {'label': 'Self-retrieval Express', 'val': '6 vehicles'},
          {'label': 'Avg Delivery Latency', 'val': '3m 42s'},
          {'label': 'Late Dispatch Claims', 'val': '0 reported (100%)'},
        ];
        break;
      case 'revenue':
        title = 'Valet Revenue Breakdown';
        icon = Icons.payments;
        details = [
          {'label': 'UPI & Digital Wallets', 'val': '₹31,200 (73.4%)'},
          {'label': 'Corporate Hotel Charge', 'val': '₹8,400 (19.8%)'},
          {'label': 'Cash Collections', 'val': '₹2,900 (6.8%)'},
          {'label': 'EV Power Surcharge', 'val': '₹1,850 included'},
        ];
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.hudOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.borderFocused, width: 2),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.groundZero,
                        child: Icon(icon, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance),
                          ),
                          Text(
                            'Timeframe: ${_performanceData[_activeTimeRange]!['periodLabel']}',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final item in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: AppColors.groundZero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['label']!, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                        Text(item['val']!, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              HudButton(
                text: 'VIEW FULL ANALYTICS',
                icon: Icons.bar_chart,
                onPressed: () {
                  Navigator.pop(ctx);
                  _openDetailedReport();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDetailedReport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.hudOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.secondaryContainer, width: 2),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.groundZero,
                        child: const Icon(Icons.analytics, color: AppColors.secondaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detailed Analytics',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance),
                          ),
                          Text(
                            'Scope: ${_performanceData[_activeTimeRange]!['periodLabel']}',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildReportMetric('Peak Turnaround Speed', '3.8 mins (Top 5%)', AppColors.primary),
              const SizedBox(height: 8),
              _buildReportMetric('Customer Satisfaction', '4.9 / 5.0 ⭐', AppColors.textHighLuminance),
              const SizedBox(height: 8),
              _buildReportMetric('Driver Shift Utilization', '91.2%', AppColors.primary),
              const SizedBox(height: 8),
              _buildReportMetric('EV Charging Conversions', '24 bays serviced', AppColors.secondaryContainer),
              const SizedBox(height: 16),
              HudButton(
                text: 'EXPORT EXECUTIVE REPORT (PDF)',
                icon: Icons.download,
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Executive PDF summary generated & downloaded.'),
                      backgroundColor: AppColors.cardModule,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportMetric(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.groundZero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
          Text(value, style: AppTypography.titleMedium.copyWith(color: valueColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _openNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.hudOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.borderFocused, width: 2),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Operations Notifications',
                        style: TextStyle(color: AppColors.textHighLuminance, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: AppColors.statusOccupied,
                        child: const Text('3 NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All notifications marked as read.')),
                      );
                    },
                    child: const Text('Mark read', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                title: 'Deck A Entry High Traffic',
                subtitle: '4 check-ins queued in the last 3 mins',
                time: 'Just now',
                dotColor: AppColors.statusOccupied,
              ),
              const SizedBox(height: 8),
              _buildNotificationItem(
                title: 'Shift Beta Handover Ready',
                subtitle: 'Supervisor John Doe clocked in',
                time: '12m ago',
                dotColor: AppColors.primary,
              ),
              const SizedBox(height: 8),
              _buildNotificationItem(
                title: 'EV Bay #2 Completed',
                subtitle: 'Session charged to ₹450 (UPI)',
                time: '35m ago',
                dotColor: AppColors.secondaryContainer,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String subtitle,
    required String time,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.groundZero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            color: dotColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(time, style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openProfileModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.hudOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.borderFocused, width: 2),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    color: AppColors.primaryContainer,
                    child: Center(
                      child: Text(
                        'AD',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Admin User', style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.secondaryContainer.withAlpha(40),
                            child: Text('Lead', style: AppTypography.labelSmall.copyWith(color: AppColors.secondaryContainer)),
                          ),
                        ],
                      ),
                      Text('admin@parkiko.com • Shift Alpha (07:00 - 15:30)', style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.manage_accounts, color: AppColors.primary),
                title: Text('Profile & Security Settings', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHighLuminance)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile preferences opened.')),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz, color: AppColors.primary),
                title: Text('Switch Terminal Deck', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHighLuminance)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openLocationSelector();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bar_chart, color: AppColors.primary),
                title: Text('Operations Summary', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHighLuminance)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDetailedReport();
                },
              ),
              const Divider(color: AppColors.borderSubtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppColors.statusOccupied),
                title: Text('Log Out of Terminal', style: AppTypography.bodyMedium.copyWith(color: AppColors.statusOccupied, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmLogout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.hudOverlay,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('Sign Out of Parkiko?', style: AppTypography.titleMedium.copyWith(color: AppColors.textHighLuminance)),
        content: Text(
          'Your active shift checklist and operational session on Alpha will be saved.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusOccupied,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safely signed out of Parkiko Admin Terminal.'),
                  backgroundColor: AppColors.cardModule,
                ),
              );
            },
            child: const Text('SIGN OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(valetTicketsProvider);
    final retrievedCount = tickets.where((t) => t.status == OperationalStatus.available).length;
    final currentMetrics = _performanceData[_activeTimeRange]!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const ParkikoLogo(size: 28),
            const SizedBox(width: 10),
            Text(
              'PARKIKO',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          // Notifications button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                onPressed: _openNotificationsModal,
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.statusOccupied,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Admin Avatar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _openProfileModal,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppColors.borderFocused, width: 1),
                ),
                child: Center(
                  child: Text(
                    'AD',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHighLuminance,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Interactive Deck Location Banner
            InkWell(
              onTap: _openLocationSelector,
              child: HudCard(
                padding: const EdgeInsets.all(16),
                borderColor: AppColors.borderFocused.withAlpha(120),
                leftAccentColor: AppColors.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning, Admin 👋',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.textHighLuminance,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.apartment, size: 15, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              _selectedLocation,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_more, size: 14, color: AppColors.outline),
                          ],
                        ),
                      ],
                    ),
                    const HudStatusChip(label: 'ACTIVE', status: OperationalStatus.available),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Intake Command Button
            HudButton(
              text: '+ QUICK INTAKE / DISPATCH VEHICLE',
              icon: Icons.add_circle_outline,
              onPressed: widget.onQuickIntake,
            ),
            const SizedBox(height: 20),

            // Performance Overview Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'PERFORMANCE OVERVIEW',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textHighLuminance,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 6, height: 6, color: AppColors.primary),
                    IconButton(
                      icon: const Icon(Icons.query_stats, size: 18, color: AppColors.primary),
                      onPressed: _openDetailedReport,
                      tooltip: 'View Detailed Analytics',
                    ),
                  ],
                ),
                // Time Range Segmented Pills (Today / This Month / Last 3 Months)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.groundZero,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                  child: Row(
                    children: [
                      _buildTimePill('today', 'TODAY'),
                      _buildTimePill('month', 'MONTH'),
                      _buildTimePill('quarter', '3M'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2x2 Metric Grid from Stitch parkiko1 (Tappable for Drilldown)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openMetricDetail('vehicles'),
                    child: _buildMetricCard(
                      title: 'TOTAL VEHICLES',
                      value: currentMetrics['vehicles']!,
                      subtext: currentMetrics['vehiclesBadge']!,
                      icon: Icons.directions_car,
                      accentColor: AppColors.secondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _openMetricDetail('parked'),
                    child: _buildMetricCard(
                      title: 'PARKED SESSIONS',
                      value: currentMetrics['parked']!,
                      subtext: currentMetrics['parkedBadge']!,
                      icon: Icons.local_parking,
                      accentColor: AppColors.statusOccupied,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openMetricDetail('retrieved'),
                    child: _buildMetricCard(
                      title: 'RETRIEVED',
                      value: currentMetrics['retrieved']!,
                      subtext: currentMetrics['retrievedBadge']!,
                      icon: Icons.key,
                      accentColor: AppColors.statusAvailable,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _openMetricDetail('revenue'),
                    child: _buildMetricCard(
                      title: currentMetrics['revenueTitle']!,
                      value: currentMetrics['revenue']!,
                      subtext: currentMetrics['revenueBadge']!,
                      icon: Icons.currency_rupee,
                      accentColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Parking Capacity / Occupancy Section
            HudCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'PARKING OCCUPANCY',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textHighLuminance,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.secondaryContainer.withAlpha(40),
                            child: Text(
                              'Deck Only',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.secondaryContainer, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _occupancyRate,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selected Deck: $_selectedLocation',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar
                  LinearProgressIndicator(
                    value: _occupiedSlots / _totalSlots,
                    backgroundColor: AppColors.surfaceContainer,
                    color: AppColors.primary,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  // Slot Breakdown Grid
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.groundZero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildOccupancySlotCol('TOTAL SLOTS', '$_totalSlots', AppColors.textHighLuminance),
                        Container(width: 1, height: 24, color: AppColors.borderSubtle),
                        _buildOccupancySlotCol('OCCUPIED', '$_occupiedSlots 🔴', AppColors.statusOccupied),
                        Container(width: 1, height: 24, color: AppColors.borderSubtle),
                        _buildOccupancySlotCol('AVAILABLE', '${_totalSlots - _occupiedSlots} 🟢', AppColors.statusAvailable),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Operations Header & Shortcut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'LIVE APRON QUEUE',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textHighLuminance,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    HudStatusChip(
                      label: '$retrievedCount READY AT PORCH',
                      status: OperationalStatus.available,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.onNavigateToOps,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Row(
                    children: [
                      Text(
                        'VIEW ALL',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.secondaryContainer),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Active Queue Preview List
            for (final ticket in tickets.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HudCard(
                  padding: const EdgeInsets.all(14),
                  leftAccentColor: ticket.status == OperationalStatus.available
                      ? AppColors.statusAvailable
                      : ticket.status == OperationalStatus.occupied
                          ? AppColors.statusOccupied
                          : AppColors.secondaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                color: AppColors.surfaceContainerHigh,
                                child: Text(
                                  ticket.licensePlate,
                                  style: AppTypography.licensePlate.copyWith(
                                    color: AppColors.textHighLuminance,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ticket.ticketNumber,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          HudStatusChip(
                            label: ticket.statusText,
                            status: ticket.status,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ticket.carModel,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textHighLuminance,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                ticket.locationSlot,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

  Widget _buildOccupancySlotCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildTimePill(String key, String label) {
    final isSelected = _activeTimeRange == key;
    return InkWell(
      onTap: () => setState(() => _activeTimeRange = key),
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.textHighLuminance : AppColors.outline,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
    return HudCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: AppColors.groundZero,
      borderColor: AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              Icon(icon, size: 15, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textHighLuminance,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: AppTypography.labelSmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
