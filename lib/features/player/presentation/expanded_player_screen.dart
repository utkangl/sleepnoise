import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../library/application/library_notifier.dart';
import '../application/audio_controller.dart';
import '../application/playback_owner_controller.dart';
import '../application/playback_facade.dart';
import '../application/sleep_timer_controller.dart';
import 'widgets/expanded_mix_player_body.dart';
import 'widgets/sleep_timer_bottom_sheet.dart';
import '../../../core/routing/app_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';

/// Full-screen expanded player (opens from mini player). Editorial “Now Playing” layout.
class ExpandedPlayerScreen extends ConsumerStatefulWidget {
  const ExpandedPlayerScreen({super.key});

  @override
  ConsumerState<ExpandedPlayerScreen> createState() =>
      _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends ConsumerState<ExpandedPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(playbackOwnerProvider);
    final showMix = owner == PlaybackOwner.mix;

    if (showMix) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _PlayerMeshBackdrop(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PlayerAppBar(
                        title: 'Karışım',
                        onClose: () => context.pop(),
                      ),
                      const ExpandedMixPlayerBody(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final state = ref.watch(audioControllerProvider);
    final controller = ref.read(audioControllerProvider.notifier);
    final library = ref.watch(libraryNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PlayerMeshBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlayerAppBar(
                      title: 'Şu an çalıyor',
                      onClose: () => context.pop(),
                    ),
                    const SizedBox(height: 12),
                    _AlbumArtWithGlow(
                      imageUrl: state.currentTrack.artworkUrl,
                      category: state.currentTrack.category,
                    ),
                    const SizedBox(height: 28),
                    _TrackRow(
                      title: state.currentTrack.title,
                      subtitle: state.currentTrack.subtitle,
                      loved: library.favoriteTrackIds
                          .contains(state.currentTrack.id),
                      onToggleLove: () => ref
                          .read(libraryNotifierProvider.notifier)
                          .toggleFavoriteTrack(state.currentTrack.id),
                    ),
                    const SizedBox(height: 22),
                    _SpectralProgressSection(
                      progress: state.progress,
                      onSeekRequested: (v) => controller.seekToProgress(v),
                      positionLabel: _fmtDuration(state.position),
                      durationLabel: _fmtDuration(state.duration),
                    ),
                    const SizedBox(height: 28),
                    _TransportRow(
                      playing: state.isPlaying,
                      shuffle: state.shuffleEnabled,
                      repeat: state.repeatMode,
                      onPrevious: () => playSinglePrevious(ref),
                      onPlayPause: () => toggleSinglePlayPause(ref),
                      onNext: () => playSingleNext(ref),
                      onShuffle: () => controller.toggleShuffle(),
                      onRepeat: () => controller.cycleRepeatMode(),
                    ),
                    const SizedBox(height: 28),
                    const _UtilityPills(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _PlayerMeshBackdrop extends StatelessWidget {
  const _PlayerMeshBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Opacity(
          opacity: 0.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: [
                  const Color(0xFF2F007D).withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.1,
                colors: [
                  const Color(0xFF003840).withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Opacity(
          opacity: 0.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.15,
                colors: [
                  const Color(0xFF13003D).withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.2,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.spectralLavender.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.spectralLavender.withValues(alpha: 0.35),
                    blurRadius: 120,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.sizeOf(context).height * 0.18,
          left: -50,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.spectralCyan.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.spectralCyan.withValues(alpha: 0.25),
                    blurRadius: 100,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerAppBar extends StatelessWidget {
  const _PlayerAppBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.expand_more_rounded),
          color: AppColors.spectralLavender,
          iconSize: 30,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _AlbumArtWithGlow extends StatelessWidget {
  const _AlbumArtWithGlow({required this.imageUrl, required this.category});

  final String imageUrl;
  final String category;

  @override
  Widget build(BuildContext context) {
    const size = 288.0;
    return Center(
      child: SizedBox(
        width: size + 48,
        height: size + 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 32,
              height: size + 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.spectralLavender.withValues(alpha: 0.35),
                    blurRadius: 60,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            Container(
              width: size + 8,
              height: size + 8,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x66A88BFF), Color(0x6681ECFF)],
                ),
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        cacheWidth:
                            (size * MediaQuery.devicePixelRatioOf(context))
                                .round()
                                .clamp(400, 900),
                        errorBuilder: (_, _, _) =>
                            _CategoryArtwork(category: category),
                      )
                    : _CategoryArtwork(category: category),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryArtwork extends StatelessWidget {
  const _CategoryArtwork({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      'forest' => Icons.forest_rounded,
      'waterfall' => Icons.water_drop_rounded,
      'ocean' => Icons.waves_rounded,
      'birds' => Icons.flutter_dash_rounded,
      'fire' => Icons.local_fire_department_rounded,
      'demo' => Icons.cloud_download_rounded,
      _ => Icons.music_note_rounded,
    };
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2A4A), Color(0xFF2B1F57)],
        ),
      ),
      child: Center(child: Icon(icon, size: 88, color: AppColors.onSurface)),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.title,
    required this.subtitle,
    required this.loved,
    required this.onToggleLove,
  });

  final String title;
  final String subtitle;
  final bool loved;
  final VoidCallback onToggleLove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onToggleLove,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                loved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: AppColors.spectralLavender,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpectralProgressSection extends StatelessWidget {
  const _SpectralProgressSection({
    required this.progress,
    required this.onSeekRequested,
    required this.positionLabel,
    required this.durationLabel,
  });

  final double progress;
  final ValueChanged<double> onSeekRequested;
  final String positionLabel;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return _SpectralProgressBody(
      progress: progress,
      onSeekRequested: onSeekRequested,
      positionLabel: positionLabel,
      durationLabel: durationLabel,
    );
  }
}

class _SpectralProgressBody extends StatefulWidget {
  const _SpectralProgressBody({
    required this.progress,
    required this.onSeekRequested,
    required this.positionLabel,
    required this.durationLabel,
  });

  final double progress;
  final ValueChanged<double> onSeekRequested;
  final String positionLabel;
  final String durationLabel;

  @override
  State<_SpectralProgressBody> createState() => _SpectralProgressBodyState();
}

class _SpectralProgressBodyState extends State<_SpectralProgressBody> {
  static const double _thumbRadius = 8;

  double? _dragProgress;

  @override
  void didUpdateWidget(covariant _SpectralProgressBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pending = _dragProgress;
    if (pending == null) {
      return;
    }
    // Clear optimistic seek once controller progress catches up.
    if ((widget.progress - pending).abs() < 0.015) {
      _dragProgress = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = (_dragProgress ?? widget.progress)
        .clamp(0.0, 1.0)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final trackWidth = (w - (_thumbRadius * 2)).clamp(0.0, w);
            final maxDx = (_thumbRadius + trackWidth).toDouble();
            return Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    if (trackWidth <= 0) {
                      return;
                    }
                    final dx = details.localPosition.dx.clamp(
                      _thumbRadius,
                      maxDx,
                    );
                    final tappedProgress =
                        ((dx - _thumbRadius) / trackWidth).clamp(0.0, 1.0);
                    setState(() => _dragProgress = tappedProgress);
                    widget.onSeekRequested(tappedProgress);
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(
                          left: _thumbRadius,
                          child: Container(
                            width: trackWidth,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: AppColors.surfaceVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _thumbRadius,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: trackWidth * effectiveProgress,
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.spectralLavender,
                                      AppColors.spectralCyan,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.spectralCyan.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: _thumbRadius,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: AppColors.onSurface,
                    overlayColor: AppColors.spectralLavender.withValues(
                      alpha: 0.15,
                    ),
                  ),
                  child: Slider(
                    value: effectiveProgress,
                    onChanged: (value) {
                      setState(() => _dragProgress = value);
                    },
                    onChangeEnd: (value) {
                      setState(() => _dragProgress = value);
                      widget.onSeekRequested(value);
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.positionLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
            Text(
              widget.durationLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({
    required this.playing,
    required this.shuffle,
    required this.repeat,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onShuffle,
    required this.onRepeat,
  });

  final bool playing;
  final bool shuffle;
  final PlayerRepeatMode repeat;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final repeatColor = repeat == PlayerRepeatMode.off
        ? AppColors.onSurfaceVariant
        : AppColors.spectralLavender;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onShuffle,
          icon: Icon(
            Icons.shuffle_rounded,
            color: shuffle
                ? AppColors.spectralLavender
                : AppColors.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPrevious,
              iconSize: 40,
              icon: Icon(
                Icons.skip_previous_rounded,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.spectralLavender,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.spectralLavender.withValues(alpha: 0.4),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 44,
                  color: AppColors.onSpectralLavender,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onNext,
              iconSize: 40,
              icon: Icon(Icons.skip_next_rounded, color: AppColors.onSurface),
            ),
          ],
        ),
        IconButton(
          onPressed: onRepeat,
          icon: Icon(
            repeat == PlayerRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: repeatColor,
          ),
        ),
      ],
    );
  }
}

class _UtilityPills extends ConsumerWidget {
  const _UtilityPills();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerControllerProvider);

    return Row(
      children: [
        Expanded(
          child: _GlassPill(
            icon: Icons.timer_outlined,
            label: timer.active
                ? 'Timer ${formatSleepTimerMmSs(timer.remaining)}'
                : 'Sleep Timer',
            onTap: () => showSleepTimerBottomSheet(context, ref),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _GlassPill(
            icon: Icons.tune_rounded,
            label: 'Sound Mixer',
            onTap: () => context.go(AppRoute.mixer.path),
          ),
        ),
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: GlassCard(
          borderRadius: 999,
          useBackdropBlur: false,
          fillOpacity: 0.38,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.spectralCyan, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.onSurface.withValues(alpha: 0.92),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
