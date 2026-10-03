// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/models/user_profile.dart';
import '../../admin/sites/services/site_manager.dart';
import '../models/vehicle_intake_model.dart';
import '../services/driver_service.dart';
import 'driver_key_handover_screen.dart';
import 'driver_vehicle_return_screen.dart';
import '../../../core/widgets/parkiko_logo.dart';

/// Vehicle Registration Number flexible Indian plate formatter:
/// 2 State Letters -> Space -> 1-2 District Digits -> Space -> 1-3 Series Letters -> Space -> 4 Digits
class _VehicleRegFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final isDeleting = newValue.text.length < oldValue.text.length;
    if (isDeleting) {
      return TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
    }

    final formatted = _formatPlateString(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _formatPlateString(String input) {
    final upper = input.toUpperCase();
    final state = StringBuffer();
    final district = StringBuffer();
    final series = StringBuffer();
    final number = StringBuffer();

    int stage = 1; // 1: state, 2: district, 3: series, 4: number
    bool hasSpaceAfterDistrict = false;
    bool hasSpaceAfterSeries = false;

    for (int i = 0; i < upper.length; i++) {
      final char = upper[i];

      if (char == ' ') {
        if (stage == 1 && state.length >= 2) {
          stage = 2;
        } else if (stage == 2 && district.isNotEmpty) {
          stage = 3;
          hasSpaceAfterDistrict = true;
        } else if (stage == 3 && series.isNotEmpty) {
          stage = 4;
          hasSpaceAfterSeries = true;
        }
        continue;
      }

      if (stage == 1) {
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          if (state.length < 2) {
            state.write(char);
            if (state.length == 2) {
              stage = 2;
            }
          }
        }
      } else if (stage == 2) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          if (district.length < 2) {
            district.write(char);
            if (district.length == 2) {
              stage = 3;
            }
          }
        } else if (RegExp(r'[A-Z]').hasMatch(char) && district.isNotEmpty) {
          stage = 3;
          hasSpaceAfterDistrict = true;
          series.write(char);
        }
      } else if (stage == 3) {
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          if (series.length < 3) {
            series.write(char);
            if (series.length == 3) {
              stage = 4;
            }
          }
        } else if (RegExp(r'[0-9]').hasMatch(char) && series.isNotEmpty) {
          stage = 4;
          hasSpaceAfterSeries = true;
          number.write(char);
        }
      } else if (stage == 4) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          if (number.length < 4) {
            number.write(char);
          }
        }
      }
    }

    String result = state.toString();

    if (state.length == 2) {
      result += ' ';
      if (district.isNotEmpty) {
        result += district.toString();
        if (district.length == 2 || hasSpaceAfterDistrict) {
          result += ' ';
          if (series.isNotEmpty) {
            result += series.toString();
            if (series.length == 3 || hasSpaceAfterSeries) {
              result += ' ';
              if (number.isNotEmpty) {
                result += number.toString();
              }
            }
          }
        }
      }
    }

    return result;
  }
}

TextInputType getPlateKeyboardType(String text) {
  if (text.isEmpty) return TextInputType.text;

  final parts = text.split(' ');
  if (parts.isEmpty) return TextInputType.text;

  if (parts.length == 1) {
    return parts[0].length < 2 ? TextInputType.text : TextInputType.number;
  }

  if (parts.length == 2) {
    final district = parts[1];
    if (text.endsWith(' ') && district.isNotEmpty) {
      return TextInputType.text;
    }
    return district.length < 2 ? TextInputType.number : TextInputType.text;
  }

  if (parts.length == 3) {
    final series = parts[2];
    if (text.endsWith(' ') && series.isNotEmpty) {
      return TextInputType.number;
    }
    return series.length < 3 ? TextInputType.text : TextInputType.number;
  }

  return TextInputType.number;
}

/// Dedicated Parkiko Driver Home & Vehicle Intake Screen matching HTML specification.
class DriverIntakeScreen extends StatefulWidget {
  final UserProfile? driverProfile;
  final VoidCallback onLogout;
  final bool initialHasPhoto;
  final ImagePicker? imagePicker;

