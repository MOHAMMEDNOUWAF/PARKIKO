import 'package:flutter/material.dart';

/// Tactical Dispatch HUD Color System
/// Designed for extreme luminance contrast, sun-glare resistance,
/// and instant operational recognition.
class AppColors {
  AppColors._();

  // Canvas & Surfaces
  static const Color surface = Color(0xFF0D1513);
  static const Color surfaceDim = Color(0xFF0D1513);
  static const Color surfaceBright = Color(0xFF333B38);
  static const Color surfaceContainerLowest = Color(0xFF08100E);
  static const Color surfaceContainerLow = Color(0xFF151D1B);
  static const Color surfaceContainer = Color(0xFF19211F);
  static const Color surfaceContainerHigh = Color(0xFF232C29);
  static const Color surfaceContainerHighest = Color(0xFF2E3634);
  static const Color background = Color(0xFF0D1513);

  // Structural Tiers
  static const Color groundZero = Color(0xFF071210);
  static const Color cardModule = Color(0xFF0D1E1A);
  static const Color elevatedControl = Color(0xFF142C26);
  static const Color hudOverlay = Color(0xF5050B0A); // 96% blackout

  // Borders & Delimiters
  static const Color borderSubtle = Color(0xFF1D3B34);
  static const Color borderFocused = Color(0xFF00BFA5);
  static const Color outline = Color(0xFF89938F);
  static const Color outlineVariant = Color(0xFF3F4945);

  // Primary (Tactical Teal)
  static const Color primary = Color(0xFF94D3C1);
  static const Color onPrimary = Color(0xFF00382E);
  static const Color primaryContainer = Color(0xFF004D40);
  static const Color onPrimaryContainer = Color(0xFF7EBDAC);
  static const Color primaryFixed = Color(0xFFAFEFDD);

  // Secondary (Laser Cyan Telemetry)
  static const Color secondary = Color(0xFFBDF4FF);
  static const Color onSecondary = Color(0xFF00363D);
  static const Color secondaryContainer = Color(0xFF00E5FF);
  static const Color onSecondaryContainer = Color(0xFF00616D);

  // Tertiary (Cautionary Amber)
  static const Color tertiary = Color(0xFFFFB950);
  static const Color onTertiary = Color(0xFF452B00);
  static const Color tertiaryContainer = Color(0xFF5E3D00);
  static const Color onTertiaryContainer = Color(0xFFF0A100);

  // Errors & High Alerts
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Operational Status Matrix
  static const Color statusAvailable = Color(0xFF00E676); // Phosphor Green
  static const Color statusOccupied = Color(0xFFFF1744);  // Radiant Crimson
  static const Color statusQueue = Color(0xFFFFAB00);     // Radiant Amber
  static const Color statusOffline = Color(0xFF607D8B);   // Muted Slate
  static const Color statusWhatsApp = Color(0xFF25D366);  // WhatsApp Emerald

  // Text & Foregrounds
  static const Color onSurface = Color(0xFFDCE4E1);
  static const Color onSurfaceVariant = Color(0xFFBFC9C4);
  static const Color textHighLuminance = Color(0xFFF0FDF4);
  static const Color textMuted = Color(0xFF8FAFA6);
}
