import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum OperationalStatus {
  available,  // Green / Retrieved
  occupied,   // Red / Parked
  inTransit,  // Amber / In Transit
  queue,      // Amber / In Queue
  offline,    // Slate / Offline
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
    this.isUppercase = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color dot;

    if (customColor != null) {
      bg = customColor!.withAlpha(30);
      fg = customColor!;
      dot = customColor!;
    } else {
      switch (status) {
        case OperationalStatus.available:
          bg = AppColors.secondaryContainer;
          fg = AppColors.onSecondaryContainer;
          dot = AppColors.primary;
          break;
        case OperationalStatus.occupied:
          bg = AppColors.errorContainer;
          fg = AppColors.error;
          dot = AppColors.error;
          break;
        case OperationalStatus.inTransit:
        case OperationalStatus.queue:
          bg = const Color(0xFFFEF3C7);
          fg = const Color(0xFFB45309);
          dot = const Color(0xFFD97706);
          break;
        case OperationalStatus.offline:
          bg = AppColors.surfaceContainer;
          fg = AppColors.onSurfaceVariant;
          dot = AppColors.outline;
          break;
        case OperationalStatus.custom:
          bg = AppColors.secondaryContainer;
          fg = AppColors.primary;
          dot = AppColors.primary;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isUppercase ? label.toUpperCase() : label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
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
    Color bg;
    Color fg;
    String label;

    switch (role) {
      case HudRole.admin:
        bg = AppColors.secondaryContainer;
        fg = AppColors.onSecondaryContainer;
        label = customLabel ?? 'Admin';
        break;
      case HudRole.manager:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.primary;
        label = customLabel ?? 'Lead';
        break;
      case HudRole.staff:
      case HudRole.valet:
        bg = AppColors.surfaceContainerLow;
        fg = AppColors.onSurfaceVariant;
        label = customLabel ?? 'Valet';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
