import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Tactical Dispatch HUD ThemeData
/// Enforces strict zero-radius architecture, monoline strokes, and high-contrast dark mode.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      // Zero-radius card theme
      cardTheme: const CardThemeData(
        color: AppColors.cardModule,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textHighLuminance,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      // Elevated button theme (Zero radius, minimum 48dp height)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.textHighLuminance,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.borderFocused, width: 1),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          backgroundColor: AppColors.cardModule,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      // Input decoration theme (Crisp monoline border, 0px radius)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.groundZero,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.secondaryContainer, width: 1),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.outline.withAlpha(150),
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
