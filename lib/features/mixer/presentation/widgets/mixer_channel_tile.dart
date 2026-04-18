import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../application/mixer_controller.dart';
import 'mixer_pill_slider.dart';

class MixerChannelData {
  const MixerChannelData({
    required this.trackId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  final String trackId;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
}

/// One mixer channel; watches only this track’s level so sliders stay fluid during live mix.
class MixerChannelTile extends ConsumerWidget {
  const MixerChannelTile({super.key, required this.channel});

  final MixerChannelData channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackId = channel.trackId;
    final percent = ref.watch(
      mixerControllerProvider.select((s) => s.levelsByTrackId[trackId] ?? 0),
    );
    final mixPlaying = ref.watch(
      mixerControllerProvider.select((s) => s.mixPlaying),
    );
    final mixCtl = ref.read(mixerControllerProvider.notifier);

    final pct = percent.round().clamp(0, 100);
    final isLiveAudible = mixPlaying && percent > 0.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isLiveAudible
            ? [
                BoxShadow(
                  color: channel.iconColor.withValues(
                    alpha: (0.12 + percent / 900).clamp(0.0, 0.45),
                  ),
                  blurRadius: 14 + percent / 12,
                  spreadRadius: 0,
                ),
              ]
            : const [],
      ),
      child: GlassCard(
        borderRadius: 16,
        useBackdropBlur: false,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutBack,
                  scale: isLiveAudible
                      ? 1.0 + (percent / 1000).clamp(0.0, 0.06)
                      : 1,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: channel.iconBackground,
                      boxShadow: isLiveAudible
                          ? [
                              BoxShadow(
                                color: channel.iconColor.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      channel.icon,
                      color: channel.iconColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              channel.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                          if (isLiveAudible) ...[
                            const SizedBox(width: 8),
                            _LiveChip(accent: channel.iconColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        channel.subtitle.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 120),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: isLiveAudible
                        ? channel.iconColor
                        : AppColors.primary,
                  ),
                  child: Text('$pct%'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            MixerPillSlider(
              value: percent,
              onChanged: (v) => mixCtl.setChannelLevel(trackId, v),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.2),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        'CANLI',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 9,
          color: accent,
        ),
      ),
    );
  }
}

