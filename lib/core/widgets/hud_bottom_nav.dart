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
      _NavItem(icon: Icons.local_parking, activeIcon: Icons.local_parking, label: 'Home'),
      _NavItem(icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car, label: 'Ops'),
      _NavItem(icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Staff'),
      _NavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Payments'),
      _NavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.zero,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.secondaryContainer.withAlpha(40) : Colors.transparent,
                            borderRadius: BorderRadius.zero,
                            border: isActive
                                ? Border.all(color: AppColors.secondaryContainer.withAlpha(120), width: 1)
                                : null,
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive ? AppColors.secondaryContainer : AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: isActive ? AppColors.secondaryContainer : AppColors.outline,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
