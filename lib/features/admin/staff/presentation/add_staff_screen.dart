import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../sites/services/site_manager.dart';

// ── Color tokens matching Design System verbatim ──────────────────────────────
const _kPrimary = AppColors.primary; // #00513A
const _kPrimaryContainer = AppColors.primaryContainer; // #0F6B4F
const _kOnPrimary = AppColors.onPrimary; // #FFFFFF
const _kSecondaryContainer = AppColors.secondaryContainer; // #AFEDD4
const _kSurface = AppColors.surface; // #F1FCF5
const _kSurfaceContainerLowest = AppColors.surfaceContainerLowest; // #FFFFFF
const _kSurfaceContainerLow = AppColors.surfaceContainerLow; // #EBF6EF
const _kSurfaceContainer = AppColors.surfaceContainer; // #E5F1EA
const _kOutlineVariant = AppColors.outlineVariant; // #BEC9C2
const _kOnSurface = AppColors.onSurface; // #141E1A
const _kOnSurfaceVariant = AppColors.onSurfaceVariant; // #3F4944
const _kError = AppColors.error; // #BA1A1A
const _kOutline = AppColors.outline; // #6F7A73

// ── Typography helper with web-safe fallback ─────────────────────────────────
TextStyle _font(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

// ── Role definition ───────────────────────────────────────────────────────────
enum VRole { driver, manager, asstManager }

class _RoleOption {
  final VRole role;
  final String label;
  final String subtitle;
  final IconData icon;

  const _RoleOption({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

const List<_RoleOption> _roles = [
  _RoleOption(
    role: VRole.driver,
    label: 'Driver',
    subtitle: 'Valet bay & terminal retrieval',
    icon: Icons.directions_car,
  ),
  _RoleOption(
    role: VRole.manager,
    label: 'Manager',
    subtitle: 'Operations & deck supervisor',
    icon: Icons.manage_accounts,
  ),
  _RoleOption(
    role: VRole.asstManager,
    label: 'Assistant Manager',
    subtitle: 'Deck coordination & shifts',
    icon: Icons.supervisor_account,
  ),
];

const List<String> _sites = [
  'Aerocity Grand Terminal - T2',
  'Grand Hyatt & Convention',
  'JW Marriott Porch',
  'South City Luxury Mall Deck',
  'CyberHub Corporate Plaza',
];

typedef StaffCreatedCallback = void Function(
  String name,
  VRole role,
  String site, {
  String? phone,
  String? staffId,
  String? password,
  String? email,
  String? licenseNo,
  DateTime? licenseExpiry,
  bool? multiSiteAccess,
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AddStaffScreen extends StatefulWidget {
  final StaffCreatedCallback? onCreated;

  const AddStaffScreen({super.key, this.onCreated});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: '1234');
  late final TextEditingController _staffIdCtrl;
  bool _obscurePassword = true;

  VRole _selectedRole = VRole.driver;
  List<String> get _availableSites {
    if (SiteManager.instance.hasSites) {
      final names = List<String>.from(SiteManager.instance.siteNames);
      for (final s in _sites) {
        if (!names.contains(s)) names.add(s);
      }
      return names;
    }
    return _sites;
  }

  String _selectedSite = _sites.first;
  bool _multiSiteAccess = true;
  bool _isSaving = false;
  String _staffId = 'PK-119';
  DateTime? _licenseExpiry;
  bool _hasPhoto = false;
  bool _dateValidationError = false;
  bool _provideLicenseLater = false;

  @override
  void initState() {
    super.initState();
    _staffId = 'PK-${100 + Random().nextInt(900)}';
    _staffIdCtrl = TextEditingController(text: _staffId);
    if (SiteManager.instance.hasSites &&
        SiteManager.instance.selectedSite.isNotEmpty &&
        !SiteManager.instance.selectedSite.startsWith('All Sites')) {
      _selectedSite = SiteManager.instance.selectedSite;
    } else {
      _selectedSite = _availableSites.first;
    }

    _phoneCtrl.addListener(() {
      final clean = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.length >= 4) {
        final last4 = clean.substring(clean.length - 4);
        if (_passwordCtrl.text == '1234' || _passwordCtrl.text.isEmpty) {
          _passwordCtrl.text = last4;
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _staffIdCtrl.dispose();
    super.dispose();
  }

  void _regenerateId() {
    final suffix = (100 + Random().nextInt(900)).toString();
    setState(() {
      _staffId = 'PK-$suffix';
      _staffIdCtrl.text = _staffId;
    });
  }

  bool get _needsLicense => _selectedRole == VRole.driver;
  bool get _isLicenseRequired => _needsLicense && !_provideLicenseLater;

  void _simulatePhotoCapture(String source) {
    setState(() => _hasPhoto = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                source == 'Camera'
                    ? 'Staff photo captured and attached!'
                    : (source == 'Gallery'
                        ? 'Staff photo selected from gallery!'
                        : 'Default valet avatar applied!'),
                style: _font(13, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _kPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openPhotoOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _kSurfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff Profile Photo',
                style: _font(16, weight: FontWeight.w700, color: _kOnSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Used for terminal badge & digital credentials',
                style: _font(12, color: _kOnSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _kSurfaceContainer,
                  child: Icon(Icons.photo_camera, color: _kPrimary),
                ),
                title: Text('Take Photo', style: _font(14, weight: FontWeight.w600)),
                subtitle: Text('Open camera & auto-crop face', style: _font(12, color: _kOnSurfaceVariant)),
                onTap: () {
                  Navigator.pop(ctx);
                  _simulatePhotoCapture('Camera');
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _kSurfaceContainer,
                  child: Icon(Icons.photo_library, color: _kPrimary),
                ),
                title: Text('Upload from Gallery', style: _font(14, weight: FontWeight.w600)),
                subtitle: Text('Select saved headshot or badge', style: _font(12, color: _kOnSurfaceVariant)),
                onTap: () {
                  Navigator.pop(ctx);
                  _simulatePhotoCapture('Gallery');
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _kSurfaceContainer,
                  child: Icon(Icons.face, color: _kPrimary),
                ),
                title: Text('Use Valet Avatar', style: _font(14, weight: FontWeight.w600)),
                subtitle: Text('Standard valet uniform badge', style: _font(12, color: _kOnSurfaceVariant)),
                onTap: () {
                  Navigator.pop(ctx);
                  _simulatePhotoCapture('Avatar');
                },
              ),
              if (_hasPhoto) ...[
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline, color: _kError),
                  ),
                  title: Text('Remove Photo', style: _font(14, weight: FontWeight.w600, color: _kError)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _hasPhoto = false);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleDismiss() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: _kPrimary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Valet Team Onboarding',
              style: _font(18, weight: FontWeight.w700, color: _kOnSurface),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Complete this form to create valet terminal login credentials and assign staff to duty sites.',
                style: _font(13, color: _kOnSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 12),
              const _HelpPoint(
                title: 'Staff ID',
                description: 'Used by the valet member to log in to handheld mobile terminals.',
              ),
              const SizedBox(height: 8),
              const _HelpPoint(
                title: 'Role & Driving License',
                description: 'Drivers and Assistant Managers require commercial RTA credentials to operate guest vehicles.',
              ),
              const SizedBox(height: 8),
              const _HelpPoint(
                title: 'WhatsApp Dispatch',
                description: 'Upon saving, an encrypted digital ID badge PDF and access pin are sent automatically.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got It',
              style: _font(14, weight: FontWeight.w700, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isDateValid = !_isLicenseRequired || _licenseExpiry != null;

    setState(() {
      _dateValidationError = !isDateValid;
    });

    if (!isFormValid || !isDateValid) {
      _showError('Please complete all required fields correctly.');
      return;
    }

    try {
      setState(() => _isSaving = true);
      final assignedId = _staffIdCtrl.text.trim().isNotEmpty
          ? _staffIdCtrl.text.trim()
          : _staffId;

      widget.onCreated?.call(
        _nameCtrl.text.trim(),
        _selectedRole,
        _selectedSite,
        phone: _phoneCtrl.text.trim(),
        staffId: assignedId,
        password: _passwordCtrl.text.trim().isNotEmpty ? _passwordCtrl.text.trim() : '1234',
        email: _emailCtrl.text.trim(),
        licenseNo: _licenseCtrl.text.trim(),
        licenseExpiry: _licenseExpiry,
        multiSiteAccess: _multiSiteAccess,
      );

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context, rootNavigator: true).maybePop(true);
        }
      }
    } catch (e) {
      debugPrint('[AddStaffScreen] Error during save: $e');
      if (mounted) {
        _showError('Failed to save staff: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: _font(13, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _kError,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kSurface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary, size: 24),
          onPressed: _handleDismiss,
          tooltip: 'Go Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Staff',
              style: _font(18, weight: FontWeight.w700, color: _kOnSurface, letterSpacing: -0.3, height: 1.2),
            ),
            Text(
              'Valet Team Onboarding',
              style: _font(11, weight: FontWeight.w500, color: _kOnSurfaceVariant, letterSpacing: 0.2),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: _showHelpDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kSurfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kOutlineVariant.withAlpha(150)),
                ),
                child: const Icon(Icons.help_outline, color: _kOnSurfaceVariant, size: 20),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _kOutlineVariant.withAlpha(100)),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Profile Avatar & Badge Card ───────
                    _FormCard(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _openPhotoOptionsSheet,
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kSurfaceContainer,
                                    border: Border.all(
                                      color: _hasPhoto ? _kPrimary : _kOutlineVariant,
                                      width: 2,
                                    ),
                                  ),
                                  child: _hasPhoto
                                      ? ClipOval(
                                          child: Container(
                                            color: _kSecondaryContainer,
                                            child: const Center(
                                              child: Icon(Icons.face, size: 52, color: _kPrimary),
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.person, size: 40, color: _kPrimary),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _openPhotoOptionsSheet,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _kPrimaryContainer,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _kSurfaceContainerLowest, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(40),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.camera_alt, color: _kOnPrimary, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upload Staff Photo',
                            style: _font(14, weight: FontWeight.w600, color: _kOnSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPEG, PNG or HEIC · Max 5MB',
                            textAlign: TextAlign.center,
                            style: _font(12, color: _kOnSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _simulatePhotoCapture('Camera'),
                                icon: const Icon(Icons.camera_alt, size: 16, color: _kPrimary),
                                label: Text('Take Photo', style: _font(11, weight: FontWeight.w600, color: _kOnSurface)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _kOutlineVariant),
                                  backgroundColor: _kSurface,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _simulatePhotoCapture('Gallery'),
                                icon: const Icon(Icons.upload_file, size: 16, color: _kPrimary),
                                label: Text('Upload from Gallery', style: _font(11, weight: FontWeight.w600, color: _kOnSurface)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _kOutlineVariant),
                                  backgroundColor: _kSurface,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 2. Personal Information Card ─────────
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardHeader(
                            icon: Icons.person_outline,
                            title: 'Personal Information',
                            trailing: _PillBadge(text: 'Required', color: _kPrimary),
                          ),
                          const SizedBox(height: 14),

                          // Full Name
                          const _FieldLabel(text: 'Full Name', required: true),
                          const SizedBox(height: 6),
                          _StyledInput(
                            controller: _nameCtrl,
                            hint: 'e.g. Vikram Sharma',
                            keyboard: TextInputType.name,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              if (v.trim().length < 2) {
                                return 'Name is too short';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Mobile Phone
                          const _FieldLabel(text: 'Mobile Number', required: true),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _kSurfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _kOutlineVariant),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '+91 (IN)',
                                      style: _font(13, weight: FontWeight.w600, color: _kOnSurface),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, color: _kOutline, size: 18),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StyledInput(
                                  controller: _phoneCtrl,
                                  hint: '98765 43210',
                                  keyboard: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Mobile number is required';
                                    }
                                    if (v.trim().length < 10) {
                                      return 'Must be 10 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Staff ID
                          Row(
                            children: [
                              const Expanded(
                                child: _FieldLabel(text: 'Staff ID (Username)', required: true),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Used for app login',
                                style: _font(11, weight: FontWeight.w500, color: _kPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _StyledInput(
                            controller: _staffIdCtrl,
                            hint: 'e.g. PK-119',
                            prefixIcon: const Icon(Icons.badge, size: 20, color: _kPrimary),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh, size: 20, color: _kOutline),
                              onPressed: _regenerateId,
                              tooltip: 'Regenerate Staff ID',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Login Password / PIN
                          Row(
                            children: [
                              const Expanded(
                                child: _FieldLabel(text: 'Login Password / PIN', required: true),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mobile valet login',
                                style: _font(11, weight: FontWeight.w500, color: _kPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _StyledInput(
                            controller: _passwordCtrl,
                            hint: 'Enter PIN or password (default: 1234)',
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: _kPrimary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                                color: _kOutline,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Password is required for mobile driver login';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Work Email
                          Row(
                            children: [
                              const _FieldLabel(text: 'Work Email'),
                              const SizedBox(width: 4),
                              Text(
                                '(Optional)',
                                style: _font(11, color: _kOnSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _StyledInput(
                            controller: _emailCtrl,
                            hint: 'e.g. v.sharma@parkiko.com',
                            keyboard: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 3. Role & Qualifications Card ────────
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardHeader(
                            icon: Icons.engineering,
                            title: 'Valet Role & Qualifications',
                            trailing: _PillBadge(text: 'Required', color: _kPrimary),
                          ),
                          const SizedBox(height: 14),

                          // Role Cards
                          ..._roles.map((option) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _RoleCard(
                                  option: option,
                                  isSelected: _selectedRole == option.role,
                                  onTap: () => setState(() {
                                    _selectedRole = option.role;
                                    if (!_needsLicense) {
                                      _dateValidationError = false;
                                    }
                                  }),
                                ),
                              )),

                          if (_needsLicense) ...[
                            const SizedBox(height: 4),

                            // Commercial Driving Credentials Container
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _kSurfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _kOutlineVariant.withAlpha(120)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_user, color: _kPrimary, size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Commercial Driving Credentials',
                                          style: _font(12, weight: FontWeight.w600, color: _kOnSurface),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _kSecondaryContainer.withAlpha(100),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.verified, size: 13, color: _kPrimary),
                                            const SizedBox(width: 3),
                                            Text(
                                              'RTA Verified',
                                              style: _font(11, weight: FontWeight.w600, color: _kPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!_provideLicenseLater) ...[
                                    const SizedBox(height: 12),
                                    const _FieldLabel(text: 'Driving License Number', required: true),
                                    const SizedBox(height: 6),
                                    _StyledInput(
                                      controller: _licenseCtrl,
                                      hint: 'e.g. DL-0420110012345',
                                      validator: (v) {
                                        if (_isLicenseRequired && (v == null || v.trim().isEmpty)) {
                                          return 'Driving license number is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    const _FieldLabel(text: 'License Expiry Date', required: true),
                                    const SizedBox(height: 6),
                                    _DateInputField(
                                      date: _licenseExpiry,
                                      hasError: _dateValidationError,
                                      errorText: 'License expiry date is required',
                                      onChanged: (d) => setState(() {
                                        _licenseExpiry = d;
                                        _dateValidationError = false;
                                      }),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    key: const Key('verification_later_row'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() {
                                      _provideLicenseLater = !_provideLicenseLater;
                                      if (_provideLicenseLater) {
                                        _dateValidationError = false;
                                      }
                                    }),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: _provideLicenseLater,
                                              onChanged: (val) => setState(() {
                                                _provideLicenseLater = val ?? false;
                                                if (_provideLicenseLater) {
                                                  _dateValidationError = false;
                                                }
                                              }),
                                              activeColor: _kPrimary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Verification in progress (Provide license details later)',
                                              style: _font(12, weight: FontWeight.w500, color: _kOnSurfaceVariant),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 4. Site & Location Assignment Card ───
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardHeader(
                            icon: Icons.business,
                            title: 'Site & Location Assignment',
                            trailing: _PillBadge(text: 'Required', color: _kPrimary),
                          ),
                          const SizedBox(height: 14),

                          const _FieldLabel(text: 'Primary Site / Property', required: true),
                          const SizedBox(height: 6),
                          _StyledDropdown(
                            value: _selectedSite,
                            items: _availableSites,
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedSite = v);
                            },
                          ),
                          const SizedBox(height: 14),

                          // Multi-site floating access checkbox
                          InkWell(
                            onTap: () => setState(() => _multiSiteAccess = !_multiSiteAccess),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _kSurfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kOutlineVariant.withAlpha(80)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _multiSiteAccess,
                                      onChanged: (v) => setState(() => _multiSiteAccess = v ?? false),
                                      activeColor: _kPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Allow Multi-Site Floating Access',
                                                style: _font(13, weight: FontWeight.w600, color: _kOnSurface),
                                              ),
                                            ),
                                            if (_multiSiteAccess) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _kSecondaryContainer.withAlpha(130),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Active',
                                                  style: _font(11, weight: FontWeight.w700, color: _kPrimary),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Staff can accept valet and retrieval jobs across any linked sister properties in the cluster',
                                          style: _font(11, color: _kOnSurfaceVariant, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 5. Telemetry WhatsApp Dispatch Note ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kOutlineVariant.withAlpha(80)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat, color: _kPrimary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: _font(12, color: _kOnSurfaceVariant, height: 1.5),
                                children: [
                                  const TextSpan(text: 'Once created, the staff member receives their valet terminal credentials and '),
                                  TextSpan(
                                    text: 'digital ID card as PDF',
                                    style: _font(12, weight: FontWeight.w700, color: _kOnSurface),
                                  ),
                                  const TextSpan(text: ' dispatched to their '),
                                  TextSpan(
                                    text: 'WhatsApp',
                                    style: _font(12, weight: FontWeight.w700, color: _kPrimary),
                                  ),
                                  const TextSpan(text: ' number.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 6. Form Action Buttons ──────────────
                    Row(
                      children: [
                        // Cancel
                        OutlinedButton(
                          onPressed: _handleDismiss,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kOutlineVariant),
                            foregroundColor: _kOnSurface,
                            minimumSize: const Size(90, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Cancel',
                            style: _font(14, weight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Save & Assign Staff
                        Expanded(
                          child: ElevatedButton.icon(
                            key: const Key('save_staff_button'),
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimaryContainer,
                              foregroundColor: _kOnPrimary,
                              disabledBackgroundColor: _kPrimaryContainer.withAlpha(150),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.person_add, size: 20),
                            label: Text(
                              _isSaving ? 'Saving...' : '+ Save & Assign Staff',
                              style: _font(14, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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

// ── Sub-widgets & Components ──────────────────────────────────────────────────

class _HelpPoint extends StatelessWidget {
  final String title;
  final String description;

  const _HelpPoint({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 16, color: _kPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: _font(12, color: _kOnSurfaceVariant, height: 1.4),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: _font(12, weight: FontWeight.w700, color: _kOnSurface),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOutlineVariant.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17211D).withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const _CardHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kSurfaceContainer)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kPrimary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: _font(15, weight: FontWeight.w700, color: _kOnSurface),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel({required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: _font(12, weight: FontWeight.w500, color: _kOnSurfaceVariant),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: _font(12, weight: FontWeight.w700, color: _kError),
                ),
              ]
            : [],
      ),
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;

  const _StyledInput({
    required this.controller,
    required this.hint,
    this.keyboard,
    this.inputFormatters,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
      style: _font(14, weight: FontWeight.w500, color: _kOnSurface),
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: _font(14, weight: FontWeight.w400, color: _kOutline),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: _kSurfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimaryContainer, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kError, width: 1.5),
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveItems = items.contains(value) ? items : [value, ...items];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kOutlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: _kOutline, size: 20),
          style: _font(14, weight: FontWeight.w500, color: _kOnSurface),
          items: effectiveItems
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('role_${option.role.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _kSecondaryContainer.withAlpha(50) : _kSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kPrimary : _kOutlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isSelected ? _kPrimary : _kOutline,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: _font(15, weight: FontWeight.w600, color: isSelected ? _kPrimary : _kOnSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: _font(12, color: _kOnSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _kPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _kPrimary : _kOutline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateInputField extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final bool hasError;
  final String? errorText;

  const _DateInputField({
    required this.date,
    required this.onChanged,
    this.hasError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final effectiveInitial = (date != null && date!.isAfter(DateTime(now.year - 5)))
        ? date!
        : now.add(const Duration(days: 365));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: effectiveInitial,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 20),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: _kPrimary, onPrimary: Colors.white),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _kSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? _kError : _kOutlineVariant,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? 'Select expiry date (DD / MM / YYYY)'
                        : '${date!.day.toString().padLeft(2, '0')} / ${date!.month.toString().padLeft(2, '0')} / ${date!.year}',
                    style: _font(
                      14,
                      color: date == null ? _kOutline : _kOnSurface,
                      weight: date == null ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.calendar_month, size: 20, color: hasError ? _kError : _kOutline),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Presets:',
              style: _font(11, weight: FontWeight.w500, color: _kOnSurfaceVariant),
            ),
            _QuickDateChip(
              label: '+1 Year',
              onTap: () => onChanged(now.add(const Duration(days: 365))),
            ),
            _QuickDateChip(
              label: '+3 Years',
              onTap: () => onChanged(now.add(const Duration(days: 365 * 3))),
            ),
            _QuickDateChip(
              label: '+5 Years',
              onTap: () => onChanged(now.add(const Duration(days: 365 * 5))),
            ),
          ],
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: _font(12, weight: FontWeight.w500, color: _kError),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('preset_$label'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _kSurfaceContainer,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kOutlineVariant.withAlpha(140)),
        ),
        child: Text(
          label,
          style: _font(11, weight: FontWeight.w600, color: _kPrimary),
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _PillBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kSecondaryContainer.withAlpha(100),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: _font(11, weight: FontWeight.w700, color: color),
      ),
    );
  }
}
