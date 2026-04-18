import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

/// Sleep timer card with pill-style slider and dashed countdown ring.
class SleepTimerSection extends StatefulWidget {
  const SleepTimerSection({super.key});

  @override
  State<SleepTimerSection> createState() => _SleepTimerSectionState();
}

class _SleepTimerSectionState extends State<SleepTimerSection> {
  double _minutes = 45;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -40,
          right: -40,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        GlassCard(
          borderRadius: 16,
          blurSigma: 10,
          padding: const EdgeInsets.all(32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              final row = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _copyAndSlider(context)),
                  if (isWide) ...[
                    const SizedBox(width: 32),
                    _countdownRing(context),
                  ],
                ],
              );
              final column = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _copyAndSlider(context),
                  const SizedBox(height: 28),
                  Center(child: _countdownRing(context)),
                ],
              );
              return isWide ? row : column;
            },
          ),
        ),
      ],
    );
  }

  Widget _copyAndSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep Timer',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Set your sanctuary to gently fade as you drift away. Our smart fade-out '
          'technology ensures you aren\'t startled awake.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            height: 1.45,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.18),
            trackShape: const RoundedRectSliderTrackShape(),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 3,
              pressedElevation: 6,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
          ),
          child: Slider(
            value: _minutes,
            min: 15,
            max: 120,
            onChanged: (v) => setState(() => _minutes = v),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _timeLabel('15 min', false),
            _timeLabel('${_minutes.round()} min left', true),
            _timeLabel('120 min', false),
          ],
        ),
      ],
    );
  }

  Widget _timeLabel(String text, bool accent) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: accent ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _countdownRing(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(128, 128),
            painter: _DashedRingPainter(
              color: AppColors.outlineVariant,
              strokeWidth: 3,
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          ),
          Text(
            '${_minutes.round()}m',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const dashAngle = 0.22;
    const gapAngle = 0.16;
    var theta = -math.pi / 2;
    final end = theta + 2 * math.pi;
    while (theta < end) {
      final sweep = math.min(dashAngle, end - theta);
      if (sweep > 0.01) {
        canvas.drawArc(rect, theta, sweep, false, paint);
      }
      theta += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
