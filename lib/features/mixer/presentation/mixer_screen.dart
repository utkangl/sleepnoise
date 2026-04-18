import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sleeping_noise_app_bar.dart';
import '../../player/application/playback_visibility.dart';
import '../../../core/routing/app_route.dart';
import '../../library/application/library_notifier.dart';
import '../../library/presentation/mix_name_dialog.dart';
import '../application/mixer_controller.dart';
import '../domain/mixable_tracks.dart';
import 'mixer_channel_factory.dart';
import 'widgets/mixer_channel_tile.dart';
import 'widgets/preset_mix_strip.dart';

class MixerScreen extends ConsumerWidget {
  const MixerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels =
        mixableTracks().map(mixerChannelFromTrack).toList();
    final mix = ref.watch(mixerControllerProvider);
    final mixCtl = ref.read(mixerControllerProvider.notifier);
    final chrome = ref.watch(
      shellPlaybackChromeVisibleProvider(AppRoute.mixer.path),
    );
    final bottomPad =
        MediaQuery.paddingOf(context).bottom + (chrome ? 210 : 100);
    final canStartMix = mix.activeLayerCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SafeArea(bottom: false, child: SleepingNoiseAppBar()),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPad),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Ses karıştırıcı',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      height: 1.05,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Uykuya dalmanı sağlayacak sesi kendin yarat.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant
                                          .withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Karışımı kaydet',
                          onPressed: canStartMix
                              ? () async {
                                  final name =
                                      await showMixSaveNameDialog(context);
                                  if (!context.mounted ||
                                      name == null ||
                                      name.isEmpty) {
                                    return;
                                  }
                                  await ref
                                      .read(libraryNotifierProvider.notifier)
                                      .saveCurrentMixerMix(ref, name);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Kaydedildi: $name'),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.bookmark_add_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const PresetMixStrip(),
                    const SizedBox(height: 28),
                    Text(
                      'Kanallar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < channels.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      MixerChannelTile(channel: channels[i]),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed:
                          (!mix.mixPlaying &&
                                  !mix.mixLoading &&
                                  !canStartMix)
                              ? null
                              : () => mixCtl.toggleMixPlayPause(),
                      icon: Icon(
                        mix.mixLoading
                            ? Icons.stop_circle_outlined
                            : (mix.mixPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded),
                      ),
                      label: Text(
                        mix.mixLoading
                            ? 'Durdur'
                            : (mix.mixPlaying ? 'Duraklat' : 'Oynat'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    if (!canStartMix && !mix.mixPlaying) ...[
                      const SizedBox(height: 10),
                      Text(
                        'En az bir kanalı sıfırdan yukarı açık tutun.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
