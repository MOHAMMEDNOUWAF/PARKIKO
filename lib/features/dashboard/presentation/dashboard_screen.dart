import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_chip.dart';
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

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(valetTicketsProvider);
    final parkedCount = tickets.where((t) => t.status == OperationalStatus.occupied).length;
    final retrievedCount = tickets.where((t) => t.status == OperationalStatus.available).length;
    final totalRevenue = tickets.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.borderFocused, width: 1),
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: AppColors.textHighLuminance,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
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
          // Notifications with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deck A Entry High Traffic • 4 check-ins queued'),
                      backgroundColor: AppColors.cardModule,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Terminal Banner
            HudCard(
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
                            'Terminal 2 Executive Deck',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const HudStatusChip(label: 'ACTIVE', status: OperationalStatus.available),
                ],
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
                  ],
                ),
                // Range pills
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
                      _buildTimePill('shift', 'SHIFT'),
                      _buildTimePill('week', 'WEEK'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2x2 Metric Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'VALETS ON DUTY',
                    value: '18',
                    subtext: '2 Supervisors active',
                    icon: Icons.group,
                    accentColor: AppColors.secondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'SLOTS OCCUPIED',
                    value: '$parkedCount / 50',
                    subtext: '${((parkedCount / 50) * 100).toInt()}% Capacity',
                    icon: Icons.local_parking,
                    accentColor: AppColors.statusOccupied,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "TODAY'S REVENUE",
                    value: '₹${totalRevenue.toInt()}',
                    subtext: 'UPI: 78% • Cash: 22%',
                    icon: Icons.currency_rupee,
                    accentColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'AVG RETRIEVAL',
                    value: '4.2m',
                    subtext: '-18% vs SLA Target',
                    icon: Icons.timer_outlined,
                    accentColor: AppColors.statusAvailable,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
