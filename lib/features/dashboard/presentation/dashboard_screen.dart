import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/parkiko_logo.dart';

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
  String _activeTimeRange = 'quarter';
  String _selectedLocation = 'Terminal 2 Executive Deck';
  int _totalSlots = 210;
  int _occupiedSlots = 147;
  String _occupancyRate = '70%';

  // Stitch parkiko1 Performance Overview Data
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
      'revenueTitle': "Today's Revenue",
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
      'revenueTitle': "Month's Revenue",
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
      'revenueTitle': '3M Revenue',
      'revenueBadge': '102% target',
    },
  };

  void _openLocationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withAlpha(150),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Terminal / Deck',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select your active operational location',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
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
            backgroundColor: AppColors.primary,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryContainer.withAlpha(50) : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0x66BEC9C2),
            width: isSelected ? 2 : 1,
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
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.radio_button_unchecked, color: AppColors.outlineVariant, size: 20),
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
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withAlpha(150),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: AppColors.onSecondaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Timeframe: ${_performanceData[_activeTimeRange]!['periodLabel']}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                text: 'View Full Analytics',
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
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withAlpha(150),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics, color: AppColors.onSecondaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detailed Analytics',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Scope: ${_performanceData[_activeTimeRange]!['periodLabel']}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
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
              _buildReportMetric('Customer Satisfaction', '4.9 / 5.0 ⭐', AppColors.onSurface),
              const SizedBox(height: 8),
              _buildReportMetric('Driver Shift Utilization', '91.2%', AppColors.primary),
              const SizedBox(height: 8),
              _buildReportMetric('EV Charging Conversions', '24 bays serviced', AppColors.secondary),
              const SizedBox(height: 16),
              HudButton(
                text: 'Export Executive Report (PDF)',
                icon: Icons.download,
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Executive PDF summary generated & downloaded.'),
                      backgroundColor: AppColors.primary,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
          Text(value, style: AppTypography.bodyMedium.copyWith(color: valueColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _openNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withAlpha(150),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notifications',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Text('3 new', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    child: const Text('Mark read', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                title: 'Deck A Entry High Traffic',
                subtitle: '4 check-ins queued in the last 3 mins',
                time: 'Just now',
                dotColor: AppColors.error,
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
                dotColor: AppColors.secondary,
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
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.onSurface, fontSize: 13)),
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
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withAlpha(150),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'AD',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Admin User',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                'Lead',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.onSecondaryContainer),
                              ),
                            ),
                          ],
                        ),
                        Text('admin@parkiko.com • Shift Alpha', style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.manage_accounts, color: AppColors.primary),
                title: Text('Profile & Security Settings', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
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
                title: Text('Switch Terminal Deck', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openLocationSelector();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bar_chart, color: AppColors.primary),
                title: Text('Operations Summary', style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDetailedReport();
                },
              ),
              const Divider(color: Color(0x33BEC9C2)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text('Log Out of Terminal', style: AppTypography.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
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
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out of Parkiko?', style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        content: Text(
          'Your active shift checklist and operational session on Alpha will be saved.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.outline, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safely signed out of Parkiko Admin Terminal.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMetrics = _performanceData[_activeTimeRange]!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const ParkikoLogo(size: 32),
            const SizedBox(width: 10),
            Text(
              'PARKIKO',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
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
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppColors.surface, width: 1.5),
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
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: InkWell(
              onTap: _openProfileModal,
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x33BEC9C2), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A17211D),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'AD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
              borderRadius: BorderRadius.circular(16),
              child: HudCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Good Morning, Admin',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.apartment, size: 16, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _selectedLocation,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.expand_more, size: 16, color: AppColors.outline),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Active',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Performance Overview Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'PERFORMANCE OVERVIEW', // Keep for test compatibility & Stitch fidelity
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.query_stats, color: AppColors.primary, size: 20),
                  onPressed: _openDetailedReport,
                  tooltip: 'Detailed Analytics',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Segmented Time Range Pills (Today / This Month / Last 3 Months)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33BEC9C2), width: 1),
              ),
              child: Row(
                children: [
                  _buildTimeRangeTab('today', 'Today'),
                  _buildTimeRangeTab('month', 'This Month'),
                  _buildTimeRangeTab('quarter', 'Last 3 Months'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2x2 Interactive Performance Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                // 1. Total Vehicles
                _buildMetricCard(
                  key: 'vehicles',
                  title: 'Total Vehicles',
                  val: currentMetrics['vehicles']!,
                  badge: currentMetrics['vehiclesBadge']!,
                  icon: Icons.directions_car,
                  iconBg: AppColors.surfaceContainerLow,
                  iconColor: AppColors.primary,
                  badgeBg: AppColors.secondaryContainer,
                  badgeFg: AppColors.onSecondaryContainer,
                ),
                // 2. Parked Sessions
                _buildMetricCard(
                  key: 'parked',
                  title: 'Parked Sessions',
                  val: currentMetrics['parked']!,
                  badge: currentMetrics['parkedBadge']!,
                  icon: Icons.local_parking,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF2E7D32),
                  badgeBg: AppColors.surfaceContainer,
                  badgeFg: AppColors.onSurfaceVariant,
                ),
                // 3. Retrieved
                _buildMetricCard(
                  key: 'retrieved',
                  title: 'Retrieved',
                  val: currentMetrics['retrieved']!,
                  badge: currentMetrics['retrievedBadge']!,
                  icon: Icons.key,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFB45309),
                  badgeBg: AppColors.secondaryContainer,
                  badgeFg: AppColors.onSecondaryContainer,
                ),
                // 4. Revenue
                _buildMetricCard(
                  key: 'revenue',
                  title: currentMetrics['revenueTitle']!,
                  val: currentMetrics['revenue']!,
                  badge: currentMetrics['revenueBadge']!,
                  icon: Icons.payments,
                  iconBg: AppColors.surfaceContainerLow,
                  iconColor: AppColors.primary,
                  badgeBg: AppColors.surfaceContainer,
                  badgeFg: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                            'Parking Occupancy',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              'Deck Only',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.onSecondaryContainer),
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
                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),

                  // Linear Progress Bar (Stitch mint-emerald)
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _totalSlots > 0 ? (_occupiedSlots / _totalSlots).clamp(0.0, 1.0) : 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3-Column Slot Summary
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('Total Slots', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text('$_totalSlots', style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: const Color(0x33BEC9C2)),
                        Expanded(
                          child: Column(
                            children: [
                              Text('Occupied', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$_occupiedSlots', style: AppTypography.titleMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Text('🔴', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: const Color(0x33BEC9C2)),
                        Expanded(
                          child: Column(
                            children: [
                              Text('Available', style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${_totalSlots - _occupiedSlots}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Text('🟢', style: TextStyle(fontSize: 10)),
                                ],
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
            const SizedBox(height: 16),

            // Quick Intake CTA
            HudButton(
              text: 'Quick Vehicle Intake',
              icon: Icons.add_circle,
              onPressed: widget.onQuickIntake,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeTab(String key, String label) {
    final isSelected = _activeTimeRange == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTimeRange = key),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0A17211D),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String key,
    required String title,
    required String val,
    required String badge,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color badgeBg,
    required Color badgeFg,
  }) {
    return InkWell(
      onTap: () => _openMetricDetail(key),
      borderRadius: BorderRadius.circular(16),
      child: HudCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeFg,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
