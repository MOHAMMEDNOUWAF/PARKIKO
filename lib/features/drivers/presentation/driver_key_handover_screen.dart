// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/widgets/parkiko_logo.dart';
import '../../auth/models/user_profile.dart';
import '../../admin/operations/services/key_record_repository.dart';
import '../../admin/operations/services/ticket_repository.dart';
import '../models/vehicle_intake_model.dart';
import '../services/driver_service.dart';

// Stitch Mint/Emerald design system color palette
const Color kPrimary = Color(0xFF00513A);
const Color kPrimaryContainer = Color(0xFF0F6B4F);
const Color kOnPrimary = Color(0xFFFFFFFF);
const Color kSecondary = Color(0xFF2D6955);
const Color kSecondaryContainer = Color(0xFFAFEDD4);
const Color kOnSecondaryContainer = Color(0xFF326D59);
const Color kBackground = Color(0xFFF1FCF5);
const Color kSurfaceContainerLowest = Color(0xFFFFFFFF);
const Color kSurfaceContainerLow = Color(0xFFEBF6EF);
const Color kSurfaceContainer = Color(0xFFE5F1EA);
const Color kOnSurface = Color(0xFF141E1A);
const Color kOnSurfaceVariant = Color(0xFF3F4944);
const Color kOutlineVariant = Color(0xFFBEC9C2);
const Color kInverseSurface = Color(0xFF28332E);
const Color kSurfaceBright = Color(0xFFF1FCF5);
const Color kError = Color(0xFFBA1A1A);
const Color kErrorContainer = Color(0xFFFFDAD6);

/// Second-step screen after vehicle intake: Slot & Key Handover.
/// Faithfully reproduces the web design in `driver_key_handover.html`.
class DriverKeyHandoverScreen extends StatefulWidget {
  final VehicleIntakeModel intake;
  final UserProfile? driverProfile;
  final String ticketNumber;
  final VoidCallback? onCompleted;

  const DriverKeyHandoverScreen({
    super.key,
    required this.intake,
    required this.ticketNumber,
    this.driverProfile,
    this.onCompleted,
  });

  @override
  State<DriverKeyHandoverScreen> createState() =>
      _DriverKeyHandoverScreenState();
}

class _DriverKeyHandoverScreenState extends State<DriverKeyHandoverScreen> {
  bool _isKeysAccepted = false;
  bool _showBanner = true;
  bool _isFinalizing = false;
  bool _isComplete = false;
  bool _tokenCopied = false;

  late String _keyTag;

  @override
  void initState() {
    super.initState();
    final digits = widget.intake.id.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanDigits = digits.length >= 3
        ? digits.substring(digits.length - 3)
        : (100 + widget.intake.customerPhone.hashCode.abs() % 900).toString();
    _keyTag = '#KT-$cleanDigits';
  }

  void _toggleKeyCustody() {
    setState(() {
      _isKeysAccepted = !_isKeysAccepted;
    });

    if (_isKeysAccepted) {
      _logKeyCustodyRecord(KeyStatus.keyReceived);
      _showToast(
        title: 'Physical Keys Tagged & Custody Recorded',
        body: 'Key $_keyTag confirmed accepted by driver. Ready for vehicle drop-off.',
        isSuccess: true,
      );
    }
  }

  Future<void> _logKeyCustodyRecord(KeyStatus status) async {
    try {
      await KeyRecordRepository.instance.updateKeyStatus(
        ticketId: widget.intake.id,
        keyTag: _keyTag,
        status: status,
        storageSlot: 'Valet Porch Custody',
        handledBy: widget.driverProfile?.userId ?? widget.intake.driverId,
      );
    } catch (e) {
      debugPrint('[DriverKeyHandover] Key record error: $e');
    }
  }

