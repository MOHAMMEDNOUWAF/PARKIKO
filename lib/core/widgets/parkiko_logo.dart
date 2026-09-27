import 'package:flutter/material.dart';

class ParkikoLogo extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;

  const ParkikoLogo({
    super.key,
    this.size = 32,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      'assets/icons/parkiko_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0F6B4F),
            borderRadius: borderRadius ?? BorderRadius.circular(size * 0.22),
          ),
          child: Icon(Icons.local_parking, color: Colors.white, size: size * 0.6),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(
          width: size,
          height: size,
          child: image,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: image,
    );
  }
}
