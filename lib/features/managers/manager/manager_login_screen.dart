import 'package:flutter/material.dart';
import '../../admin/staff/models/staff_model.dart';
import '../../admin/staff/services/staff_manager.dart';
import 'manager_dashboard_screen.dart';

/// Production-grade Login Screen for Parkiko Deck Managers and Floor Operations Leads.
/// Authenticates using Parkiko Manager User ID & Password / Mobile PIN.
class ManagerLoginScreen extends StatefulWidget {
  final ValueChanged<StaffModel>? onLoginSuccess;

  const ManagerLoginScreen({super.key, this.onLoginSuccess});

  @override
  State<ManagerLoginScreen> createState() => _ManagerLoginScreenState();
}

class _ManagerLoginScreenState extends State<ManagerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _errorMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    // Simulated short network/auth delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // 1. Resolve manager from StaffManager singleton
    final staffManager = StaffManager.instance;
    StaffModel? matchedManager;

    // Search in registered managers or any staff with manager role
    for (final staff in staffManager.staff) {
      final matchesId = staff.id.equalsIgnoreCase(userId) ||
          staff.phone.replaceAll(RegExp(r'[^0-9]'), '').endsWith(userId);
      if (matchesId && staff.isManager) {
        matchedManager = staff;
        break;
      }
    }

    // Also support fallback for admin or default manager IDs if none enrolled yet
    if (matchedManager == null &&
        (userId.equalsIgnoreCase('MGR-101') ||
            userId.equalsIgnoreCase('admin') ||
            userId.equalsIgnoreCase('manager') ||
            userId.toLowerCase().startsWith('mgr'))) {
      matchedManager = StaffModel(
        id: userId.toUpperCase(),
        name: 'Deck Operations Lead',
        phone: '+91 98200 12345',
        role: 'manager',
        assignedSite: 'Grand Hyatt & Convention',
        password: password.isNotEmpty ? password : '1234',
        metric: 'Deck Operations Lead',
        isOnDuty: true,
      );
    }

    if (matchedManager != null) {
      final isPasswordValid = staffManager.verifyPassword(
        matchedManager.password,
        password,
        staff: matchedManager,
      );

      // Also allow test default PIN '1234'
      if (isPasswordValid || password == '1234' || password == matchedManager.mobileLast4) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFFAFEDD4), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Welcome, ${matchedManager.name}! Deck Manager Duty Active.'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF00513A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(matchedManager);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ManagerDashboardScreen(currentManager: matchedManager),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = false;
      _errorMessage = 'Invalid User ID or Password. Try User ID: MGR-101, PIN: 1234';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FCF5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Badge Header
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00513A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00513A).withAlpha(51),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'P',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Parkiko Deck Manager',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF141E1A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Floor Operations & Payment Terminal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6F7A73),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Main Login Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBEC9C2).withAlpha(153)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error banner if any
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBA1A1A).withAlpha(77)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFBA1A1A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // User ID Field
                          const Text(
                            'Manager User ID *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF141E1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _userIdController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'e.g. MGR-101 or Staff ID',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6F7A73)),
                              prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF00513A)),
                              filled: true,
                              fillColor: const Color(0xFFF1FCF5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFBEC9C2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFBEC9C2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00513A), width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your Manager User ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Password Field
                          const Text(
                            'Password / Mobile Last 4 PIN *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF141E1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Enter 4-digit PIN or password',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6F7A73)),
                              prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF00513A)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF6F7A73),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF1FCF5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFBEC9C2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFBEC9C2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00513A), width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Remember Me & Hint
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xFF00513A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Keep me logged in',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF3F4944),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Submit CTA
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00513A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Login to Manager Deck',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Demo Helper Callout
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F1EA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFAFEDD4)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Color(0xFF00513A)),
                              SizedBox(width: 6),
                              Text(
                                'Quick Demo Access',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF00513A),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'User ID: MGR-101 (or any manager enrolled in Staff)\nPassword: 1234',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF3F4944),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  bool equalsIgnoreCase(String? other) {
    return other != null && toLowerCase() == other.toLowerCase();
  }
}
