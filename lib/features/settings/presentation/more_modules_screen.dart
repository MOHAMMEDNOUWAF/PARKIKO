import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_card.dart';
import '../../sites/presentation/add_site_wizard_screen.dart';

class MoreModulesScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const MoreModulesScreen({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'More Modules & System',
          style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Terminal & Site Operations
          _buildSectionHeader('PROPERTY & SITES'),
          _buildModuleTile(
            context,
            title: 'Add New Site / Property',
            subtitle: '3-Step Setup for decks, tariff cards, and rosters',
            icon: Icons.add_business,
            accentColor: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSiteWizardScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildModuleTile(
            context,
            title: 'Decks & Stall Allocation',
            subtitle: 'Manage capacity, valet ramps, and VIP slots',
            icon: Icons.grid_view,
            accentColor: AppColors.secondaryContainer,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terminal 2 Executive Deck layout loaded')),
              );
            },
          ),
          const SizedBox(height: 20),

          // Section: Analytics & Intelligence
          _buildSectionHeader('ANALYTICS & FLEET'),
          _buildModuleTile(
            context,
            title: 'Reports & Financials Dynamic',
            subtitle: 'Revenue curves, turnaround times, and shift audits',
            icon: Icons.bar_chart,
            accentColor: AppColors.tertiary,
            onTap: () => _showReportsModal(context),
          ),
          const SizedBox(height: 8),
          _buildModuleTile(
            context,
            title: 'Operations Alerts & Notifications',
            subtitle: 'Ramp congestion alerts, key handovers, and VIP arrivals',
            icon: Icons.notifications_active,
            accentColor: AppColors.statusAvailable,
            onTap: () => _showNotificationsModal(context),
          ),
          const SizedBox(height: 20),

          // Section: Security & System
          _buildSectionHeader('SETTINGS & SECURITY'),
          _buildModuleTile(
            context,
            title: 'Terminal Settings & Security',
            subtitle: 'Biometric passkeys, offline sync, and role access',
            icon: Icons.security,
            accentColor: AppColors.statusOccupied,
            onTap: () => _showSettingsModal(context),
          ),
          const SizedBox(height: 8),
          _buildModuleTile(
            context,
            title: 'WhatsApp Bridge Integration',
            subtitle: 'Instant ticket delivery, retrieval triggers via API',
            icon: Icons.send,
            accentColor: AppColors.statusWhatsApp,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('WhatsApp Cloud API Bridge: Status Connected (200 OK)'),
                  backgroundColor: AppColors.statusWhatsApp.withAlpha(200),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Logout Card
          HudCard(
            padding: const EdgeInsets.all(14),
            borderColor: AppColors.statusOccupied.withAlpha(150),
            onTap: () => _showLogoutDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: AppColors.statusOccupied, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SIGN OUT OF TERMINAL',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.statusOccupied,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return HudCard(
      padding: const EdgeInsets.all(14),
      leftAccentColor: accentColor,
      leftAccentWidth: 4,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: AppColors.groundZero,
            child: Icon(icon, size: 22, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHighLuminance,
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
          ),
          const Icon(Icons.chevron_right, color: AppColors.outline, size: 18),
        ],
      ),
    );
  }

  void _showReportsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reports & Financials Dynamic', style: AppTypography.headlineSmall),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            HudCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.borderFocused,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WEEKLY RUN PERFORMANCE', style: AppTypography.labelSmall),
                  const SizedBox(height: 8),
                  Text('1,248 Vehicles Handled', style: AppTypography.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Average Retrieval Time: 3.8 mins (-22%)', style: AppTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 14),
            HudCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PEAK OPERATIONAL HOURS', style: AppTypography.labelSmall),
                  const SizedBox(height: 8),
                  Text('14:00 - 18:30 (Aerocity T2)', style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text('Valet Utilization: 92% • Gate Wait: 2.1 mins', style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fleet Notifications Feed', style: AppTypography.headlineSmall),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),
            _buildNotifItem('Deck A Ramp Busy', 'High queue of 5 vehicles at Main Deck A Valet ramp.', 'Just now', true),
            const SizedBox(height: 10),
            _buildNotifItem('Shift Beta Handover Ready', 'Supervisor John Doe clocked in and signed shift checklist.', '12m ago', false),
            const SizedBox(height: 10),
            _buildNotifItem('EV Bay #2 Cleared', 'Tata Nexon EV completed charging. Slot ready for next vehicle.', '35m ago', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifItem(String title, String desc, String time, bool isUrgent) {
    return HudCard(
      padding: const EdgeInsets.all(12),
      leftAccentColor: isUrgent ? AppColors.statusOccupied : AppColors.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              Text(time, style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
            ],
          ),
          const SizedBox(height: 3),
          Text(desc, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terminal Settings & Security', style: AppTypography.headlineSmall),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Biometric Quick Authentication', style: AppTypography.bodyMedium),
              subtitle: Text('Require Touch ID / Face ID before releasing keys', style: AppTypography.bodySmall),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Offline Local Sync Mode', style: AppTypography.bodyMedium),
              subtitle: Text('Queue vehicle intakes locally during apron network loss', style: AppTypography.bodySmall),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('SMS / WhatsApp Automated Slips', style: AppTypography.bodyMedium),
              subtitle: Text('Instantly dispatch digital parking token to customer', style: AppTypography.bodySmall),
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardModule,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.statusOccupied, width: 1),
        ),
        title: Text('Sign Out of Terminal?', style: AppTypography.titleMedium),
        content: Text(
          'Are you sure you want to sign out of the Parkiko Admin operations terminal?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppTypography.labelMedium.copyWith(color: AppColors.outline)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onLogout();
            },
            child: Text(
              'SIGN OUT',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.statusOccupied,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
