import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../player/domain/audio_track.dart';
import 'widgets/mixer_channel_tile.dart';

MixerChannelData mixerChannelFromTrack(AudioTrack t) {
  final icon = _iconForCategory(t.category);
  final colors = _colorsForCategory(t.category);
  return MixerChannelData(
    trackId: t.id,
    title: t.title,
    subtitle: t.subtitle,
    icon: icon,
    iconBackground: colors.$1,
    iconColor: colors.$2,
  );
}

IconData _iconForCategory(String c) {
  return switch (c) {
    'forest' => Icons.forest_rounded,
    'waterfall' => Icons.water_drop_rounded,
    'ocean' => Icons.waves_rounded,
    'birds' => Icons.flutter_dash_rounded,
    'fire' => Icons.local_fire_department_rounded,
    'demo' => Icons.cloud_download_rounded,
    _ => Icons.music_note_rounded,
  };
}

(Color, Color) _colorsForCategory(String c) {
  return switch (c) {
    'forest' => (
        AppColors.secondaryContainer.withValues(alpha: 0.4),
        AppColors.secondary,
      ),
    'waterfall' => (
        AppColors.primaryContainer.withValues(alpha: 0.2),
        AppColors.primary,
      ),
    'ocean' => (
        AppColors.secondaryContainer.withValues(alpha: 0.3),
        AppColors.secondary,
      ),
    'birds' => (
        AppColors.tertiary.withValues(alpha: 0.22),
        AppColors.tertiary,
      ),
    'fire' => (
        AppColors.errorContainer.withValues(alpha: 0.2),
        AppColors.error,
      ),
    'demo' => (
        AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
        AppColors.primary,
      ),
    _ => (
        AppColors.surfaceContainerHighest.withValues(alpha: 0.4),
        AppColors.onSurfaceVariant,
      ),
  };
}
