import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/hud_bottom_nav.dart';
import '../../home/presentation/home_screen.dart';
import '../../operations/presentation/live_operations_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          HomeScreen(
            onNavigateToOps: () => setState(() => _currentTabIndex = 1),
            onNavigateToMore: () => setState(() => _currentTabIndex = 4),
            onLogout: widget.onLogout,
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
