import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Static mesh (no animation loop — avoids constant repaints / jank).
/// Tonal layers + blobs at fixed “rest” positions.
class MeshGradientBackground extends StatelessWidget {
  const MeshGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-0.95, -1),
                end: const Alignment(1, 1),
                colors: [
                  AppColors.surface,
                  AppColors.surfaceContainerLow,
                  AppColors.surfaceContainer,
                  AppColors.surfaceContainerHigh.withValues(alpha: 0.85),
                  AppColors.surface,
                ],
                stops: const [0.0, 0.28, 0.52, 0.78, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.82, -0.6),
                radius: 1.2,
                colors: [
                  AppColors.primaryDim.withValues(alpha: 0.28),
                  AppColors.primaryDim.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.72, 0.75),
                radius: 1.1,
                colors: [
                  AppColors.secondaryDim.withValues(alpha: 0.22),
                  AppColors.secondaryDim.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.48, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, 0.1),
                radius: 0.95,
                colors: [
                  AppColors.tertiaryDim.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
          _blob(
            alignment: const Alignment(0.82, -0.72),
            color: AppColors.primary.withValues(alpha: 0.18),
            size: 1.35,
          ),
          _blob(
            alignment: const Alignment(-0.78, 0.82),
            color: AppColors.secondary.withValues(alpha: 0.12),
            size: 1.28,
          ),
          _blob(
            alignment: const Alignment(0.55, 0.38),
            color: AppColors.primaryContainer.withValues(alpha: 0.14),
            size: 1.05,
          ),
        ],
      ),
    );
  }

  static Widget _blob({
    required Alignment alignment,
    required Color color,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: OverflowBox(
        maxWidth: 800 * size,
        maxHeight: 800 * size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0, 1],
            ),
          ),
        ),
      ),
    );
  }
}
