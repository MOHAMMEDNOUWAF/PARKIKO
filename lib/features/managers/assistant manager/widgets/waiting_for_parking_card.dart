import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../drivers/models/vehicle_intake_model.dart';

/// Card displaying a vehicle intake waiting for bay allocation or parked.
class WaitingForParkingCard extends StatelessWidget {
  final VehicleIntakeModel intake;
  final ValueChanged<VehicleIntakeModel> onAssignBay;

  const WaitingForParkingCard({
    super.key,
    required this.intake,
    required this.onAssignBay,
  });

  @override
  Widget build(BuildContext context) {
    final isParked = intake.status == 'parked';
    final digits = intake.id.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanTag = intake.keyTag ??
        '#KT-${digits.length >= 3 ? digits.substring(digits.length - 3) : "101"}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isParked ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isParked ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Accent Bar
            Container(
              width: 5,
              color: isParked ? const Color(0xFF00513A) : const Color(0xFFF59E0B),
            ),
            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Vehicle Model & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            intake.vehicleModel.isNotEmpty
                                ? intake.vehicleModel
                                : 'Valet Vehicle',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF141E1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isParked
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isParked
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isParked
                                    ? Icons.check_circle_rounded
                                    : Icons.hourglass_top_rounded,
                                size: 10,
                                color: isParked
                                    ? const Color(0xFF00513A)
                                    : const Color(0xFFB45309),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isParked ? 'PARKED' : 'WAITING FOR PARKING',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isParked
                                      ? const Color(0xFF00513A)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 2: Reg Plate & Key Tag & Intake Time
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141E1A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            intake.vehicleReg,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFAFEDD4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.vpn_key_rounded,
                                size: 11,
                                color: Color(0xFF00513A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cleanTag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF00513A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Intake: ${DateFormat('hh:mm a').format(intake.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 3: Customer & Intake Driver info
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF6F7A73)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${intake.customerName} • ${intake.customerPhone}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3F4944),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF6F7A73)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Intake Driver: ${intake.driverName} (${intake.driverId})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6F7A73),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 4: Action Button or Parked Indicator
                    Align(
                      alignment: Alignment.centerRight,
                      child: isParked
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle, size: 14, color: Color(0xFF00513A)),
                                  SizedBox(width: 5),
                                  Text(
                                    'Parked by Driver',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00513A),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton.icon(
                              key: Key('btn_assign_bay_${intake.id}'),
                              onPressed: () => onAssignBay(intake),
                              icon: const Icon(Icons.local_parking_rounded, size: 14),
                              label: const Text(
                                'Assign Bay & Park',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00513A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    );
  }
}
