import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/parkiko_logo.dart';
import '../services/firebase_auth_service.dart';

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
  // Theme Palette matching HTML specification
  static const Color kBackground = Color(0xFFF1FCF5);
  static const Color kSurface = Color(0xFFF1FCF5);
  static const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color kSurfaceContainerLow = Color(0xFFEBF6EF);
  static const Color kSurfaceContainer = Color(0xFFE5F1EA);
  static const Color kSurfaceContainerHigh = Color(0xFFDFEBE4);
  static const Color kPrimary = Color(0xFF00513A);
  static const Color kPrimaryContainer = Color(0xFF0F6B4F);
  static const Color kOnPrimary = Color(0xFFFFFFFF);
  static const Color kSecondary = Color(0xFF2D6955);
  static const Color kOnSurface = Color(0xFF141E1A);
  static const Color kOnSurfaceVariant = Color(0xFF3F4944);
  static const Color kOutline = Color(0xFF6F7A73);
  static const Color kOutlineVariant = Color(0xFFBEC9C2);

  final _userIdController = TextEditingController(text: 'PK-8041');
  final _passwordController = TextEditingController(text: '8041');
  bool _isAdmin = true;
  bool _obscurePassword = true;
  bool _keepLoggedIn = true;
  bool _isLoading = false;

  void _handleSignIn() async {
    setState(() => _isLoading = true);
    final authService = FirebaseAuthService();
    final success = await authService.signInWithIdentifier(
      identifier: _userIdController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onLoginSuccess();
      }
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
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Linear Header
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: kSurface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_parking, color: kPrimary, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        'Parkiko Admin',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Online pill badge
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Terminal Diagnostics: Online • Latency 14ms'),
                              backgroundColor: kPrimaryContainer,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kSurfaceContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: kPrimaryContainer,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Online',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kOnSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Help button
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: kOnSurfaceVariant, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Valet Dispatch Support Desk: +91 800-PARKIKO'),
                              backgroundColor: kPrimaryContainer,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        tooltip: 'Support & Help',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Center Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        // Hero / Branding Section
                        const SizedBox(height: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kSurfaceContainerLowest,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: kOutlineVariant.withAlpha(100), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: const ParkikoLogo(size: 72),
                              ),
                            ),
                            Positioned(
                              bottom: -3,
                              right: -3,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kSurfaceContainerLowest, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.shield, color: kOnPrimary, size: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Terminal diagnostics chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: kSurfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.terminal, size: 14, color: kPrimary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Terminal & Operations Login • v2.4',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kOnSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          'Welcome to Parkiko',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: kOnSurface,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to manage valet operations, parking slots, and staff dispatch.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: kOnSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Main Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kSurfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kOutlineVariant.withAlpha(120), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(6),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Role Selection Tabs
                              Text(
                                'Select Operations Role',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kOnSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: kSurfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kOutlineVariant.withAlpha(80), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _isAdmin = true),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _isAdmin ? kSurfaceContainerLowest : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: _isAdmin
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withAlpha(10),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.admin_panel_settings,
                                                size: 16,
                                                color: _isAdmin ? kPrimary : kOnSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Admin',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: _isAdmin ? FontWeight.w700 : FontWeight.w500,
                                                  color: _isAdmin ? kPrimary : kOnSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _isAdmin = false),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: !_isAdmin ? kSurfaceContainerLowest : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: !_isAdmin
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withAlpha(10),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.badge_outlined,
                                                size: 16,
                                                color: !_isAdmin ? kPrimary : kOnSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Staff',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: !_isAdmin ? FontWeight.w700 : FontWeight.w500,
                                                  color: !_isAdmin ? kPrimary : kOnSurfaceVariant,
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
                              const SizedBox(height: 16),

                              // Input 1: User ID
                              Text(
                                'User ID',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kOnSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _userIdController,
                                style: GoogleFonts.inter(fontSize: 14, color: kOnSurface, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'Enter your User ID (e.g. PK-8041)',
                                  hintStyle: GoogleFonts.inter(fontSize: 14, color: kOutline.withAlpha(160)),
                                  prefixIcon: const Icon(Icons.account_circle_outlined, color: kOnSurfaceVariant, size: 20),
                                  filled: true,
                                  fillColor: kSurfaceContainerLowest,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: kOutlineVariant, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: kPrimary, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Input 2: Password / PIN Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Password or 4-digit PIN',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: kOnSurface,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('PIN reset instruction sent to registered terminal admin.'),
                                          backgroundColor: kPrimaryContainer,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot / Reset PIN?',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: kPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                keyboardType: TextInputType.text,
                                style: GoogleFonts.inter(fontSize: 14, color: kOnSurface, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: GoogleFonts.inter(fontSize: 14, color: kOutline.withAlpha(160)),
                                  prefixIcon: const Icon(Icons.lock_outline, color: kOnSurfaceVariant, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: kOnSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: kSurfaceContainerLowest,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: kOutlineVariant, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: kPrimary, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Remember Me Checkbox
                              InkWell(
                                onTap: () => setState(() => _keepLoggedIn = !_keepLoggedIn),
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _keepLoggedIn,
                                      activeColor: kPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) => setState(() => _keepLoggedIn = val ?? true),
                                    ),
                                    Flexible(
                                      child: Text(
                                        'Keep me logged in on this terminal',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: kOnSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Primary CTA Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryContainer,
                                    foregroundColor: kOnPrimary,
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleSignIn,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Sign In to Terminal',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward, size: 18),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Quick Access Divider
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: kOutlineVariant, thickness: 0.8)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'QUICK ACCESS',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: kOnSurfaceVariant,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: kOutlineVariant, thickness: 0.8)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Biometric Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: kSurfaceContainerLow,
                                    side: BorderSide(color: kOutlineVariant.withAlpha(180), width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _handleSignIn,
                                  icon: const Icon(Icons.fingerprint, color: kPrimary, size: 20),
                                  label: Text(
                                    'Touch ID / Face ID Biometric',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kOnSurface,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // OTP Option
                              Center(
                                child: InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('OTP sent to registered supervisor mobile.'),
                                        backgroundColor: kPrimaryContainer,
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.sms_outlined, size: 14, color: kSecondary),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'Login using One-Time Password (OTP)',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: kSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Active Terminal Status Strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: kSurfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kOutlineVariant.withAlpha(80), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.garage_outlined, size: 18, color: kPrimary),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'North Deck Bay A-14 • Active',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: kOnSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: kPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Live Dispatch',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: kPrimary,
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
              decoration: BoxDecoration(
                color: kSurface,
                border: Border(top: BorderSide(color: kOutlineVariant.withAlpha(60), width: 1)),
              ),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Need terminal clearance or shift badge? ',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contacting Lead Dispatcher on Deck T2...'),
                              backgroundColor: kPrimaryContainer,
                            ),
                          );
                        },
                        child: Text(
                          'Contact Deck Dispatcher',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Terms of Service', style: GoogleFonts.inter(fontSize: 10, color: kOutline)),
                      Text('  •  ', style: GoogleFonts.inter(fontSize: 10, color: kOutline)),
                      Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 10, color: kOutline)),
                      Text('  •  ', style: GoogleFonts.inter(fontSize: 10, color: kOutline)),
                      Text('Terminal Status', style: GoogleFonts.inter(fontSize: 10, color: kOutline)),
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
