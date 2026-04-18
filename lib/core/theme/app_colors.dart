import 'package:flutter/material.dart';

/// **Digital Sanctuary — The Celestial Veil**
/// Tonal layering; no hard 1px containment strokes — use [ghostBorder] when an edge is required.
abstract final class AppColors {
  // --- Foundation ---
  static const Color surface = Color(0xFF070D1F);
  static const Color background = surface;

  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surfaceContainerLow = Color(0xFF0A1228);
  static const Color surfaceContainer = Color(0xFF101B32);
  static const Color surfaceContainerHigh = Color(0xFF171F36);
  static const Color surfaceContainerHighest = Color(0xFF1E2A48);
  static const Color surfaceVariant = Color(0xFF252E45);

  // --- Brand & spectral ---
  static const Color primary = Color(0xFF5BF4DE);
  static const Color primaryContainer = Color(0xFF11C9B4);
  static const Color surfaceTint = Color(0xFF5BF4DE);

  /// Mesh / ambient (low-opacity blends).
  static const Color primaryDim = Color(0xFF3DA89A);
  static const Color secondaryDim = Color(0xFF5C6CA8);
  static const Color tertiaryDim = Color(0xFFB87A30);

  static const Color onPrimary = Color(0xFF021A1C);
  static const Color onPrimaryContainer = Color(0xFF001A18);

  static const Color secondary = Color(0xFFB8C0F0);
  static const Color onSecondary = Color(0xFF1A1F38);
  static const Color secondaryContainer = Color(0xFF1F2848);

  /// Spectral ember — use sparingly for critical CTAs.
  static const Color tertiary = Color(0xFFFFB148);
  static const Color onTertiary = Color(0xFF2A1400);
  static const Color onTertiaryContainer = Color(0xFF3D2100);

  // --- Typography (never pure white) ---
  static const Color onBackground = Color(0xFFDFE4FE);
  static const Color onSurface = Color(0xFFDFE4FE);
  static const Color onSurfaceVariant = Color(0xFF9BA3C9);

  // --- Edges: ghost only (15% outline-variant max) ---
  static const Color outlineVariant = Color(0xFF6B7399);
  static const Color outline = Color(0xFF8E96B8);

  /// The only allowed “line”: low-opacity glimmer.
  static Color get ghostBorder => outlineVariant.withValues(alpha: 0.15);

  static const Color error = Color(0xFFFF8A9A);
  static const Color errorContainer = Color(0xFF6A1A2E);

  // --- Expanded player / editorial mockup (lavender + cyan spectrum) ---
  static const Color spectralLavender = Color(0xFFA88BFF);
  static const Color spectralCyan = Color(0xFF81ECFF);
  static const Color onSpectralLavender = Color(0xFF260069);

  // --- Legacy aliases used by screens (mapped to DS) ---
  static const Color primaryFixedDim = Color(0xFF7AE8D8);
  static const Color navInactive = onSurfaceVariant;
  static const Color navActive = primary;
}
