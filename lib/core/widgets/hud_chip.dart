import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum OperationalStatus {
  available,  // Phosphor Green
  occupied,   // Radiant Crimson
  inTransit,  // Radiant Crimson / Amber
  queue,      // Radiant Amber
  offline,    // Muted Slate
  custom,
}

enum HudRole {
  admin,
  manager,
  staff,
  valet,
}

class HudStatusChip extends StatelessWidget {
  final String label;
  final OperationalStatus status;
  final Color? customColor;
  final bool isUppercase;

  const HudStatusChip({
    super.key,
    required this.label,
    this.status = OperationalStatus.available,
    this.customColor,
    this.isUppercase = true,
  });

  Color _getStatusColor() {
    if (customColor != null) return customColor!;
    switch (status) {
      case OperationalStatus.available:
        return AppColors.statusAvailable;
      case OperationalStatus.occupied:
        return AppColors.statusOccupied;
      case OperationalStatus.inTransit:
        return AppColors.statusQueue;
      case OperationalStatus.queue:
        return AppColors.statusQueue;
      case OperationalStatus.offline:
        return AppColors.statusOffline;
      case OperationalStatus.custom:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isUppercase ? label.toUpperCase() : label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HudRoleChip extends StatelessWidget {
  final HudRole role;
  final String? customLabel;

  const HudRoleChip({
    super.key,
    required this.role,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    Color fg;
    String label;

    switch (role) {
      case HudRole.admin:
        border = AppColors.secondaryContainer;
        bg = AppColors.secondaryContainer.withAlpha(30);
        fg = AppColors.secondaryContainer;
        label = customLabel ?? 'ADMIN';
        break;
      case HudRole.manager:
        border = AppColors.tertiary;
        bg = AppColors.tertiary.withAlpha(30);
        fg = AppColors.tertiary;
        label = customLabel ?? 'MANAGER';
        break;
      case HudRole.staff:
      case HudRole.valet:
        border = AppColors.outline;
        bg = AppColors.outline.withAlpha(25);
        fg = AppColors.onSurface;
        label = customLabel ?? 'STAFF';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
