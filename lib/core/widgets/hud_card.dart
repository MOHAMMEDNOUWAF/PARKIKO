import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HudCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final Color borderColor;
  final Color? leftAccentColor;
  final double leftAccentWidth;
  final VoidCallback? onTap;

  const HudCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.backgroundColor = AppColors.cardModule,
    this.borderColor = AppColors.borderSubtle,
    this.leftAccentColor,
    this.leftAccentWidth = 3,
    this.onTap,
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
            child: Container(color: leftAccentColor),
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: cardContent,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: box,
      );
    }

    return box;
  }
}
