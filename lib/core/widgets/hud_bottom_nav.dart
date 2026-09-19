import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HudBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HudBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Operations'),
      _NavItem(icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Staff'),
      _NavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Payments'),
      _NavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More', hasDotBadge: true),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0x4DBEC9C2), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F17211D),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(9999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 16 : 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.secondaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                            size: 22,
                          ),
                          if (item.hasDotBadge && !isActive)
                            Positioned(
                              top: -1,
                              right: -2,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool hasDotBadge;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.hasDotBadge = false,
  });
}
