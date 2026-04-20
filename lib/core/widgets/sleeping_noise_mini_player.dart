import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/mixer/application/mixer_controller.dart';
import '../../features/player/application/audio_controller.dart';
import '../../features/player/application/playback_facade.dart';
import '../../features/player/application/playback_owner_controller.dart';
import '../routing/app_route.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Global mini player: gösterilen şey mix mi single mı sadece state’e göre seçilir.
class SleepingNoiseMiniPlayer extends ConsumerWidget {
  const SleepingNoiseMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(playbackOwnerProvider);
    final mix = ref.watch(mixerControllerProvider);
    final mixCtl = ref.read(mixerControllerProvider.notifier);
    final audioState = ref.watch(audioControllerProvider);
    final hasSingle = owner == PlaybackOwner.single;
    final hasMix = owner == PlaybackOwner.mix;

    if (hasMix) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(AppRoute.nowPlaying.path),
        child: _LiveMixMiniBar(
          activeLayers: mix.activeLayerCount,
          isPlaying: mix.mixPlaying,
          mixLoading: mix.mixLoading,
          onPlayPause: () => mixCtl.toggleMixPlayPause(),
        ),
      );
    }

    if (hasSingle) {
      final track = audioState.currentTrack;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // NP'ye geçerken oynatma durmuşsa otomatik resume — kullanıcı
          // "playing card"a basınca NP açılıp ses yine duruyor demesin.
          if (!audioState.isPlaying && !audioState.isLoading) {
            unawaited(
              ref
                  .read(audioControllerProvider.notifier)
                  .playTrackById(track.id),
            );
          }
          context.push(AppRoute.nowPlaying.path);
        },
        child: _HomeNowPlayingBar(
          imageUrl: track.artworkUrl,
          title: track.title,
          subtitle: audioState.isLoading ? 'Yükleniyor…' : track.subtitle,
          isPlaying: audioState.isPlaying,
          onPrevious: () => playSinglePrevious(ref),
          onPlayPause: () => toggleSinglePlayPause(ref),
          onNext: () => playSingleNext(ref),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _LiveMixMiniBar extends StatelessWidget {
  const _LiveMixMiniBar({
    required this.activeLayers,
    required this.isPlaying,
    required this.mixLoading,
    required this.onPlayPause,
  });

  final int activeLayers;
  final bool isPlaying;
  final bool mixLoading;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: GlassCard(
              borderRadius: 16,
              blurSigma: 10,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer.withValues(alpha: 0.25),
                    ),
                    child: const Icon(
                      Icons.layers_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Karışım',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aktif katman: $activeLayers',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.primary,
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPlayPause,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          mixLoading
                              ? Icons.stop_circle_outlined
                              : (isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded),
                          color: AppColors.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeNowPlayingBar extends StatelessWidget {
  const _HomeNowPlayingBar({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.isPlaying,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: GlassCard(
              borderRadius: 16,
              blurSigma: 10,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _Thumb(url: imageUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: AppColors.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    iconSize: 22,
                  ),
                  Material(
                    color: AppColors.primaryContainer,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPlayPause,
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onNext,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: AppColors.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    iconSize: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    const radius = 10.0;
    final hasImage = url.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: hasImage
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppColors.surfaceContainerHighest,
                  child: Icon(
                    Icons.music_note_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
            : ColoredBox(
                color: AppColors.surfaceContainerHighest,
                child: Icon(
                  Icons.music_note_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
