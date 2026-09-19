import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tactical Dispatch HUD Typography
/// Prioritizes machine-readability, instant outdoor scanning, and tabular numerals.
class AppTypography {
  AppTypography._();

  // Display Typography (Space Grotesk)
  static TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 52 / 48,
    letterSpacing: -1.92, // -0.04em
    color: AppColors.textHighLuminance,
  );

  static TextStyle displayLargeMobile = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 36 / 32,
    letterSpacing: -0.96, // -0.03em
    color: AppColors.textHighLuminance,
  );

  // Headlines (Space Grotesk)
  static TextStyle headlineLarge = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    letterSpacing: -0.64, // -0.02em
    color: AppColors.onSurface,
  );

  static TextStyle headlineLargeMobile = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 30 / 24,
    letterSpacing: -0.48, // -0.02em
    color: AppColors.onSurface,
  );

  static TextStyle headlineMedium = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.22, // -0.01em
    color: AppColors.onSurface,
  );

  static TextStyle headlineSmall = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  // Titles (Space Grotesk)
  static TextStyle titleMedium = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
    letterSpacing: 0.32, // 0.02em
    color: AppColors.onSurface,
  );

  // Body Typography (Inter / Geist)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.14, // 0.01em
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.24, // 0.02em
    color: AppColors.onSurfaceVariant,
  );

  // Labels & Telemetry Readouts (Uppercase & Tracked)
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0.84, // 0.06em
    color: AppColors.onSurface,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.88, // 0.08em
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    height: 12 / 9,
    letterSpacing: 1.08, // 0.12em
    color: AppColors.onSurfaceVariant,
  );

  // High-Precision License Plate & Telemetry Numbers
  static TextStyle licensePlate = GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.groundZero,
  );

  static TextStyle telemetryTimer = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.primary,
  );
}
