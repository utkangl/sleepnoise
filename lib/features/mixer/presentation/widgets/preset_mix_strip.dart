import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../application/mixer_controller.dart';
import '../../domain/preset_mix.dart';
import '../../domain/preset_mix_catalog.dart';

/// Yatay kaydırmalı hazır mikslar şeridi.
class PresetMixStrip extends ConsumerWidget {
  const PresetMixStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixCtl = ref.read(mixerControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hazır mikslar',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presetMixCatalog.length,
            separatorBuilder: (context, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final preset = presetMixCatalog[index];
              return _PresetMixCard(
                preset: preset,
                onApply: () => mixCtl.loadPresetMix(preset),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PresetMixCard extends StatelessWidget {
  const _PresetMixCard({
    required this.preset,
    required this.onApply,
  });

  final PresetMix preset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onApply,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          borderRadius: 16,
          blurSigma: 8,
          useBackdropBlur: false,
          fillOpacity: 0.42,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: SizedBox(
            width: 168,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  preset.icon,
                  size: 26,
                  color: AppColors.primary,
                ),
                Text(
                  preset.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
                Text(
                  preset.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