  const DriverIntakeScreen({
    super.key,
    this.driverProfile,
    required this.onLogout,
    this.initialHasPhoto = false,
    this.imagePicker,
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
  late bool _hasPhoto;
  String _photoFileName = '';
  String? _photoFilePath;
  bool _isCapturingPhoto = false;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  TextInputType _regKeyboardType = TextInputType.text;

  // Validation Error Flags
  bool _errorName = false;
  bool _errorPhone = false;
  bool _errorReg = false;
  bool _errorModel = false;
  bool _errorPhoto = false;

  final Set<String> _handledDispatchedVehicles = {};

  @override
  void initState() {
    super.initState();
    _hasPhoto = widget.initialHasPhoto;
    if (_hasPhoto) {
      _photoFileName = 'IMG_INTAKE_0284.JPG';
    }
    DriverService.instance.addListener(_onDriverStateChanged);
    SiteManager.instance.addListener(_onSitesChanged);
    _vehicleRegController.addListener(_onVehicleRegChanged);
  }

  void _onVehicleRegChanged() {
    final text = _vehicleRegController.text;
    final newKeyboard = getPlateKeyboardType(text);
    if (newKeyboard != _regKeyboardType) {
      setState(() => _regKeyboardType = newKeyboard);
    }
    final regPattern = RegExp(r'^[A-Z]{2}\s[0-9]{1,2}\s[A-Z]{1,3}\s[0-9]{4}$');
    if (_errorReg && regPattern.hasMatch(text.trim())) {
      setState(() => _errorReg = false);
    }
  }

  bool get _canAdvanceRegSegment {
    final text = _vehicleRegController.text;
    if (text.isEmpty || text.endsWith(' ')) return false;
    final parts = text.split(' ');
    // In district segment with 1 digit:
    if (parts.length == 2 && parts[1].length == 1) return true;
    // In series segment with 1 or 2 letters:
    if (parts.length == 3 && parts[2].isNotEmpty && parts[2].length <= 2) return true;
    return false;
  }

  void _advanceRegSegment() {
    final text = _vehicleRegController.text;
    if (!text.endsWith(' ')) {
      final updated = '$text ';
      _vehicleRegController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: updated.length),
      );
    }
  }

