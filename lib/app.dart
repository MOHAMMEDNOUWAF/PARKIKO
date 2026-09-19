import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/navigation/presentation/main_shell_screen.dart';

class ParkikoApp extends StatefulWidget {
  const ParkikoApp({super.key});

  @override
  State<ParkikoApp> createState() => _ParkikoAppState();
}

class _ParkikoAppState extends State<ParkikoApp> {
  bool _isAuthenticated = false; // Initial landing is the Login Screen

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkiko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isAuthenticated
          ? MainShellScreen(
              onLogout: () => setState(() => _isAuthenticated = false),
            )
          : LoginScreen(
              onLoginSuccess: () => setState(() => _isAuthenticated = true),
            ),
    );
  }
}
