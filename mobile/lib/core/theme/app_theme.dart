import 'package:flutter/material.dart';

/// Brand and status colors.
abstract final class AppColors {
  /// Industrial blue used to generate the whole color scheme.
  static const Color seed = Color(0xFF0B5CAD);

  /// Andon colors: line stopped, warning, running.
  static const Color stopped = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);
  static const Color running = Color(0xFF2E7D32);
}

/// Material 3 light and dark themes.
abstract final class AppTheme {
  /// Shop-floor friendly minimum height for buttons and inputs (gloves).
  static const double minTouchHeight = 56;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchHeight),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }
}
