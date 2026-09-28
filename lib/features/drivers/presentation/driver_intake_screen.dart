// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/models/user_profile.dart';
import '../../admin/sites/services/site_manager.dart';
import '../models/vehicle_intake_model.dart';
import '../services/driver_service.dart';
import '../../../core/widgets/parkiko_logo.dart';
import 'driver_key_handover_screen.dart';

/// Vehicle Registration Number strict Indian plate formatter: `KL 00 AA 0000`
class _VehicleRegFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    String validCleaned = '';

    for (int i = 0; i < raw.length && validCleaned.length < 10; i++) {
      final char = raw[i];
      final currIdx = validCleaned.length;
      if (currIdx < 2) {
        // First 2 characters: Letters A-Z (State code)
        if (RegExp(r'[A-Z]').hasMatch(char)) validCleaned += char;
      } else if (currIdx < 4) {
        // Next 2 characters: Digits 0-9 (District code)
        if (RegExp(r'[0-9]').hasMatch(char)) validCleaned += char;
      } else if (currIdx < 6) {
        // Next 2 characters: Letters A-Z (Series code)
        if (RegExp(r'[A-Z]').hasMatch(char)) validCleaned += char;
      } else if (currIdx < 10) {
        // Next 4 characters: Digits 0-9 (Unique number)
        if (RegExp(r'[0-9]').hasMatch(char)) validCleaned += char;
      }
    }

    String formatted = '';
    if (validCleaned.isNotEmpty) {
      formatted += validCleaned.substring(0, min(2, validCleaned.length));
    }
    if (validCleaned.length > 2) {
      formatted += ' ${validCleaned.substring(2, min(4, validCleaned.length))}';
    }
    if (validCleaned.length > 4) {
      formatted += ' ${validCleaned.substring(4, min(6, validCleaned.length))}';
    }
    if (validCleaned.length > 6) {
      formatted += ' ${validCleaned.substring(6, validCleaned.length)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Dedicated Parkiko Driver Home & Vehicle Intake Screen matching HTML specification.
class DriverIntakeScreen extends StatefulWidget {
  final UserProfile? driverProfile;
  final VoidCallback onLogout;

  const DriverIntakeScreen({
    super.key,
    this.driverProfile,
    required this.onLogout,
  });

  @override
  State<DriverIntakeScreen> createState() => _DriverIntakeScreenState();
}

class _DriverIntakeScreenState extends State<DriverIntakeScreen>
    with SingleTickerProviderStateMixin {
  // Theme Palette strictly matching HTML specification
  static const Color kBackground = Color(0xFFF1FCF5);
  static const Color kSurface = Color(0xFFF1FCF5);
  static const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color kSurfaceContainerLow = Color(0xFFEBF6EF);
  static const Color kSurfaceContainerHighest = Color(0xFFDAE5DE);
  static const Color kPrimary = Color(0xFF00513A);
  static const Color kOnPrimary = Color(0xFFFFFFFF);
  static const Color kSecondary = Color(0xFF2D6955);
  static const Color kSecondaryContainer = Color(0xFFAFEDD4);
  static const Color kOnSecondaryContainer = Color(0xFF326D59);
  static const Color kTertiaryContainer = Color(0xFF006D2D);
  static const Color kOnSurface = Color(0xFF141E1A);
  static const Color kOnSurfaceVariant = Color(0xFF3F4944);
  static const Color kOutline = Color(0xFF6F7A73);
  static const Color kOutlineVariant = Color(0xFFBEC9C2);
  static const Color kError = Color(0xFFBA1A1A);
  static const Color kErrorContainer = Color(0xFFFFDAD6);
  static const Color kEmerald500 = Color(0xFF10B981);

  // Form Controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _vehicleRegController = TextEditingController();
  final _vehicleModelController = TextEditingController();

  // Focus Nodes for smooth keyboard jumping
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _regFocusNode = FocusNode();
  final _modelFocusNode = FocusNode();

  // Scroll Controller
  final _scrollController = ScrollController();

  // GlobalKeys for scrolling to error fields
  final _nameKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _regKey = GlobalKey();
  final _modelKey = GlobalKey();
  final _photoKey = GlobalKey();

  // Form State
  bool _hasPhoto = true; // HTML specification default: car photo pre-captured
  String _photoFileName = 'IMG_INTAKE_0284.JPG';
  bool _isOcrFlashing = false;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  // Validation Error Flags
  bool _errorName = false;
  bool _errorPhone = false;
  bool _errorReg = false;
  bool _errorModel = false;
  bool _errorPhoto = false;

  @override
  void initState() {
    super.initState();
    DriverService.instance.addListener(_onDriverStateChanged);
    SiteManager.instance.addListener(_onSitesChanged);
  }

  void _onDriverStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSitesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DriverService.instance.removeListener(_onDriverStateChanged);
    SiteManager.instance.removeListener(_onSitesChanged);
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _vehicleRegController.dispose();
    _vehicleModelController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _regFocusNode.dispose();
    _modelFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _driverInitials {
    final name = widget.driverProfile?.name.trim() ?? 'Rahul V.';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'RV';
  }

  String get _driverDisplayName {
    return widget.driverProfile?.name.trim().isNotEmpty == true
        ? widget.driverProfile!.name
        : 'Rahul V.';
  }

  String get _driverStaffId {
    return widget.driverProfile?.userId.trim().isNotEmpty == true
        ? widget.driverProfile!.userId
        : 'ST-108';
  }

  String get _activeSiteName {
    final assigned = widget.driverProfile?.organizationId?.trim();
    if (assigned != null && assigned.isNotEmpty && assigned != 'No Site Configured' && assigned != 'All Sites') {
      return assigned.contains('Valet') ? assigned : '$assigned • Valet Desk';
    }
    final selected = SiteManager.instance.selectedSite;
    if (selected.isNotEmpty && selected != 'No Site Configured' && selected != 'All Sites') {
      return '$selected • Valet Desk';
    }
    return 'Terminal 2 • Valet Desk';
  }

  // Smooth focus helper
  void _jumpToFocus(FocusNode targetNode, GlobalKey targetKey) {
    targetNode.requestFocus();
    Scrollable.ensureVisible(
      targetKey.currentContext ?? context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  // OCR Plate Scanner Simulation
  void _handleOcrScan() {
    const samplePlates = [
      'MH 02 CD 8821',
      'DL 01 AB 4920',
      'KA 03 MG 9912',
      'MH 12 PK 3301',
      'KL 07 BZ 4501',
    ];
    final randomPlate = samplePlates[Random().nextInt(samplePlates.length)];

    setState(() {
      _vehicleRegController.text = randomPlate;
      _errorReg = false;
      _isOcrFlashing = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isOcrFlashing = false);
        _jumpToFocus(_modelFocusNode, _modelKey);
      }
    });
  }

  // Photo state toggles
  void _capturePhoto() {
    setState(() {
      _hasPhoto = true;
      _photoFileName = 'IMG_INTAKE_${1000 + Random().nextInt(9000)}.JPG';
      _errorPhoto = false;
    });
  }

  void _removePhoto() {
    setState(() {
      _hasPhoto = false;
    });
  }

  // Form Submission
  Future<void> _handleSubmit() async {
    final name = _customerNameController.text.trim();
    final phone = _customerPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final reg = _vehicleRegController.text.trim();
    final model = _vehicleModelController.text.trim();

    final regPattern = RegExp(r'^[A-Z]{2}\s[0-9]{2}\s[A-Z]{2}\s[0-9]{4}$');

    setState(() {
      _errorName = name.isEmpty;
      _errorPhone = phone.length != 10;
      _errorReg = !regPattern.hasMatch(reg);
      _errorModel = model.isEmpty;
      _errorPhoto = !_hasPhoto;
    });

    if (_errorName) {
      _jumpToFocus(_nameFocusNode, _nameKey);
      return;
    }
    if (_errorPhone) {
      _jumpToFocus(_phoneFocusNode, _phoneKey);
      return;
    }
    if (_errorReg) {
      _jumpToFocus(_regFocusNode, _regKey);
      return;
    }
    if (_errorModel) {
      _jumpToFocus(_modelFocusNode, _modelKey);
      return;
    }
    if (_errorPhoto) {
      Scrollable.ensureVisible(
        _photoKey.currentContext ?? context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // All 5 items validated
    setState(() {
      _isSubmitting = true;
      _isSuccess = false;
    });

    // Simulated network latency
    await Future.delayed(const Duration(milliseconds: 600));

    final intakeId = 'INT-${1000 + Random().nextInt(9000)}';
    final newIntake = VehicleIntakeModel(
      id: intakeId,
      customerName: name,
      customerPhone: phone,
      vehicleReg: reg,
      vehicleModel: model,
      photoName: _photoFileName,
      driverId: _driverStaffId,
      driverName: _driverDisplayName,
      siteName: _activeSiteName,
      status: 'intake_registered',
      createdAt: DateTime.now(),
    );

    await DriverService.instance.submitIntake(
      newIntake,
      organizationId: widget.driverProfile?.organizationId ?? 'default_org',
      locationId: _activeSiteName,
    );

    final numPart = intakeId.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanDigits = numPart.isNotEmpty
        ? numPart
        : (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    final cleanTicketNum = 'BILL #PK-$cleanDigits-T2';

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });

      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => DriverKeyHandoverScreen(
            intake: newIntake,
            driverProfile: widget.driverProfile,
            ticketNumber: cleanTicketNum,
            onCompleted: () {
              _resetForm();
            },
          ),
        ),
      );

      if (completed == true && mounted) {
        _resetForm();
      }
    }
  }

  void _resetForm() {
    setState(() {
      _customerNameController.clear();
      _customerPhoneController.clear();
      _vehicleRegController.clear();
      _vehicleModelController.clear();
      _hasPhoto = true; // reset to pre-ready photo state
      _photoFileName = 'IMG_INTAKE_${1000 + Random().nextInt(9000)}.JPG';
      _isSubmitting = false;
      _isSuccess = false;
      _errorName = false;
      _errorPhone = false;
      _errorReg = false;
      _errorModel = false;
      _errorPhoto = false;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Driver Profile & Sign-out Bottom Sheet
  void _openDriverProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: kSurfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kOutlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimary.withAlpha(50), width: 3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _driverInitials,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kOnPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _driverDisplayName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kOnSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kSecondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _driverStaffId,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: kOnSecondaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Valet Operator',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: kOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: kOutlineVariant),
              const SizedBox(height: 12),

              // Duty toggle switch
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_outline, color: kPrimary, size: 20),
                ),
                title: Text(
                  'Driver Duty Status',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: kOnSurface),
                ),
                subtitle: Text(
                  DriverService.instance.isOnDuty ? 'Currently active & accepting vehicles' : 'Shift on break / off duty',
                  style: GoogleFonts.inter(fontSize: 12, color: kOnSurfaceVariant),
                ),
                trailing: Switch(
                  value: DriverService.instance.isOnDuty,
                  activeColor: kPrimary,
                  onChanged: (val) {
                    DriverService.instance.toggleDutyStatus(
                      valetId: _driverStaffId,
                      userId: _driverStaffId,
                      organizationId: widget.driverProfile?.organizationId ?? 'default_org',
                      locationId: _activeSiteName,
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kError,
                    side: const BorderSide(color: kError, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onLogout();
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(
                    'Sign Out of Terminal',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnDuty = DriverService.instance.isOnDuty;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: kSurface.withOpacity(0.95),
            border: Border(
              bottom: BorderSide(
                color: kOutlineVariant.withOpacity(0.6),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Driver Avatar & Desk Info
                  InkWell(
                    onTap: _openDriverProfileSheet,
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        const ParkikoLogo(size: 34),
                        const SizedBox(width: 10),
                        // Avatar Badge
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: kPrimary.withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _driverInitials,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kOnPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: kEmerald500,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _activeSiteName,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                text: 'Driver: $_driverDisplayName ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kOnSurface,
                                ),
                                children: [
                                  TextSpan(
                                    text: '($_driverStaffId)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: kOnSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Duty Status Pill Button
                  InkWell(
                    onTap: () => DriverService.instance.toggleDutyStatus(),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOnDuty ? kSecondaryContainer.withOpacity(0.8) : kSurfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnDuty ? kPrimary : kOutline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isOnDuty ? kOnSecondaryContainer : kOutline,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STEPPER HERO HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox.shrink(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: kSecondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'New Intake',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kOnSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vehicle Intake & Booking',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kOnSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Capture customer & car details to register valet intake.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: kOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INTAKE FORM
                  // SECTION 1: CUSTOMER DETAILS
                  _buildSectionCard(
                    title: 'CUSTOMER DETAILS',
                    icon: Icons.person_outline,
                    headerTrailing: Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 14, color: kPrimary),
                            const SizedBox(width: 3),
                            Text(
                              'Auto-matched',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kErrorContainer.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REQUIRED',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: kError,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      // Customer Full Name
                      Column(
                        key: _nameKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Customer Full Name', isRequired: true),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: kSurfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _errorName ? kError : kOutlineVariant,
                                width: _errorName ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(Icons.badge_outlined, color: kOnSurfaceVariant, size: 20),
                                ),
                                Expanded(
                                  child: TextField(
                                    key: const Key('driver_customer_name_input'),
                                    controller: _customerNameController,
                                    focusNode: _nameFocusNode,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kOnSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g., name',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: kOutline.withAlpha(160),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      if (_errorName && val.trim().isNotEmpty) {
                                        setState(() => _errorName = false);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  key: const Key('btn_nav_phone'),
                                  icon: const Icon(Icons.arrow_downward, color: kPrimary, size: 20),
                                  onPressed: () => _jumpToFocus(_phoneFocusNode, _phoneKey),
                                  tooltip: 'Jump to WhatsApp Phone',
                                ),
                              ],
                            ),
                          ),
                          if (_errorName) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Please enter a valid customer name.',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: kError),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // WhatsApp Mobile Number
                      Column(
                        key: _phoneKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('WhatsApp Mobile Number', isRequired: true),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: kSurfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _errorPhone ? kError : kOutlineVariant,
                                width: _errorPhone ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.call_outlined, color: kOnSurfaceVariant, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+91',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: kOnSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    key: const Key('driver_customer_phone_input'),
                                    controller: _customerPhoneController,
                                    focusNode: _phoneFocusNode,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kOnSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '9876543210',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: kOutline.withAlpha(160),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      if (_errorPhone && val.length == 10) {
                                        setState(() => _errorPhone = false);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  key: const Key('btn_nav_reg'),
                                  icon: const Icon(Icons.arrow_downward, color: kPrimary, size: 20),
                                  onPressed: () => _jumpToFocus(_regFocusNode, _regKey),
                                  tooltip: 'Jump to Vehicle Registration Number',
                                ),
                              ],
                            ),
                          ),
                          if (_errorPhone) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Please enter a valid 10-digit mobile number.',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: kError),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 2: VEHICLE DETAILS
                  _buildSectionCard(
                    title: 'VEHICLE DETAILS',
                    icon: Icons.directions_car_outlined,
                    headerTrailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kErrorContainer.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ALL FIELDS REQUIRED',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: kError,
                        ),
                      ),
                    ),
                    children: [
                      // Vehicle Registration Number
                      Column(
                        key: _regKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Vehicle Registration Number', isRequired: true),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 48,
                            decoration: BoxDecoration(
                              color: kSurfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _errorReg
                                    ? kError
                                    : _isOcrFlashing
                                        ? kPrimary
                                        : kOutlineVariant,
                                width: (_errorReg || _isOcrFlashing) ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(Icons.pin, color: kOnSurfaceVariant, size: 20),
                                ),
                                Expanded(
                                  child: TextField(
                                    key: const Key('driver_vehicle_reg_input'),
                                    controller: _vehicleRegController,
                                    focusNode: _regFocusNode,
                                    textCapitalization: TextCapitalization.characters,
                                    inputFormatters: [
                                      _VehicleRegFormatter(),
                                      LengthLimitingTextInputFormatter(13),
                                    ],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: kOnSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'KL 00 AA 0000',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        letterSpacing: 1.0,
                                        color: kOutline.withAlpha(160),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      if (_errorReg && val.length >= 13) {
                                        setState(() => _errorReg = false);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  key: const Key('btn_scan_ocr'),
                                  icon: const Icon(Icons.document_scanner, color: kPrimary, size: 20),
                                  onPressed: _handleOcrScan,
                                  tooltip: 'Scan license plate (OCR simulation)',
                                ),
                                IconButton(
                                  key: const Key('btn_nav_model'),
                                  icon: const Icon(Icons.arrow_downward, color: kPrimary, size: 20),
                                  onPressed: () => _jumpToFocus(_modelFocusNode, _modelKey),
                                  tooltip: 'Jump to Vehicle Model',
                                ),
                              ],
                            ),
                          ),
                          if (_errorReg) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Please enter a valid vehicle license plate (e.g., KL 00 AA 0000).',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: kError),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            'Format: KL 00 AA 0000 (2 Letters • 2 Digits • 2 Letters • 4 Digits)',
                            style: GoogleFonts.inter(fontSize: 10, color: kOutline, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Vehicle Name / Model
                      Column(
                        key: _modelKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Vehicle Name / Model', isRequired: true),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: kSurfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _errorModel ? kError : kOutlineVariant,
                                width: _errorModel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(Icons.directions_car_outlined, color: kOnSurfaceVariant, size: 20),
                                ),
                                Expanded(
                                  child: TextField(
                                    key: const Key('driver_vehicle_model_input'),
                                    controller: _vehicleModelController,
                                    focusNode: _modelFocusNode,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kOnSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g., vehical name',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: kOutline.withAlpha(160),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      if (_errorModel && val.trim().isNotEmpty) {
                                        setState(() => _errorModel = false);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  key: const Key('btn_nav_photo'),
                                  icon: const Icon(Icons.arrow_downward, color: kPrimary, size: 20),
                                  onPressed: () {
                                    Scrollable.ensureVisible(
                                      _photoKey.currentContext ?? context,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  tooltip: 'Jump to Take Photo',
                                ),
                              ],
                            ),
                          ),
                          if (_errorModel) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Please enter vehicle model details.',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: kError),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Take Photo of Car
                      Column(
                        key: _photoKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFieldLabel('Take Photo of Car', isRequired: true),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kErrorContainer.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'MANDATORY',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: kError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // State 1 & State 2: Photo box
                          if (_hasPhoto)
                            // State 2: Photo Preview Box
                            Container(
                              key: const Key('photo_preview_box'),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kSurfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kSecondary, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: kSecondary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: kSecondary.withOpacity(0.3)),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(Icons.directions_car, color: kPrimary, size: 28),
                                        Positioned(
                                          bottom: 3,
                                          right: 3,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: kEmerald500,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _photoFileName,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: kOnSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 14, color: kEmerald500),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Photo ready • Condition logged',
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
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: const Key('btn_remove_photo'),
                                    icon: const Icon(Icons.delete_outline, color: kError, size: 22),
                                    onPressed: _removePhoto,
                                    tooltip: 'Remove photo and retake',
                                  ),
                                ],
                              ),
                            )
                          else
                            // State 1: Photo Dropzone
                            InkWell(
                              key: const Key('photo_dropzone'),
                              onTap: _capturePhoto,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: kSurfaceContainerLow.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _errorPhoto ? kError : kOutlineVariant,
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: kSecondaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.photo_camera, color: kOnSecondaryContainer, size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to capture or upload vehicle photo',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: kOnSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Captures front bumper, plate & overall condition',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: kOutline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_errorPhoto) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Please capture a vehicle inspection photo before continuing.',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: kError),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // STICKY ACTION BUTTON & FOOTER
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      key: const Key('btn_submit_intake'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSuccess
                            ? kTertiaryContainer
                            : kPrimary,
                        foregroundColor: kOnPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Validating & Proceeding...',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _isSuccess
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.done_all, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Intake Saved! Moving to Step 2',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Next',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: kPrimary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'All 5 intake items are mandatory to proceed',
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        text: label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: kOnSurfaceVariant,
        ),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: kError,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget headerTrailing,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: kPrimary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: kOnSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              headerTrailing,
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: kOutlineVariant),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
