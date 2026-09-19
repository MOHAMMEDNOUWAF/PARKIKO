import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum HudButtonVariant {
  primary,   // Stitch primary mint (#00513A)
  secondary, // Surface container low (#EBF6EF) + primary text
  critical,  // Stitch error (#BA1A1A)
  ghost,     // Transparent with border
}

class HudButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final HudButtonVariant variant;
  final bool isLoading;
  final double height;
  final bool fullWidth;
  final double borderRadius;

  const HudButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = HudButtonVariant.primary,
    this.isLoading = false,
    this.height = 48,
    this.fullWidth = true,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;

    switch (variant) {
      case HudButtonVariant.primary:
        bg = AppColors.primary;
        border = Colors.transparent;
        fg = Colors.white;
        break;
      case HudButtonVariant.secondary:
        bg = AppColors.surfaceContainerLow;
        border = const Color(0x66BEC9C2);
        fg = AppColors.primary;
        break;
      case HudButtonVariant.critical:
        bg = AppColors.error;
        border = Colors.transparent;
        fg = Colors.white;
        break;
      case HudButtonVariant.ghost:
        bg = Colors.transparent;
        border = const Color(0x66BEC9C2);
        fg = AppColors.onSurfaceVariant;
        break;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: variant == HudButtonVariant.primary
                ? const [
                    BoxShadow(
                      color: Color(0x1A00513A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(trailingIcon, size: 18, color: fg),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
