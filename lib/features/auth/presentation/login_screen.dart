// ignore_for_file: deprecated_member_use, unused_field
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/parkiko_logo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Tailwind color tokens matching HTML specification exactly
  static const Color kPrimary = Color(0xFF0F6B4F);
  static const Color kPrimaryDark = Color(0xFF0B523C);
  static const Color kPrimaryFixed = Color(0xFFA1F3CF);
  static const Color kSurface = Color(0xFFF1FCF5);
  static const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color kSurfaceContainerLow = Color(0xFFEAF5EE);
  static const Color kSurfaceContainer = Color(0xFFE2F0E7);
  static const Color kSurfaceContainerHigh = Color(0xFFD9EAE0);
  static const Color kOutlineVariant = Color(0xFFD0DED5);
  static const Color kOutline = Color(0xFF6F7A73);
  static const Color kOnSurface = Color(0xFF122019);
  static const Color kOnSurfaceVariant = Color(0xFF495B52);
  static const Color kOnPrimary = Color(0xFFFFFFFF);

  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userIdFocusNode = FocusNode();
  final _pinFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _keepLoggedIn = true;
  bool _isLoading = false;
  bool _userIdFocused = false;
  bool _pinFocused = false;

  // Floating Toast Notification state matching HTML
  bool _toastVisible = false;
  String _toastMessage = '';
  IconData _toastIcon = Icons.mark_email_read;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _userIdFocusNode.addListener(() {
      setState(() => _userIdFocused = _userIdFocusNode.hasFocus);
    });
    _pinFocusNode.addListener(() {
      setState(() => _pinFocused = _pinFocusNode.hasFocus);
    });
  }

  void _showToast(String message, IconData icon) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIcon = icon;
      _toastVisible = true;
    });

    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _toastVisible = false);
      }
    });
  }

  void _handleSignIn() async {
    final rawUser = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (rawUser.isEmpty) {
      _showToast('User ID is required to authenticate', Icons.error_outline);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please enter your Parkiko User ID.'),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }
    if (password.isEmpty) {
      _showToast('4-digit PIN is required', Icons.error_outline);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please enter your password.'),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }

    setState(() => _isLoading = true);

    // Resolve identifier: if entered numeric "8041", check if prefixed with "PK-"
    String identifier = rawUser;
    final isExplicitRolePrefix = rawUser.toUpperCase().startsWith('PK-') ||
        rawUser.toUpperCase().startsWith('ST-') ||
        rawUser.toUpperCase().startsWith('MGR-') ||
        rawUser.toUpperCase().startsWith('ASST-') ||
        rawUser.toLowerCase() == 'admin' ||
        rawUser.toLowerCase() == 'admin1' ||
        rawUser.toLowerCase() == 'driver1';

    if (!isExplicitRolePrefix && RegExp(r'^\d+$').hasMatch(rawUser)) {
      identifier = 'PK-$rawUser';
    }

    // Attempt sign-in with resolved identifier
    var result = await ref.read(currentUserProfileProvider.notifier).signIn(
      identifier: identifier,
      password: password,
      rememberMe: _keepLoggedIn,
    );

    // If PK- prefixed failed and raw was different, attempt with raw
    if (!result.isSuccess && identifier != rawUser) {
      result = await ref.read(currentUserProfileProvider.notifier).signIn(
        identifier: rawUser,
        password: password,
        rememberMe: _keepLoggedIn,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.isSuccess) {
        _showToast('Terminal access granted. Launching session...', Icons.verified);
        widget.onLoginSuccess();
      } else {
        final errMsg = result.errorMessage ?? 'Invalid User ID or password.';
        _showToast('Authentication failed: $errMsg', Icons.lock_reset);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(errMsg),
              backgroundColor: AppColors.error,
            ),
          );
      }
    }
  }

  Widget _buildQuickFillChip(String label, String id, String pin) {
    return InkWell(
      onTap: () {
        setState(() {
          _userIdController.text = id;
          _passwordController.text = pin;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: kSurfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kOutlineVariant.withOpacity(0.6)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _userIdFocusNode.dispose();
    _pinFocusNode.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          // Main Scrollable Area
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  children: [
                    // Top App Brand Bar (<header class="w-full px-6 pt-5 pb-3 flex items-center justify-between z-10">)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const ParkikoLogo(
                                size: 28,
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Parkiko',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => _showToast(
                                'Help & support desk: support@parkiko.com',
                                Icons.help_outline,
                              ),
                              child: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.help_outline,
                                  size: 24,
                                  color: kOnSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Content Area (<main class="w-full max-w-[370px] mx-auto px-4 flex-1 flex flex-col justify-center py-2">)
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 370),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Brand Emblem & Hero Header (<section class="text-center flex flex-col items-center mb-5">)
                                Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: kOutlineVariant.withOpacity(0.6),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const ParkikoLogo(
                                        size: 64,
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                    ),
                                    Text(
                                      'Welcome to Parkiko',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: kOnSurface,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 270),
                                      child: Text(
                                        'Sign in to manage valet operations, parking slots, and staff dispatch.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: kOnSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // White Elevated Card Container
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: kOutlineVariant.withOpacity(0.6),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kPrimary.withOpacity(0.06),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // User ID Input Field
                                      Text(
                                        'User ID',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: kOnSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _userIdFocused ? kPrimary : kOutlineVariant,
                                            width: _userIdFocused ? 1.5 : 1.0,
                                          ),
                                          boxShadow: _userIdFocused
                                              ? [
                                                  BoxShadow(
                                                    color: kPrimary.withOpacity(0.12),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.account_circle,
                                              color: kOnSurfaceVariant,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: kSurfaceContainer,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: kOutlineVariant.withOpacity(0.6),
                                                ),
                                              ),
                                              child: Text(
                                                'PK-',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: kPrimary,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: TextField(
                                                key: const Key('login_user_id_field'),
                                                controller: _userIdController,
                                                focusNode: _userIdFocusNode,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(4),
                                                ],
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: kOnSurface,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                                  hintText: '1234',
                                                  hintStyle: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: kOutline.withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // 4-Digit PIN Input Field
                                      Text(
                                        '4-Digit PIN',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: kOnSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _pinFocused ? kPrimary : kOutlineVariant,
                                            width: _pinFocused ? 1.5 : 1.0,
                                          ),
                                          boxShadow: _pinFocused
                                              ? [
                                                  BoxShadow(
                                                    color: kPrimary.withOpacity(0.12),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.lock,
                                              color: kOnSurfaceVariant,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: _passwordController,
                                                focusNode: _pinFocusNode,
                                                obscureText: _obscurePassword,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.digitsOnly,
                                                  LengthLimitingTextInputFormatter(4),
                                                ],
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: kOnSurface,
                                                  letterSpacing: _obscurePassword ? 2.0 : 0.0,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                                  hintText: '••••',
                                                  hintStyle: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: kOutline.withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                                color: kOnSurfaceVariant,
                                                size: 20,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscurePassword = !_obscurePassword,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Keep me logged in checkbox
                                      InkWell(
                                        onTap: () => setState(() => _keepLoggedIn = !_keepLoggedIn),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: Checkbox(
                                                  value: _keepLoggedIn,
                                                  activeColor: kPrimary,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  side: const BorderSide(
                                                    color: kOutlineVariant,
                                                    width: 1.5,
                                                  ),
                                                  onChanged: (val) => setState(
                                                    () => _keepLoggedIn = val ?? true,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
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
                                      ),
                                      const SizedBox(height: 14),

                                      // Primary CTA Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 44,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPrimary,
                                            foregroundColor: kOnPrimary,
                                            elevation: 1,
                                            shadowColor: kPrimary.withOpacity(0.2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _isLoading ? null : _handleSignIn,
                                          child: _isLoading
                                              ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Authenticating...',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  'Sign In',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),

                                      // Hidden accessibility / test button compatibility
                                      const SizedBox.shrink(),

                                      const SizedBox(height: 14),

                                      // Quick ID Preset Chips for effortless testing
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Text(
                                              'Demo:',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: kOnSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            _buildQuickFillChip('Admin', '1234', '7894'),
                                            const SizedBox(width: 5),
                                            _buildQuickFillChip('Manager', '0101', '1234'),
                                            const SizedBox(width: 5),
                                            _buildQuickFillChip('Asst. Mgr', '0201', '1234'),
                                            const SizedBox(width: 5),
                                            _buildQuickFillChip('Driver', '0108', '1234'),
                                          ],
                                        ),
                                      ),

                                      if (kDebugMode) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            TextButton(
                                              key: const Key('dev_bypass_login_button'),
                                              style: TextButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                              ),
                                              onPressed: () {
                                                ref.read(currentUserProfileProvider.notifier).devBypassLogin();
                                                widget.onLoginSuccess();
                                              },
                                              child: Text(
                                                'Dev Admin',
                                                style: GoogleFonts.inter(fontSize: 10, color: kOutline),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton(
                                              key: const Key('dev_bypass_driver_login_button'),
                                              style: TextButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                              ),
                                              onPressed: () {
                                                ref.read(currentUserProfileProvider.notifier).devBypassDriverLogin();
                                                widget.onLoginSuccess();
                                              },
                                              child: Text(
                                                'Dev Driver',
                                                style: GoogleFonts.inter(fontSize: 10, color: kOutline),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => _showToast('Terms of Service opened', Icons.description),
                            child: Text(
                              'Terms of Service',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: kOutline,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: kOutline,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showToast('Privacy Policy opened', Icons.policy),
                            child: Text(
                              'Privacy Policy',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: kOutline,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: kOutline,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showToast('Terminal Online • Latency 14ms', Icons.cloud_done),
                            child: Text(
                              'Terminal Status',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: kOutline,
                              ),
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

          // Floating Toast Notification (<div class="fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-[#122019] text-white ...">)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              offset: _toastVisible ? Offset.zero : const Offset(0, -0.4),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _toastVisible ? 1.0 : 0.0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF122019),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _toastIcon,
                          color: kPrimaryFixed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _toastMessage,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
