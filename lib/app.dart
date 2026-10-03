import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/parkiko_logo.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/drivers/presentation/driver_intake_screen.dart';
import 'features/managers/assistant manager/assistant_manager_screen.dart';
import 'features/managers/manager/manager.dart';
import 'features/admin/navigation/presentation/main_shell_screen.dart';
import 'features/admin/staff/models/staff_model.dart';

class ParkikoApp extends ConsumerWidget {
  const ParkikoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentUserProfileProvider);

    return MaterialApp(
      title: 'Parkiko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (profile) {
          if (profile != null && profile.isActive) {
            if (profile.isAdmin) {
              return MainShellScreen(
                onLogout: () {
                  ref.read(currentUserProfileProvider.notifier).signOut();
                },
              );
            } else if (profile.isAssistantManager) {
              return AssistantManagerScreen(
                currentAssistantManager: StaffModel(
                  id: profile.userId,
                  name: profile.name,
                  phone: '',
                  role: 'assistant manager',
                  assignedSite: profile.locationIds.isNotEmpty
                      ? profile.locationIds.first
                      : 'Grand Hyatt • Deck B1',
                ),
                assignedSite: profile.locationIds.isNotEmpty
                    ? profile.locationIds.first
                    : 'Grand Hyatt • Deck B1',
                onLogout: () {
                  ref.read(currentUserProfileProvider.notifier).signOut();
                },
                onBack: () {
                  ref.read(currentUserProfileProvider.notifier).signOut();
                },
              );
            } else if (profile.isManager) {
              return ManagerDashboardScreen(
                currentManager: StaffModel(
                  id: profile.userId,
                  name: profile.name,
                  phone: '',
                  role: 'manager',
                  assignedSite: profile.locationIds.isNotEmpty
                      ? profile.locationIds.first
                      : 'Grand Hyatt & Convention',
                ),
                onLogout: () {
                  ref.read(currentUserProfileProvider.notifier).signOut();
                },
              );
            } else if (profile.isDriver) {
              return DriverIntakeScreen(
                driverProfile: profile,
                onLogout: () {
                  ref.read(currentUserProfileProvider.notifier).signOut();
                },
              );
            }
          }
          return LoginScreen(
            onLoginSuccess: () {
              // Riverpod state change automatically triggers rebuild
            },
          );
        },
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ParkikoLogo(size: 64),
                SizedBox(height: 24),
                CircularProgressIndicator(color: AppColors.primary),
              ],
            ),
          ),
        ),
        error: (_, _) => LoginScreen(
          onLoginSuccess: () {},
        ),
      ),
    );
  }
}
