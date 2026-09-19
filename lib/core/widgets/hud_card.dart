import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Google Stitch Card Component
/// 16px rounded corners, white surface, subtle elevation and border
class HudCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final Color borderColor;
  final Color? leftAccentColor;
  final double leftAccentWidth;
  final VoidCallback? onTap;
  final double borderRadius;

  const HudCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.backgroundColor = AppColors.surfaceContainerLowest,
    this.borderColor = const Color(0x40BEC9C2),
    this.leftAccentColor,
    this.leftAccentWidth = 4,
    this.onTap,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = child;

    if (leftAccentColor != null) {
      cardContent = Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: leftAccentWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                bottomLeft: Radius.circular(borderRadius),
              ),
              child: Container(color: leftAccentColor),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: leftAccentWidth + 4),
            child: child,
          ),
        ],
      );
    }

    final box = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817211D),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0A17211D),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: cardContent,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: box,
        ),
      );
    }

    return box;
  }
}
