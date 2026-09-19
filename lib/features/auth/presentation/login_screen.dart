import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/hud_button.dart';
import '../../../core/widgets/hud_card.dart';
import '../../../core/widgets/hud_text_field.dart';
import '../../../core/widgets/parkiko_logo.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController(text: 'PK-8041');
  final _passwordController = TextEditingController();
  bool _isAdmin = true;
  bool _keepLoggedIn = true;
  bool _isLoading = false;

  void _handleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      widget.onLoginSuccess();
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const ParkikoLogo(size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Parkiko Admin',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppColors.borderSubtle, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              color: AppColors.statusAvailable,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ONLINE',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.statusAvailable,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: AppColors.onSurfaceVariant, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Main Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        // Branding Section
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            const ParkikoLogo(size: 72),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: const Icon(Icons.shield, color: AppColors.groundZero, size: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Terminal diagnostics chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: AppColors.borderSubtle, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.terminal, size: 13, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Terminal & Operations Login • v2.4',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Welcome to Parkiko',
                          style: AppTypography.headlineLargeMobile.copyWith(
                            color: AppColors.textHighLuminance,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to manage valet operations, parking slots, and staff dispatch.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Container Card
                        HudCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Role Selection Tabs
                              Text(
                                'SELECT OPERATIONS ROLE',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.groundZero,
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _isAdmin = true),
                                        borderRadius: BorderRadius.zero,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _isAdmin ? AppColors.primaryContainer : Colors.transparent,
                                            borderRadius: BorderRadius.zero,
                                            border: _isAdmin
                                                ? Border.all(color: AppColors.borderFocused, width: 1)
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.admin_panel_settings,
                                                size: 16,
                                                color: _isAdmin ? AppColors.textHighLuminance : AppColors.outline,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'ADMIN',
                                                style: AppTypography.labelSmall.copyWith(
                                                  color: _isAdmin ? AppColors.textHighLuminance : AppColors.outline,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _isAdmin = false),
                                        borderRadius: BorderRadius.zero,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !_isAdmin ? AppColors.primaryContainer : Colors.transparent,
                                            borderRadius: BorderRadius.zero,
                                            border: !_isAdmin
                                                ? Border.all(color: AppColors.borderFocused, width: 1)
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.badge,
                                                size: 16,
                                                color: !_isAdmin ? AppColors.textHighLuminance : AppColors.outline,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'STAFF',
                                                style: AppTypography.labelSmall.copyWith(
                                                  color: !_isAdmin ? AppColors.textHighLuminance : AppColors.outline,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // User ID Input
                              HudTextField(
                                label: 'User ID',
                                controller: _userIdController,
                                placeholder: 'Enter your User ID (e.g. PK-8041)',
                                prefixIcon: Icons.account_circle,
                              ),
                              const SizedBox(height: 14),

                              // Password Input
                              HudTextField(
                                label: 'Password or 4-digit PIN',
                                controller: _passwordController,
                                placeholder: '••••••••',
                                isPassword: true,
                                prefixIcon: Icons.lock,
                              ),
                              const SizedBox(height: 12),

                              // Remember me & forgot PIN
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () => setState(() => _keepLoggedIn = !_keepLoggedIn),
                                    borderRadius: BorderRadius.zero,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: _keepLoggedIn ? AppColors.statusAvailable : AppColors.groundZero,
                                            borderRadius: BorderRadius.zero,
                                            border: Border.all(
                                              color: _keepLoggedIn ? AppColors.statusAvailable : AppColors.borderSubtle,
                                              width: 1,
                                            ),
                                          ),
                                          child: _keepLoggedIn
                                              ? const Icon(Icons.check, size: 14, color: AppColors.groundZero)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Keep me logged in on this terminal',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('PIN reset instruction sent to registered terminal admin.'),
                                          backgroundColor: AppColors.cardModule,
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot / Reset PIN?',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Sign In Button
                              HudButton(
                                text: 'Sign In to Terminal',
                                trailingIcon: Icons.arrow_forward,
                                isLoading: _isLoading,
                                onPressed: _handleSignIn,
                              ),
                              const SizedBox(height: 20),

                              // Divider
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: AppColors.borderSubtle),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'QUICK ACCESS',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.outline,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: AppColors.borderSubtle),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Biometric Button
                              HudButton(
                                text: 'Touch ID / Face ID Biometric',
                                icon: Icons.fingerprint,
                                variant: HudButtonVariant.secondary,
                                onPressed: _handleSignIn,
                              ),
                              const SizedBox(height: 12),

                              // OTP Option
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('OTP sent to registered supervisor mobile.'),
                                        backgroundColor: AppColors.cardModule,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.sms, size: 14, color: AppColors.secondaryContainer),
                                  label: Text(
                                    'Login using One-Time Password (OTP)',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.secondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Active Terminal Status Strip
                        HudCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          backgroundColor: AppColors.surfaceContainer,
                          borderColor: AppColors.borderSubtle,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.garage_outlined, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'North Deck Bay A-14 • Active',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.statusAvailable,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Live Dispatch',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Clean Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Need terminal clearance or shift badge? ',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contacting Lead Dispatcher on Deck T2...'),
                              backgroundColor: AppColors.cardModule,
                            ),
                          );
                        },
                        child: Text(
                          'Contact Deck Dispatcher',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Terms of Service', style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
                      Text('  •  ', style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
                      Text('Privacy Policy', style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
                      Text('  •  ', style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
                      Text('Terminal Status', style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
