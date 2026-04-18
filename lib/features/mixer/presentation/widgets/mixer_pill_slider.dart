import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Thin track, cyan thumb with soft glow (matches HTML mixer sliders).
class MixerPillSlider extends StatelessWidget {
  const MixerPillSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceContainerHighest,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.22),
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: const _MixerThumbShape(),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: Slider(value: value, min: 0, max: 100, onChanged: onChanged),
    );
  }
}

class _MixerThumbShape extends RoundSliderThumbShape {
  const _MixerThumbShape();

  static const double _radius = 10;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final glow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final fill = Paint()..color = AppColors.primary;

    canvas.drawCircle(center, _radius + 4, glow);
    canvas.drawCircle(center, _radius, fill);
    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