  void _onDriverStateChanged() {
    if (!mounted) return;

    final myId = widget.driverProfile?.userId ?? '108';
    final cleanMyId = myId.replaceAll('ST-', '').replaceAll('PK-', '').trim();

    final dispatchedVehicles = DriverService.instance.intakes.where((i) {
      if (i.status != 'dispatched' && i.status != 'dispatched_delayed') return false;
      if (i.assignedDriverId == null || i.assignedDriverId!.isEmpty) return true;
      final assignedClean = i.assignedDriverId!.replaceAll('ST-', '').replaceAll('PK-', '').trim();
      return assignedClean == cleanMyId || i.assignedDriverId == myId;
    }).toList();

    for (final vehicle in dispatchedVehicles) {
      if (!_handledDispatchedVehicles.contains(vehicle.id)) {
        _handledDispatchedVehicles.add(vehicle.id);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            DriverVehicleReturnScreen.showAsModal(
              context,
              vehicle: vehicle,
              driverProfile: widget.driverProfile,
            );
          }
        });
      }
    }

    setState(() {});
  }

  void _onSitesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DriverService.instance.removeListener(_onDriverStateChanged);
    SiteManager.instance.removeListener(_onSitesChanged);
    _vehicleRegController.removeListener(_onVehicleRegChanged);
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

  // Photo state & camera capture
  Future<void> _capturePhoto({ImageSource source = ImageSource.camera}) async {
    if (_isCapturingPhoto) return;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST') && widget.imagePicker == null) {
      setState(() {
        _hasPhoto = true;
        _photoFileName = 'IMG_INTAKE_${1000 + Random().nextInt(9000)}.JPG';
        _errorPhoto = false;
      });
      return;
    }
    setState(() => _isCapturingPhoto = true);
    try {
      final picker = widget.imagePicker ?? ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final now = DateTime.now();
        final timeStamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
        final name = pickedFile.name.isNotEmpty
            ? pickedFile.name
            : 'IMG_INTAKE_$timeStamp.JPG';
        setState(() {
          _hasPhoto = true;
          _photoFileName = name;
          _photoFilePath = pickedFile.path;
          _errorPhoto = false;
        });
      }
    } catch (e) {
      debugPrint('[DriverIntake] Error capturing photo: $e');
      if (!kIsWeb &&
          (Platform.environment.containsKey('FLUTTER_TEST') ||
              e.toString().contains('MissingPluginException'))) {
        setState(() {
          _hasPhoto = true;
          _photoFileName = 'IMG_INTAKE_${1000 + Random().nextInt(9000)}.JPG';
          _errorPhoto = false;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access camera: $e'),
            backgroundColor: kError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturingPhoto = false);
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _hasPhoto = false;
      _photoFileName = '';
      _photoFilePath = null;
    });
  }

  void _viewPhotoDialog() {
    if (!_hasPhoto) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: kPrimary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.camera_alt, color: kOnPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Vehicle Condition Photo',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kOnPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kOnPrimary, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            if (_photoFilePath != null &&
                !kIsWeb &&
                File(_photoFilePath!).existsSync())
              Image.file(
                File(_photoFilePath!),
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                color: kSurfaceContainerLow,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car, size: 64, color: kPrimary),
                      const SizedBox(height: 8),
                      Text(
                        _photoFileName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('Retake with Camera'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _capturePhoto(source: ImageSource.camera);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: kOnPrimary,
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Form Submission
  Future<void> _handleSubmit() async {
    final name = _customerNameController.text.trim();
    final phone = _customerPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final reg = _vehicleRegController.text.trim();
    final model = _vehicleModelController.text.trim();

    final regPattern = RegExp(r'^[A-Z]{2}\s[0-9]{1,2}\s[A-Z]{1,3}\s[0-9]{4}$');

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

    // Note: Do NOT update database or broadcast to screens on Next.
    // Intake is saved to database ONLY when driver clicks "Keys Accepted".

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
      _hasPhoto = widget.initialHasPhoto;
      _photoFileName = _hasPhoto ? 'IMG_INTAKE_${1000 + Random().nextInt(9000)}.JPG' : '';
      _photoFilePath = null;
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

  Widget _buildActiveDispatchedBanner() {
    final myId = widget.driverProfile?.userId ?? '108';
    final cleanMyId = myId.replaceAll('ST-', '').replaceAll('PK-', '').trim();

    final activeVehicles = DriverService.instance.intakes.where((i) {
      if (i.status != 'dispatched' && i.status != 'dispatched_delayed') return false;
      if (i.assignedDriverId == null || i.assignedDriverId!.isEmpty) return true;
      final assignedClean = i.assignedDriverId!.replaceAll('ST-', '').replaceAll('PK-', '').trim();
      return assignedClean == cleanMyId || i.assignedDriverId == myId;
    }).toList();

    if (activeVehicles.isEmpty) return const SizedBox.shrink();

    return Column(
      children: activeVehicles.map((v) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF00513A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00513A).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE RETURN: ${v.vehicleReg}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFAFEDD4),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.vehicleModel.isNotEmpty ? v.vehicleModel : "Vehicle"} • ${v.customerName}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  DriverVehicleReturnScreen.showAsModal(
                    context,
                    vehicle: v,
                    driverProfile: widget.driverProfile,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAFEDD4),
                  foregroundColor: const Color(0xFF00513A),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Open Popup',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
                  Row(
                    children: [
                      const ParkikoLogo(size: 32),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _openDriverProfileSheet,
                        borderRadius: BorderRadius.circular(24),
                        child: Row(
                          children: [
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
                ],
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
                      Row(
                        children: [
                          const ParkikoLogo(size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Parkiko Driver Desk',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
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
                  _buildActiveDispatchedBanner(),

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
                                  tooltip: 'Jump to Mobile Number',
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

                      // Mobile Number
                      Column(
                        key: _phoneKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Mobile Number', isRequired: true),
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
                                color: _errorReg ? kError : kOutlineVariant,
                                width: _errorReg ? 2 : 1,
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
                                    keyboardType: _regKeyboardType,
                                    textCapitalization: TextCapitalization.characters,
                                    inputFormatters: [
                                      _VehicleRegFormatter(),
                                    ],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: kOnSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'KL 07 BZ 4501',
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
                                      final regPattern = RegExp(r'^[A-Z]{2}\s[0-9]{1,2}\s[A-Z]{1,3}\s[0-9]{4}$');
                                      if (_errorReg && regPattern.hasMatch(val.trim())) {
                                        setState(() => _errorReg = false);
                                      }
                                    },
                                  ),
                                ),
                                if (_canAdvanceRegSegment)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: TextButton(
                                      key: const Key('btn_advance_reg_segment'),
                                      onPressed: _advanceRegSegment,
                                      style: TextButton.styleFrom(
                                        backgroundColor: kSecondaryContainer.withAlpha(120),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: Text(
                                        'Space ␣',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: kPrimary,
                                        ),
                                      ),
                                    ),
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
                              'Please enter a valid vehicle license plate (e.g., KL 07 BZ 4501).',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: kError),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            'Format: 2 Letters • 1-2 Digits • 1-3 Letters • 4 Digits (e.g., KL 07 BZ 4501)',
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
                                  GestureDetector(
                                    onTap: _viewPhotoDialog,
                                    child: Tooltip(
                                      message: 'Tap to view full photo',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 56,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: kSecondary.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: kSecondary.withOpacity(0.3)),
                                          ),
                                          child: _photoFilePath != null &&
                                                  !kIsWeb &&
                                                  File(_photoFilePath!).existsSync()
                                              ? Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image.file(
                                                      File(_photoFilePath!),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Positioned(
                                                      bottom: 2,
                                                      right: 2,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.6),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 10),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Stack(
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
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _viewPhotoDialog,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _photoFileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                  ),
                                  IconButton(
                                    key: const Key('btn_retake_photo'),
                                    icon: const Icon(Icons.camera_alt_outlined, color: kPrimary, size: 22),
                                    onPressed: () => _capturePhoto(source: ImageSource.camera),
                                    tooltip: 'Retake photo with camera',
                                  ),
                                  IconButton(
                                    key: const Key('btn_remove_photo'),
                                    icon: const Icon(Icons.delete_outline, color: kError, size: 22),
                                    onPressed: _removePhoto,
                                    tooltip: 'Remove photo',
                                  ),
                                ],
                              ),
                            )
                          else
                            // State 1: Photo Dropzone
                            InkWell(
                              key: const Key('photo_dropzone'),
                              onTap: () => _capturePhoto(source: ImageSource.camera),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
                                      child: _isCapturingPhoto
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: kPrimary,
                                              ),
                                            )
                                          : const Icon(Icons.photo_camera, color: kOnSecondaryContainer, size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Take Photo of Car',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: kOnSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap to open camera and capture car condition',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: kOutline,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          key: const Key('btn_open_camera'),
                                          onPressed: () => _capturePhoto(source: ImageSource.camera),
                                          icon: const Icon(Icons.camera_alt, size: 15),
                                          label: Text(
                                            'Open Camera',
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPrimary,
                                            foregroundColor: kOnPrimary,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          key: const Key('btn_open_gallery'),
                                          onPressed: () => _capturePhoto(source: ImageSource.gallery),
                                          icon: const Icon(Icons.photo_library_outlined, size: 15),
                                          label: Text(
                                            'Gallery',
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: kSecondary,
                                            side: BorderSide(color: kOutlineVariant),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
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
