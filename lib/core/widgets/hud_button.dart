import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum HudButtonVariant {
  primary,   // Run / Park / Dispatch (Teal + Phosphor Green indicator)
  secondary, // Tactical action (Dark Slate + Cyan border)
  critical,  // Reject / Release alert (Crimson)
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
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;
    Color? stripColor;

    switch (variant) {
      case HudButtonVariant.primary:
        bg = AppColors.primaryContainer;
        border = AppColors.borderFocused;
        fg = AppColors.textHighLuminance;
        stripColor = AppColors.statusAvailable;
        break;
      case HudButtonVariant.secondary:
        bg = AppColors.cardModule;
        border = AppColors.borderSubtle;
        fg = AppColors.onSurface;
        stripColor = AppColors.secondaryContainer;
        break;
      case HudButtonVariant.critical:
        bg = const Color(0xFF2A080C);
        border = AppColors.statusOccupied;
        fg = const Color(0xFFFF8A80);
        stripColor = AppColors.statusOccupied;
        break;
      case HudButtonVariant.ghost:
        bg = Colors.transparent;
        border = AppColors.borderSubtle;
        fg = AppColors.onSurfaceVariant;
        stripColor = null;
        break;
    }

    final content = Stack(
      children: [
        // Left tactical indicator strip
        if (stripColor != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: stripColor),
          ),
        Center(
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
                        text.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
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
      ],
    );

    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.zero,
      child: Container(
        height: height,
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: content,
      ),
    );
  }
}
