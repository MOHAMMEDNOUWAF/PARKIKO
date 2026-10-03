import 'package:flutter/material.dart';
import '../models/assistant_manager_models.dart';

/// Card displaying a dispatched or completed retrieval order in history log.
class HistoryDispatchCard extends StatelessWidget {
  final HistoryDispatchItem hist;

  const HistoryDispatchCard({
    super.key,
    required this.hist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hist.isJustDispatched
              ? const Color(0xFF00513A).withAlpha(150)
              : const Color(0xFFBEC9C2).withAlpha(120),
          width: hist.isJustDispatched ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Status badge, Order #, Payment, Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAFEDD4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.done_all,
                          size: 11,
                          color: Color(0xFF00513A),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hist.isJustDispatched ? 'Just Dispatched' : 'Dispatched',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00513A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAE5DE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hist.orderNumber,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check,
                          size: 10,
                          color: Color(0xFF065F46),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hist.paymentText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                hist.timeLabel,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00513A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 2: Vehicle & Plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hist.vehicleName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF141E1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F1EA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hist.plateNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141E1A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Row 3: Guest Name
          Text(
            'Guest: ${hist.guestName}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6F7A73),
            ),
          ),

          const SizedBox(height: 10),

          // Row 4: Runner Attribution & Handover status
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5F1EA)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: Color(0xFF00513A),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Runner: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6F7A73),
                      ),
                    ),
                    Text(
                      hist.runnerLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: Color(0xFF065F46),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Handover: ${hist.handoverTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
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
}
