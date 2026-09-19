import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Google Stitch Typography System (Inter)
/// 1:1 Specifications from Stitch parkiko1 project
class AppTypography {
  AppTypography._();

  // Display Typography (Inter)
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 52 / 48,
    letterSpacing: -0.96,
    color: AppColors.onSurface,
  );

  static TextStyle displayLargeMobile = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 36 / 32,
    letterSpacing: -0.64,
    color: AppColors.onSurface,
  );

  // Headlines (Inter)
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    letterSpacing: -0.48,
    color: AppColors.onSurface,
  );

  static TextStyle headlineLargeMobile = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 30 / 24,
    letterSpacing: -0.24,
    color: AppColors.onSurface,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.22,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  // Titles (Inter)
  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );

  // Body Typography (Inter)
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
    letterSpacing: 0.14,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.24,
    color: AppColors.onSurfaceVariant,
  );

  // Labels (Inter)
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0.14,
    color: AppColors.onSurface,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.24,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.44,
    color: AppColors.onSurfaceVariant,
  );

  // High-Precision License Plate & Telemetry Numbers
  static TextStyle licensePlate = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.onSurface,
  );

  static TextStyle telemetryTimer = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.primary,
  );
}
