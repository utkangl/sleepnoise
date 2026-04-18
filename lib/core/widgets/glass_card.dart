import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Frosted glass. Backdrop blur is expensive — use [useBackdropBlur: false] for dense lists.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.blurSigma = 8,
    this.fillOpacity = 0.45,
    this.useBackdropBlur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;
  final double fillOpacity;
  final bool useBackdropBlur;

  @override
  Widget build(BuildContext context) {
    final inner = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: fillOpacity),
        border: Border.all(color: AppColors.ghostBorder, width: 1),
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: useBackdropBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: inner,
            )
          : inner,
    );
  }
}
