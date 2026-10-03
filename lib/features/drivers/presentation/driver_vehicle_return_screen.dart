// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/models/user_profile.dart';
import '../models/vehicle_intake_model.dart';
import '../services/driver_service.dart';

class DriverVehicleReturnScreen extends StatefulWidget {
  final VehicleIntakeModel vehicle;
  final UserProfile? driverProfile;
  final bool isModal;

  const DriverVehicleReturnScreen({
    super.key,
    required this.vehicle,
    this.driverProfile,
    this.isModal = false,
  });

  /// Presents the Driver Vehicle Return Screen as a modal bottom sheet pop-up.
  /// The sheet is non-dismissible — the driver must complete the handover.
  static Future<void> showAsModal(
    BuildContext context, {
    required VehicleIntakeModel vehicle,
    UserProfile? driverProfile,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,   // ← cannot swipe-dismiss
      enableDrag: false,      // ← cannot drag to close
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: false,        // ← back button blocked
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.88,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDED),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DriverVehicleReturnScreen(
              vehicle: vehicle,
              driverProfile: driverProfile,
              isModal: true,
            ),
          ),
        ),
      ),
    );
  }

  /// Presents the Driver Vehicle Return Screen as a centered popup dialog.
  /// The dialog is non-dismissible — the driver must complete the handover.
  static Future<void> showAsDialog(
    BuildContext context, {
    required VehicleIntakeModel vehicle,
    UserProfile? driverProfile,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // ← tapping outside does nothing
      builder: (ctx) => PopScope(
        canPop: false,           // ← back button blocked
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
            child: DriverVehicleReturnScreen(
              vehicle: vehicle,
              driverProfile: driverProfile,
              isModal: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<DriverVehicleReturnScreen> createState() => _DriverVehicleReturnScreenState();
}

class _DriverVehicleReturnScreenState extends State<DriverVehicleReturnScreen> {
  bool _keyReceived = false;
  bool _vehicleTaken = false;
  bool _isSuccess = false;
  bool _isReleasing = false;
  String? _delayReason;

  @override
  void initState() {
    super.initState();
    // Trigger alert sound + vibration pattern when the popup appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Play system alert sound
      SystemSound.play(SystemSoundType.alert);
      // Strong vibration: long buzz → short pause → short buzz
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) HapticFeedback.heavyImpact();
      });
    });
  }

  String get _driverDisplayName {
    if (widget.driverProfile?.name.trim().isNotEmpty == true) {
      return widget.driverProfile!.name;
    }
    if (widget.vehicle.assignedDriverName?.isNotEmpty == true) {
      return widget.vehicle.assignedDriverName!;
    }
    if (widget.vehicle.driverName.isNotEmpty) {
      return widget.vehicle.driverName;
    }
    return 'Rahul V.';
  }

  String get _driverStaffId {
    if (widget.driverProfile?.userId.trim().isNotEmpty == true) {
      return widget.driverProfile!.userId;
    }
    if (widget.vehicle.assignedDriverId?.isNotEmpty == true) {
      return widget.vehicle.assignedDriverId!;
    }
    if (widget.vehicle.driverId.isNotEmpty) {
      return widget.vehicle.driverId;
    }
    return 'PK-108';
  }

  void _triggerHandoverSuccess() {
    setState(() {
      _isReleasing = true;
    });

    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() {
          _isReleasing = false;
          _isSuccess = true;
        });

        DriverService.instance.updateIntakeStatus(widget.vehicle.id, 'completed');

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  void _openReportDelayDialog() {
    final reasons = [
      'Customer Not at Porch / No Answer',
      'Porch Traffic Congestion',
      'Key Retrieval Delay',
      'Vehicle Security Check Required',
      'Customer Request Delay',
    ];

    String selectedReason = reasons.first;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Report Handover Delay',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF141E1A),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select the reason for delay in vehicle return to porch:',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3F4944)),
                  ),
                  const SizedBox(height: 12),
                  ...reasons.map((r) => RadioListTile<String>(
                        value: r,
                        groupValue: selectedReason,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF00513A),
                        title: Text(
                          r,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF141E1A),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedReason = val);
                          }
                        },
                      )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Additional notes (optional)...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6F7A73)),
                      filled: true,
                      fillColor: const Color(0xFFEBF6EF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6F7A73),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final note = noteController.text.trim();
                    final fullReason = note.isNotEmpty ? '$selectedReason: $note' : selectedReason;

                    setState(() {
                      _delayReason = fullReason;
                    });

                    DriverService.instance.updateIntakeStatus(
                      widget.vehicle.id,
                      'dispatched_delayed',
                      extraData: {
                        'delayReason': fullReason,
                        'delayedAt': DateTime.now().toIso8601String(),
                      },
                    );

                    Navigator.of(ctx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Delay reported: $selectedReason'),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFFD97706),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00513A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Report Delay',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDED),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Urgent alert banner at the top
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFBA1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ACTION REQUIRED — Complete vehicle handover to proceed',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildVehicleCard(),
              const SizedBox(height: 14),
              _buildVerificationChecklist(),
              const SizedBox(height: 16),
              if (_isSuccess) _buildSuccessBanner(),
              if (!_isSuccess) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFBA1A1A),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      // No leading button at all when shown as modal — driver cannot go back.
      leading: widget.isModal
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          color: const Color(0xFF93000A),
          height: 2,
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VEHICLE RETURN — ACTION REQUIRED',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$_driverDisplayName • $_driverStaffId',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    final v = widget.vehicle;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBA1A1A).withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBA1A1A).withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F1EA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            v.id.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3F4944),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.pin_drop, size: 13, color: Color(0xFF2D6955)),
                            const SizedBox(width: 2),
                            Text(
                              v.siteName.toLowerCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D6955),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.vehicleModel.isNotEmpty ? v.vehicleModel : 'Unknown Vehicle',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF141E1A),
                      ),
                    ),
                    Text(
                      v.keyTag != null && v.keyTag!.isNotEmpty ? 'Key Tag: ${v.keyTag}' : 'Valet Bay Inspection Cleared',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF3F4944),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDAE5DE).withAlpha(153),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF141E1A).withAlpha(204), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'IND',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00513A),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      v.vehicleReg,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF141E1A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE5F1EA), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFAFEDD4),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      v.customerName.isNotEmpty ? v.customerName.substring(0, 1).toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF326D59),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.customerName.isNotEmpty ? v.customerName : 'Unknown Customer',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF141E1A),
                        ),
                      ),
                      Text(
                        v.customerPhone.isNotEmpty ? v.customerPhone : 'No Phone',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3F4944),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (v.customerPhone.isNotEmpty)
                InkWell(
                  onTap: () async {
                    final url = Uri.parse('tel:${v.customerPhone}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00513A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.call, size: 15, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Call Client',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationChecklist() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBA1A1A).withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBA1A1A).withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Handover Verification',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF141E1A),
                  letterSpacing: 0.5,
                ),
              ),
              _buildPaymentTag(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCheckButton(
                  title: 'Key Handed Over',
                  subtitle: 'Key fob transferred',
                  icon: Icons.vpn_key,
                  isActive: _keyReceived,
                  onTap: () => setState(() => _keyReceived = !_keyReceived),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCheckButton(
                  title: 'Vehicle Received',
                  subtitle: 'Client accepted car',
                  icon: Icons.directions_car,
                  isActive: _vehicleTaken,
                  onTap: () => setState(() => _vehicleTaken = !_vehicleTaken),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTag() {
    final v = widget.vehicle;
    final amountStr = v.paymentAmount != null ? '₹${v.paymentAmount!.toStringAsFixed(0)}' : '₹250';
    final isPaid = v.isPaid;
    final modeStr = v.paymentMode.isNotEmpty ? v.paymentMode.toUpperCase() : 'UPI';
    final label = isPaid ? '$amountStr Paid ($modeStr)' : '$amountStr Unpaid (Collect)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFAFEDD4).withAlpha(150) : const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? const Color(0xFF00513A).withAlpha(80) : const Color(0xFFBA1A1A).withAlpha(100),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.error_outline,
            size: 13,
            color: isPaid ? const Color(0xFF00513A) : const Color(0xFFBA1A1A),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isPaid ? const Color(0xFF00513A) : const Color(0xFFBA1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSuccess || _isReleasing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFAFEDD4).withAlpha(180) : const Color(0xFFEBF6EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF00513A) : const Color(0xFFBEC9C2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFAFEDD4) : const Color(0xFFDAE5DE),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: isActive ? const Color(0xFF00513A) : const Color(0xFF3F4944),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF141E1A),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF3F4944),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 15,
                  color: isActive ? const Color(0xFF00513A) : const Color(0xFF6F7A73),
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Confirmed' : 'Tap to Confirm',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? const Color(0xFF00513A) : const Color(0xFF6F7A73),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canConfirm = _keyReceived && _vehicleTaken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_delayReason != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delay Reported: $_delayReason',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        ElevatedButton(
          onPressed: canConfirm && !_isReleasing ? _triggerHandoverSuccess : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBA1A1A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFBA1A1A).withAlpha(120),
            disabledForegroundColor: Colors.white.withAlpha(180),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isReleasing)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.task_alt, size: 19),
              const SizedBox(width: 8),
              Text(
                _isReleasing ? 'Releasing Bay & Finalizing...' : 'Confirm Return & Handover',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isReleasing ? null : _openReportDelayDialog,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6F7A73),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(
            'Customer Not at Porch / Report Delay',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006D2D),
            disabledBackgroundColor: const Color(0xFF006D2D),
            disabledForegroundColor: const Color(0xFF74F18D),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 19),
              const SizedBox(width: 8),
              Text(
                'Vehicle Successfully Handed Over',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            border: Border.all(color: const Color(0xFF006D2D).withAlpha(80)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 18, color: Color(0xFF006D2D)),
                  const SizedBox(width: 6),
                  Text(
                    'Return Confirmed & Bay Released!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006D2D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ticket #${widget.vehicle.id.toUpperCase()} completed. Bay re-allocated to intake queue.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
