import 'package:flutter/material.dart';

/// Google Stitch Mint-Emerald Theme Palette for Parkiko
/// 1:1 Design tokens from Stitch project parkiko1
class AppColors {
  AppColors._();

  // Canvas & Surfaces (Mint light theme)
  static const Color background = Color(0xFFF1FCF5);
  static const Color surface = Color(0xFFF1FCF5);
  static const Color surfaceDim = Color(0xFFD1DDD6);
  static const Color surfaceBright = Color(0xFFF1FCF5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Clean white card base
  static const Color surfaceContainerLow = Color(0xFFEBF6EF);
  static const Color surfaceContainer = Color(0xFFE5F1EA);
  static const Color surfaceContainerHigh = Color(0xFFDFEBE4);
  static const Color surfaceContainerHighest = Color(0xFFDAE5DE);
  static const Color surfaceVariant = Color(0xFFDAE5DE);

  // Structural Tiers
  static const Color groundZero = Color(0xFFEBF6EF);
  static const Color cardModule = Color(0xFFFFFFFF);
  static const Color elevatedControl = Color(0xFFE5F1EA);
  static const Color hudOverlay = Color(0xFFFFFFFF);

  // Borders & Delimiters
  static const Color outline = Color(0xFF6F7A73);
  static const Color outlineVariant = Color(0xFFBEC9C2);
  static const Color borderSubtle = Color(0xFFBEC9C2);
  static const Color borderFocused = Color(0xFF00513A);

  // Primary (Deep Mint / Emerald)
  static const Color primary = Color(0xFF00513A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0F6B4F);
  static const Color onPrimaryContainer = Color(0xFF97E8C5);
  static const Color primaryFixed = Color(0xFFA1F3CF);
  static const Color primaryFixedDim = Color(0xFF86D6B4);
  static const Color onPrimaryFixed = Color(0xFF002115);
  static const Color onPrimaryFixedVariant = Color(0xFF00513A);

  // Secondary (Sage / Mint Container)
  static const Color secondary = Color(0xFF2D6955);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFAFEDD4);
  static const Color onSecondaryContainer = Color(0xFF326D59);
  static const Color secondaryFixed = Color(0xFFB2EFD6);
  static const Color secondaryFixedDim = Color(0xFF96D3BB);

  // Tertiary (Deep Forest Green)
  static const Color tertiary = Color(0xFF005220);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF006D2D);
  static const Color onTertiaryContainer = Color(0xFF74F18D);

  // Errors & High Alerts
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Operational Status Matrix (Stitch palette)
  static const Color statusAvailable = Color(0xFF005220); // Deep Forest / Available
  static const Color statusOccupied = Color(0xFFBA1A1A);  // Deep Red / In slots
  static const Color statusQueue = Color(0xFFD97706);     // Amber
  static const Color statusOffline = Color(0xFF6F7A73);   // Slate outline
  static const Color statusWhatsApp = Color(0xFF25D366);  // WhatsApp Emerald

  // Text & Foregrounds
  static const Color onSurface = Color(0xFF141E1A);
  static const Color onSurfaceVariant = Color(0xFF3F4944);
  static const Color onBackground = Color(0xFF141E1A);
  static const Color textHighLuminance = Color(0xFF141E1A);
  static const Color textMuted = Color(0xFF6F7A73);

  // Inverse Surfaces
  static const Color inverseSurface = Color(0xFF28332E);
  static const Color inverseOnSurface = Color(0xFFE8F3ED);
  static const Color inversePrimary = Color(0xFF86D6B4);
}
