import 'package:flutter/material.dart';
import '../models/assistant_manager_models.dart';

/// Card displaying a vehicle parked by a driver, ready for customer retrieval.
class ParkedVehicleCard extends StatelessWidget {
  final ParkedVehicleItem parked;
  final ValueChanged<ParkedVehicleItem> onTriggerRetrieval;

  const ParkedVehicleCard({
    super.key,
    required this.parked,
    required this.onTriggerRetrieval,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A).withAlpha(220)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Badges & Parked By Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // PARKED READY
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle_outline,
                            size: 12,
                            color: Color(0xFFB45309),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PARKED READY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // EV Charging (Optional)
                    if (parked.isEv)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.bolt,
                              size: 11,
                              color: Color(0xFF065F46),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'EV Charging',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Payment Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: parked.isPaid
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: parked.isPaid
                            ? null
                            : Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            parked.isPaid ? Icons.check : Icons.schedule,
                            size: 11,
                            color: parked.isPaid
                                ? const Color(0xFF065F46)
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            parked.paymentText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: parked.isPaid
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Parked by PK-xxx (time)
              Text(
                'By ${parked.parkedBy} (${parked.parkedAgo})',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78350F),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Vehicle Name & Plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  parked.vehicleName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF141E1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFFDE68A).withAlpha(160),
                  ),
                ),
                child: Text(
                  parked.plateNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF451A03),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Guest Name
          Text(
            'Guest: ${parked.guestName}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6F7A73),
            ),
          ),

          const SizedBox(height: 10),

          // Slot Position & Safe Box Grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB).withAlpha(180),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEF3C7)),
            ),
            child: Row(
              children: [
                // Column 1: Slot Position
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          parked.isEv
                              ? Icons.electric_car_rounded
                              : Icons.local_parking_rounded,
                          size: 15,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Slot Position',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              parked.slotPosition,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF451A03),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFFFDE68A),
                ),
                const SizedBox(width: 8),

                // Column 2: Vault Key Safe
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vault Key Safe',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              parked.vaultBox,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF451A03),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Trigger Retrieval Action Button
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => onTriggerRetrieval(parked),
              icon: const Icon(Icons.output_rounded, size: 16),
              label: const Text(
                'Trigger Retrieval',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF3C7),
                foregroundColor: const Color(0xFF78350F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
