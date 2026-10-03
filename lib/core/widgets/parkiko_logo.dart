import 'package:flutter/material.dart';

class ParkikoLogo extends StatelessWidget {
  final double? size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ParkikoLogo({
    super.key,
    this.size,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size ?? 32.0;
    final effectiveHeight = height ?? size ?? 32.0;

    Widget image = Image.asset(
      'assets/icons/parkiko.png',
      width: effectiveWidth,
      height: effectiveHeight,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: effectiveWidth,
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0F6B4F),
            borderRadius: borderRadius ?? BorderRadius.circular(effectiveWidth * 0.22),
          ),
          child: Icon(Icons.local_parking, color: Colors.white, size: effectiveWidth * 0.6),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(
          width: effectiveWidth,
          height: effectiveHeight,
          child: image,
        ),
      );
    }

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: image,
    );
  }
}