  void _showToast({
    required String title,
    required String body,
    bool isSuccess = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSuccess ? kPrimary.withAlpha(80) : kError.withAlpha(80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSuccess ? kSecondaryContainer : kErrorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.info_outline,
                  color: isSuccess ? kPrimary : kError,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: kOnSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCompleteIntake() async {
    if (!_isKeysAccepted) {
      _showToast(
        title: 'Physical Keys Required',
        body: 'Please tap "Keys Accepted" to verify possession of key fob $_keyTag before finalizing intake.',
      );
      return;
    }

    setState(() {
      _isFinalizing = true;
    });

    try {
      // 1. Confirm ticket state to PARKED
      await TicketRepository.instance.confirmVehicleParked(
        ticketId: widget.intake.id,
        valetId: widget.driverProfile?.userId ?? widget.intake.driverId,
        locationSlot: 'Valet Porch Intake',
      );

      // 2. Log final key custody
      await _logKeyCustodyRecord(KeyStatus.keyStored);
    } catch (e) {
      debugPrint('[DriverKeyHandover] Complete intake error: $e');
    }

    if (!mounted) return;

    setState(() {
      _isFinalizing = false;
      _isComplete = true;
    });
  }

  Future<void> _confirmCancelIntake() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel / Delete Intake?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: kOnSurface,
            fontSize: 17,
          ),
        ),
        content: Text(
          'This will cancel ticket ${widget.ticketNumber} for vehicle ${widget.intake.vehicleReg}. This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: kOnSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Intake',
              style: GoogleFonts.inter(
                color: kOnSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kError,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Intake'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await DriverService.instance.deleteIntake(widget.intake.id);
        if (FirebaseService.isInitialized) {
          await FirebaseFirestore.instance
              .collection('tickets')
              .doc(widget.intake.id)
              .delete();
        }
      } catch (e) {
        debugPrint('[DriverKeyHandover] delete ticket: $e');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  String _formatPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    if (phone.startsWith('+91')) {
      return phone;
    }
    return '+91 $phone';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kOnSurface, size: 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Row(
          children: [
            const ParkikoLogo(size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vehicle Slot & Key Handover',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kOnSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _isComplete ? _buildSuccessView() : _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Dispatch Banner
          if (_showBanner) ...[
            _buildDispatchBanner(),
            const SizedBox(height: 12),
          ],

          // Page Headline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Slot & Key Handover',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kOnSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Verify assigned bay and accept physical key',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: kOnSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Bill Token & Vehicle Summary Card
          _buildTokenSummaryCard(),
          const SizedBox(height: 14),

          // 2. Key Custody & Handover Card
          _buildKeyCustodyCard(),
          const SizedBox(height: 18),

          // 3. Actions (Parked & Complete Intake, Hint, Cancel)
          _buildActionsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDispatchBanner() {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withAlpha(40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(color: kPrimary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: kSecondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cell_tower, color: kPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kSecondaryContainer.withAlpha(180),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'LIVE BROADCAST',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: kPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Synced',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: kOnSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Dispatched to Manager & Assistant Manager Deck',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kOnSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vehicle details and Key $_keyTag live on supervisor dashboard for bay monitoring, runner dispatch & key custody.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: kOnSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  icon: const Icon(Icons.close, size: 16, color: kOnSurfaceVariant),
                  onPressed: () {
                    setState(() {
                      _showBanner = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant.withAlpha(180)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Token ID + Copy Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GENERATED BILL TOKEN',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: kOnSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.ticketNumber,
                            key: const Key('display_ticket_number'),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          key: const Key('btn_copy_token'),
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: widget.ticketNumber));
                            setState(() {
                              _tokenCopied = true;
                            });
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) setState(() => _tokenCopied = false);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _tokenCopied ? Icons.check : Icons.content_copy,
                              size: 16,
                              color: _tokenCopied ? const Color(0xFF10B981) : kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSecondaryContainer.withAlpha(140),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Prepaid FastPass',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: kOutlineVariant),
          const SizedBox(height: 12),

          // Vehicle Badge & Model
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kInverseSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.intake.vehicleReg,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kSurfaceBright,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.intake.vehicleModel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kOnSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer Name & Phone
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: kOnSurfaceVariant),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.intake.customerName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call, size: 14, color: kOnSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatPhone(widget.intake.customerPhone),
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kOnSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Intake Time Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: kPrimary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Intake Time: Today, ${TimeOfDay.fromDateTime(widget.intake.createdAt).format(context)} IST',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: kOnSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.intake.siteName.replaceAll(' • Valet Desk', '').trim(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCustodyCard() {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant.withAlpha(180)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Key Custody Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key, color: kPrimary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'KEY CUSTODY & HANDOVER',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: kOnSurface,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isKeysAccepted
                      ? const Color(0xFFD1FAE5)
                      : kSecondaryContainer.withAlpha(150),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isKeysAccepted
                            ? const Color(0xFF059669)
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isKeysAccepted ? 'Keys Secured' : 'Active Handover',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isKeysAccepted
                            ? const Color(0xFF065F46)
                            : kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Key Status Interactive Toggle Button
          InkWell(
            key: const Key('key_status_toggle'),
            onTap: _toggleKeyCustody,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: _isKeysAccepted ? Colors.white : kPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kPrimary,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withAlpha(_isKeysAccepted ? 20 : 50),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isKeysAccepted ? Icons.check_circle : Icons.vpn_key_outlined,
                    color: _isKeysAccepted ? kPrimary : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isKeysAccepted
                          ? 'Keys Accepted (In Custody)'
                          : 'Tap to Accept Key ($_keyTag)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isKeysAccepted ? kPrimary : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sub-item 1: WhatsApp Receipt
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kOutlineVariant.withAlpha(120)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat, color: Color(0xFF065F46), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'WhatsApp Receipt & E-Pass',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kOnSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SENT',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Delivered to ${_formatPhone(widget.intake.customerPhone)} • Token ${widget.ticketNumber.replaceAll('BILL #', '')}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: kOnSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified, color: kPrimary, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sub-item 2: Manager Deck Sync
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kOutlineVariant.withAlpha(120)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: kSecondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sensors, color: kPrimary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Manager & Asst. Mgr Deck',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kOnSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LIVE',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Real-time bay monitoring, runner alert & custody',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: kOnSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Synced',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Prominent Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            key: const Key('btn_complete_intake'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isKeysAccepted ? kPrimary : kPrimary.withAlpha(120),
              foregroundColor: Colors.white,
              elevation: _isKeysAccepted ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isFinalizing ? null : _handleCompleteIntake,
            child: _isFinalizing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Finalizing & Syncing Deck...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isKeysAccepted ? Icons.local_parking : Icons.lock,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Parked & Complete Intake',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Hint Text below button
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isKeysAccepted ? Icons.check_circle : Icons.info_outline,
              size: 13,
              color: _isKeysAccepted ? kPrimary : kError,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _isKeysAccepted
                    ? 'Keys received. You may now complete intake once parked'
                    : 'Please accept physical keys to unlock intake completion',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _isKeysAccepted ? kPrimary : kError,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cancel / Delete Intake Button
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            key: const Key('btn_delete_intake'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kError,
              side: BorderSide(color: kError.withAlpha(80)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _confirmCancelIntake,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(
              'Cancel / Delete Intake',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF059669),
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: kSecondaryContainer.withAlpha(160),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'INTAKE SUCCESSFUL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: kPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intake Complete & Parked!',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: kOnSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Token ${widget.ticketNumber} parked. Physical key $_keyTag logged in custody.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: kOnSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Duty Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kOutlineVariant.withAlpha(140)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Driver Duty',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: kOnSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Available for Next Car',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: kOutlineVariant),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Live Deck Status',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: kOnSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Supervisor Notified',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kOnSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Back to Driver Home CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                key: const Key('btn_back_to_driver_home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  widget.onCompleted?.call();
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.home, size: 20),
                label: Text(
                  'Back to Driver Home',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
