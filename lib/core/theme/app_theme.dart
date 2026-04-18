import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Ethereal typography: Plus Jakarta Sans — editorial air, weight contrast, breathable body.
abstract final class AppTheme {
  static ThemeData dark() {
    TextStyle pjs({
      required double size,
      FontWeight? weight,
      double? height,
      double? letterSpacingEm,
      Color? color,
    }) {
      final ls = letterSpacingEm != null ? letterSpacingEm * size : null;
      return GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: ls,
        color: color ?? AppColors.onSurface,
      );
    }

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: ColorScheme.dark(
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        outline: AppColors.outline,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
      ),
    );

    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: pjs(
          size: 57,
          weight: FontWeight.w200,
          letterSpacingEm: -0.04,
          height: 1.1,
        ),
        displayMedium: pjs(
          size: 45,
          weight: FontWeight.w200,
          letterSpacingEm: -0.04,
          height: 1.12,
        ),
        displaySmall: pjs(
          size: 36,
          weight: FontWeight.w300,
          letterSpacingEm: -0.04,
          height: 1.15,
        ),
        headlineLarge: pjs(size: 32, weight: FontWeight.w200, height: 1.2),
        headlineMedium: pjs(size: 28, weight: FontWeight.w300, height: 1.25),
        headlineSmall: pjs(size: 24, weight: FontWeight.w400, height: 1.3),
        titleLarge: pjs(size: 22, weight: FontWeight.w700, height: 1.27),
        titleMedium: pjs(size: 16, weight: FontWeight.w600, height: 1.35),
        titleSmall: pjs(size: 14, weight: FontWeight.w600, height: 1.35),
        bodyLarge: pjs(
          size: 16,
          weight: FontWeight.w400,
          height: 1.6,
          letterSpacingEm: 0.02,
          color: AppColors.onSurface,
        ),
        bodyMedium: pjs(
          size: 14,
          weight: FontWeight.w400,
          height: 1.6,
          letterSpacingEm: 0.02,
          color: AppColors.onSurface,
        ),
        bodySmall: pjs(
          size: 12,
          weight: FontWeight.w400,
          height: 1.55,
          letterSpacingEm: 0.02,
          color: AppColors.onSurfaceVariant,
        ),
        labelLarge: pjs(
          size: 14,
          weight: FontWeight.w600,
          letterSpacingEm: 0.1,
          color: AppColors.onSurface,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: pjs(
          size: 22,
          weight: FontWeight.w700,
          letterSpacingEm: -0.02,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary, size: 26),
      ),
    );
  }
}
