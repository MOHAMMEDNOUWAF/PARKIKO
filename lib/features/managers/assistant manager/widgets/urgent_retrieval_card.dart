import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/assistant_manager_models.dart';

/// Card displaying an urgent customer retrieval request with pulsing alert,
/// quick runner assignment, and dispatch action.
class UrgentRetrievalCard extends StatelessWidget {
  final UrgentRetrievalItem item;
  final Animation<double> pulseAnimation;
  final List<QuickRunnerChipData> sameSiteChips;
  final String runnerStatusText;
  final ValueChanged<String> onRunnerChanged;
  final ValueChanged<String> onQuickRunnerSet;
  final VoidCallback onClearRunner;
  final VoidCallback onDispatch;
  final VoidCallback onAutoDispatch;

  const UrgentRetrievalCard({
    super.key,
    required this.item,
    required this.pulseAnimation,
    required this.sameSiteChips,
    required this.runnerStatusText,
    required this.onRunnerChanged,
    required this.onQuickRunnerSet,
    required this.onClearRunner,
    required this.onDispatch,
    required this.onAutoDispatch,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        final glowAlpha = (30 + 35 * pulseAnimation.value).toInt();
        final borderAlpha = (100 + 155 * pulseAnimation.value).toInt();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.white,
              const Color(0xFFFFF9F9),
              pulseAnimation.value,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFBA1A1A).withAlpha(borderAlpha),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBA1A1A).withAlpha(glowAlpha),
                blurRadius: 10 * pulseAnimation.value,
                spreadRadius: 1 * pulseAnimation.value,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Source Badge, Order #, Payment Badge, Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Source badge (WhatsApp / Curbside / Bay Call)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.sourceBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.sourceIcon, size: 12, color: item.sourceTextColor),
                          const SizedBox(width: 4),
                          Text(
                            item.sourceTag,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: item.sourceTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Order Number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.orderNumber,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                          color: Color(0xFF93000A),
                        ),
                      ),
                    ),

                    // Payment Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.isPaid
                            ? const Color(0xFFAFEDD4)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: item.isPaid
                            ? null
                            : Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.isPaid
                                ? Icons.check_circle_rounded
                                : Icons.pending_outlined,
                            size: 11,
                            color: item.isPaid
                                ? const Color(0xFF00513A)
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.paymentText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: item.isPaid
                                  ? const Color(0xFF00513A)
                                  : const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Timer Pill
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFBA1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      item.timerText,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Vehicle Name & License Plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  item.vehicleName,
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
                  color: const Color(0xFFE5F1EA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.plateNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141E1A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Guest Name
          Row(
            children: [
              const Text(
                'Guest: ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6F7A73),
                ),
              ),
              Text(
                item.guestName,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141E1A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Assign Runner Module
          if (item.isAutoRunner)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assign Runner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141E1A),
                      ),
                    ),
                    Text(
                      item.runnerStatusText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAutoDispatch,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text(
                      'Dispatch Auto-Runner PK-108',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00513A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assign Runner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141E1A),
                      ),
                    ),
                    Text(
                      runnerStatusText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00513A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Fixed Prefix Input Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBEC9C2).withAlpha(120),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Fixed 'PK-' Prefix Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5F1EA),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(11),
                          ),
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFFBEC9C2),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: const Text(
                          'PK-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3F4944),
                          ),
                        ),
                      ),

                      // Numeric TextField
                      Expanded(
                        child: TextField(
                          controller: item.runnerController,
                          focusNode: item.focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: onRunnerChanged,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF141E1A),
                          ),
                          decoration: InputDecoration(
                            hintText: item.runnerPlaceholder,
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBEC9C2),
                            ),
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),

                      // Clear Button (X)
                      if (item.runnerController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: const Color(0xFF6F7A73),
                          onPressed: onClearRunner,
                        ),
                    ],
                  ),
                ),

                if (sameSiteChips.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Quick:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6F7A73),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: sameSiteChips.map((chip) {
                              final isSelected =
                                  item.runnerController.text.trim() == chip.code;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () => onQuickRunnerSet(chip.code),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFAFEDD4)
                                          : const Color(0xFFDFEBE4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      chip.label,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF00513A)
                                            : const Color(0xFF141E1A),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                // Dispatch Action Button
                _DispatchButton(
                  runnerText: item.runnerController.text.trim(),
                  onPressed: onDispatch,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DispatchButton extends StatelessWidget {
  final String runnerText;
  final VoidCallback onPressed;

  const _DispatchButton({
    required this.runnerText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = runnerText.isNotEmpty;

    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? const Color(0xFF00513A)
              : const Color(0xFFE5F1EA),
          foregroundColor: isEnabled ? Colors.white : const Color(0xFF6F7A73),
          disabledBackgroundColor: const Color(0xFFE5F1EA),
          disabledForegroundColor: const Color(0xFF6F7A73),
          elevation: isEnabled ? 1 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_rounded,
              size: 16,
              color: isEnabled ? Colors.white : const Color(0xFF6F7A73),
            ),
            const SizedBox(width: 6),
            Text(
              isEnabled
                  ? 'Dispatch Runner PK-$runnerText'
                  : 'Enter Runner to Dispatch',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.white : const Color(0xFF6F7A73),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
