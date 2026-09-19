import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_bottom_nav.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_chip.dart';
import '../../../core/widgets/hud_text_field.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../operations/models/valet_ticket.dart';
import '../../operations/presentation/live_operations_screen.dart';
import '../../operations/providers/operations_provider.dart';
import '../../payments/presentation/payments_screen.dart';
import '../../settings/presentation/more_modules_screen.dart';
import '../../staff/presentation/staff_management_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;

  const MainShellScreen({
    super.key,
    required this.onLogout,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentTabIndex = 0;

  void _openQuickIntakeModal() {
    final plateController = TextEditingController();
    final modelController = TextEditingController(text: 'Honda City');
    final customerController = TextEditingController();
    final phoneController = TextEditingController();
    final slotController = TextEditingController(text: 'Deck A (Slot #A-19)');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                        child: const Icon(Icons.add_circle, color: AppColors.onSecondaryContainer, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Quick Vehicle Intake',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.outline),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HudTextField(
                label: 'Vehicle License Plate',
                controller: plateController,
                placeholder: 'e.g. MH-01-DE-4411',
                hasScannerButton: true,
                onScanPressed: () {
                  plateController.text = 'MH-04-KB-5500';
                },
              ),
              const SizedBox(height: 12),
              HudTextField(
                label: 'Car Model & Color',
                controller: modelController,
                placeholder: 'e.g. BMW 330i (Alpine White)',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: HudTextField(
                      label: 'Customer Name',
                      controller: customerController,
                      placeholder: 'Name',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HudTextField(
                      label: 'Customer Phone',
                      controller: phoneController,
                      placeholder: '+91 98XXX',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              HudTextField(
                label: 'Assigned Parking Bay',
                controller: slotController,
              ),
              const SizedBox(height: 20),
              HudButton(
                text: 'Dispatch & Generate Ticket',
                icon: Icons.check,
                onPressed: () {
                  if (plateController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter vehicle license plate')),
                    );
                    return;
                  }
                  final newTicket = ValetTicket(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    ticketNumber: '#VP-${1083 + (DateTime.now().second % 100)}',
                    licensePlate: plateController.text.trim().toUpperCase(),
                    carModel: modelController.text.trim(),
                    color: 'Default',
                    customerName: customerController.text.trim().isEmpty ? 'Guest Customer' : customerController.text.trim(),
                    customerPhone: phoneController.text.trim().isEmpty ? '+91 98000 00000' : phoneController.text.trim(),
                    siteName: 'Terminal 2 Executive Deck',
                    siteShort: 'Executive T2',
                    locationSlot: slotController.text.trim(),
                    staffName: 'Arjun S.',
                    staffId: '#STF-104',
                    staffRole: 'T2 Lead Valet',
                    status: OperationalStatus.occupied,
                    statusText: 'PARKED',
                    checkInTime: DateTime.now(),
                    amount: 200,
                  );
                  ref.read(valetTicketsProvider.notifier).addTicket(newTicket);
                  Navigator.pop(ctx);
                  setState(() => _currentTabIndex = 1); // Jump to Live Ops
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle ${newTicket.licensePlate} parked at ${newTicket.locationSlot}!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          DashboardScreen(
            onNavigateToOps: () => setState(() => _currentTabIndex = 1),
            onQuickIntake: _openQuickIntakeModal,
          ),
          const LiveOperationsScreen(),
          const StaffManagementScreen(),
          const PaymentsScreen(),
          MoreModulesScreen(onLogout: widget.onLogout),
        ],
      ),
      bottomNavigationBar: HudBottomNav(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
      ),
    );
  }
}
