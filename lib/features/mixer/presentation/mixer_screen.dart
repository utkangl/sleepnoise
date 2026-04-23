import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/tab_reselect_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sleeping_noise_app_bar.dart';
import '../../player/application/playback_visibility.dart';
import '../../../core/routing/app_route.dart';
import '../../catalog/application/remote_catalog_controller.dart';
import '../../library/application/library_notifier.dart';
import '../../library/application/track_download_controller.dart';
import '../../library/presentation/mix_name_dialog.dart';
import '../../player/domain/audio_catalog.dart';
import '../../player/domain/audio_track.dart';
import '../application/mixer_controller.dart';
import '../application/mixer_mixable_catalog.dart';
import 'mixer_channel_factory.dart';
import 'widgets/mixer_channel_tile.dart';
import 'widgets/preset_mix_strip.dart';

class MixerScreen extends ConsumerStatefulWidget {
  const MixerScreen({super.key});

  @override
  ConsumerState<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends ConsumerState<MixerScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    listenTabScrollToTop(ref, AppRoute.mixer.path, _scroll);
    final remoteCatalog = ref.watch(remoteCatalogProvider);
    final downloadCtl = ref.read(trackDownloadControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      downloadCtl.ensureHydrated(featuredTracks);
      remoteCatalog.whenData(downloadCtl.ensureHydrated);
      ref.read(mixerControllerProvider.notifier).syncMixableCatalog(
            ref.read(mixerMixableTracksProvider),
          );
    });
    ref.listen<List<AudioTrack>>(mixerMixableTracksProvider, (_, next) {
      ref.read(mixerControllerProvider.notifier).syncMixableCatalog(next);
    });
    final channels =
        ref.watch(mixerMixableTracksProvider).map(mixerChannelFromTrack).toList();
    final mix = ref.watch(mixerControllerProvider);
    final mixCtl = ref.read(mixerControllerProvider.notifier);
    final chrome = ref.watch(
      shellPlaybackChromeVisibleProvider(AppRoute.mixer.path),
    );
    final mq = MediaQuery.paddingOf(context);
    final scrollAreaTop = mq.top + SleepingNoiseAppBar.height;
    final bottomPad = mq.bottom + (chrome ? 210 : 100);
    final canStartMix = mix.activeLayerCount > 0;
    // Hazır bir miks yüklü ve kullanıcı henüz hiçbir kanalı değiştirmediyse,
    // tekrar kaydetmek anlamsız: butonu gizle.
    final canSaveAsCustom = canStartMix && mix.loadedPresetId == null;

    return Stack(
      children: [
        Positioned(
          top: scrollAreaTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
            controller: _scroll,
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
                        if (canSaveAsCustom)
                          IconButton(
                            tooltip: 'Karışımı kaydet',
                            onPressed: () async {
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
                                  SnackBar(content: Text('Kaydedildi: $name')),
                                );
                              }
                            },
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: const SafeArea(bottom: false, child: SleepingNoiseAppBar()),
        ),
      ],
    );
  }
}
