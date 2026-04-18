import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../library/application/library_notifier.dart';
import '../../../library/presentation/mix_name_dialog.dart';
import '../../../mixer/application/mixer_controller.dart';
import '../../../mixer/domain/mixable_tracks.dart';
import '../../application/sleep_timer_controller.dart';
import '../../domain/audio_catalog.dart';
import 'sleep_timer_bottom_sheet.dart';

class ExpandedMixPlayerBody extends ConsumerWidget {
  const ExpandedMixPlayerBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = ref.watch(mixerControllerProvider);
    final mixCtl = ref.read(mixerControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        _MixArtHeader(activeLayers: mix.activeLayerCount),
        const SizedBox(height: 14),
        Text(
          'Karışım',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (mix.mixLoading && !mix.mixPlaying)
              ? 'Sesler hazırlanıyor…'
              : '${mix.activeLayerCount} aktif katman',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        if (mix.mixLoading && !mix.mixPlaying)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else
          ...mixableTrackIds().map((id) {
            final track = featuredTracks.firstWhere((t) => t.id == id);
            final value = (mix.levelsByTrackId[id] ?? 0).clamp(0, 100).toDouble();
            final pct = value.round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                borderRadius: 12,
                useBackdropBlur: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                          ),
                        ),
                        Text(
                          '$pct%',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: value,
                        min: 0,
                        max: 100,
                        onChanged: (v) => mixCtl.setChannelLevel(id, v),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.spectralLavender,
              boxShadow: [
                BoxShadow(
                  color: AppColors.spectralLavender.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => mixCtl.toggleMixPlayPause(),
              icon: Icon(
                mix.mixLoading
                    ? Icons.stop_circle_outlined
                    : (mix.mixPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                size: 32,
                color: AppColors.onSpectralLavender,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: mix.activeLayerCount == 0
              ? null
              : () async {
                  final name = await showMixSaveNameDialog(context);
                  if (!context.mounted || name == null || name.isEmpty) {
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
          label: const Text('Karışımı kaydet'),
        ),
        const SizedBox(height: 14),
        const _MixSleepTimerPill(),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.pop();
              context.go(AppRoute.mixer.path);
            },
            borderRadius: BorderRadius.circular(999),
            child: GlassCard(
              borderRadius: 999,
              useBackdropBlur: false,
              fillOpacity: 0.38,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.spectralCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MIXER EKRANINA DÖN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.onSurface.withValues(alpha: 0.92),
                    ),
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

class _MixSleepTimerPill extends ConsumerWidget {
  const _MixSleepTimerPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerControllerProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showSleepTimerBottomSheet(
              context,
              ref,
              idleSubtitle:
                  'Bu karışım seçtiğin sürede otomatik dursun.',
            ),
        borderRadius: BorderRadius.circular(999),
        child: GlassCard(
          borderRadius: 999,
          useBackdropBlur: false,
          fillOpacity: 0.38,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                color: AppColors.spectralCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                timer.active
                    ? 'TIMER ${formatSleepTimerMmSs(timer.remaining)}'
                    : 'SLEEP TIMER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.onSurface.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MixArtHeader extends StatelessWidget {
  const _MixArtHeader({required this.activeLayers});

  final int activeLayers;

  @override
  Widget build(BuildContext context) {
    const outer = 168.0;
    const ring = 152.0;
    const inner = 138.0;
    return Center(
      child: SizedBox(
        width: outer,
        height: outer,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: ring,
              height: ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.spectralLavender.withValues(alpha: 0.3),
                    blurRadius: 28,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: inner,
              height: inner,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x66A88BFF), Color(0x6681ECFF)],
                ),
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: const Color(0xFF1B2A4A),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.layers_rounded,
                        size: 44,
                        color: AppColors.onSurface,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeLayers katman',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
