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
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Karışım',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
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
                ],
              ),
            ),
            // Mevcut karışımı favorilere kaydet (anlık seviyelerle birlikte).
            if (mix.activeLayerCount > 0) const _MixFavoriteButton(),
          ],
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

/// Karışımı (anlık seviyelerle) favorilere ekleyen yuvarlak buton.
/// Hazır mikslerde (loadedPresetId varsa) doğrudan o presetin favorisini
/// toggle eder; özel karışımlarda ise isim sorup yeni bir [UserSavedMix]
/// olarak kaydeder ve favori işaretler.
class _MixFavoriteButton extends ConsumerWidget {
  const _MixFavoriteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = ref.watch(mixerControllerProvider);
    final lib = ref.watch(libraryNotifierProvider);
    final libCtl = ref.read(libraryNotifierProvider.notifier);
    final presetId = mix.loadedPresetId;
    final isPresetFav =
        presetId != null && lib.favoritePresetMixIds.contains(presetId);

    return Material(
      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          if (presetId != null) {
            await libCtl.toggleFavoritePresetMix(presetId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isPresetFav
                      ? 'Favorilerden çıkarıldı'
                      : 'Favorilere eklendi',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
          final name = await showMixSaveNameDialog(context);
          if (!context.mounted || name == null || name.isEmpty) {
            return;
          }
          await libCtl.saveCurrentMixerMix(ref, name);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Favorilere eklendi: $name'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            isPresetFav
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: AppColors.spectralLavender,
          ),
        ),
      ),
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
