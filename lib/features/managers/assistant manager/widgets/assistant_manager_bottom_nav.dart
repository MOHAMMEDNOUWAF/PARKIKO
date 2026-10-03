import 'package:flutter/material.dart';

/// Docked bottom navigation bar for switching between retrieval queue and shift history.
class AssistantManagerBottomNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final int newHistoryBadgeCount;

  const AssistantManagerBottomNav({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
    required this.newHistoryBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1FCF5).withAlpha(245),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFBEC9C2).withAlpha(80),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEBF6EF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFBEC9C2).withAlpha(80),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              // Tab 1: Retrieval & Dispatch
              Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(0),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: activeIndex == 0
                          ? const Color(0xFF00513A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: activeIndex == 0
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00513A).withAlpha(40),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          size: 16,
                          color: activeIndex == 0
                              ? Colors.white
                              : const Color(0xFF6F7A73),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Retrieval & Dispatch',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: activeIndex == 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: activeIndex == 0
                                ? Colors.white
                                : const Color(0xFF3F4944),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab 2: History
              Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(1),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: activeIndex == 1
                          ? const Color(0xFF00513A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: activeIndex == 1
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00513A).withAlpha(40),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: activeIndex == 1
                              ? Colors.white
                              : const Color(0xFF6F7A73),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: activeIndex == 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: activeIndex == 1
                                ? Colors.white
                                : const Color(0xFF3F4944),
                          ),
                        ),
                        if (newHistoryBadgeCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: activeIndex == 1
                                  ? Colors.white
                                  : const Color(0xFF00513A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+$newHistoryBadgeCount',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: activeIndex == 1
                                    ? const Color(0xFF00513A)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
