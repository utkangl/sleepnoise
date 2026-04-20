import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/tab_reselect_provider.dart';
import '../../../core/routing/app_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/sleeping_noise_app_bar.dart';
import '../../library/application/library_notifier.dart';
import '../../mixer/application/mixer_controller.dart';
import '../../mixer/domain/preset_mix.dart';
import '../../mixer/domain/preset_mix_catalog.dart';
import '../../player/application/playback_facade.dart';
import '../../player/application/playback_visibility.dart';
import '../../player/domain/audio_catalog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    listenTabScrollToTop(ref, AppRoute.home.path, _scroll);
    final chrome = ref.watch(
      shellPlaybackChromeVisibleProvider(AppRoute.home.path),
    );
    final lib = ref.watch(libraryNotifierProvider);
    final mix = ref.watch(mixerControllerProvider);
    final mq = MediaQuery.paddingOf(context);
    final scrollAreaTop = mq.top + SleepingNoiseAppBar.height;
    final bottomPad = mq.bottom + (chrome ? 210 : 100);

    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final recommended = _recommendedPreset(now);
    final quickPresets = _pickQuickPresets(now);
    final favoriteSounds = featuredTracks
        .where((t) => lib.favoriteTrackIds.contains(t.id))
        .toList();

    return Stack(
      children: [
        Positioned(
          top: scrollAreaTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(24, 4, 24, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GreetingHeader(greeting: greeting),
                const SizedBox(height: 16),
                if (mix.activeLayerCount > 0) ...[
                  _ContinueMixCard(mix: mix),
                  const SizedBox(height: 16),
                ],
                _SectionLabel(label: 'Bu gece için öneri'),
                const SizedBox(height: 10),
                _RecommendedPresetCard(preset: recommended),
                const SizedBox(height: 20),
                _SectionLabel(label: 'Hızlı temalar'),
                const SizedBox(height: 10),
                _QuickPresetGrid(presets: quickPresets),
                const SizedBox(height: 18),
                _SectionLabel(label: 'Doğal sesler'),
                const SizedBox(height: 10),
                _SoundChipsRow(),
                if (favoriteSounds.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Favorilerin'),
                  const SizedBox(height: 10),
                  _FavoritesStrip(),
                ],
                const SizedBox(height: 8),
              ],
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

String _greetingForHour(int hour) {
  if (hour >= 22 || hour < 5) return 'İyi geceler';
  if (hour < 12) return 'Günaydın';
  if (hour < 18) return 'İyi günler';
  return 'İyi akşamlar';
}

/// Gün içinde sabit kalan, gece değişen bir önerilen miks: kullanıcı her gün
/// farklı bir keşif yaşasın diye katalog uzunluğuna göre döner.
PresetMix _recommendedPreset(DateTime now) {
  if (presetMixCatalog.isEmpty) {
    return const PresetMix(
      id: '_empty',
      title: 'Karışım',
      subtitle: 'Mixer’da kendin oluştur',
      levels: {},
    );
  }
  final dayIndex = now.year * 366 + now.month * 31 + now.day;
  return presetMixCatalog[dayIndex.abs() % presetMixCatalog.length];
}

List<PresetMix> _pickQuickPresets(DateTime now) {
  if (presetMixCatalog.length <= 4) return List.of(presetMixCatalog);
  final start =
      (now.year * 366 + now.month * 31 + now.day).abs() %
          presetMixCatalog.length;
  return [
    for (var i = 1; i <= 4; i++)
      presetMixCatalog[(start + i) % presetMixCatalog.length],
  ];
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOŞ GELDİN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
            children: [
              TextSpan(text: '$greeting, '),
              const TextSpan(
                text: 'rahatla.',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bu gece için sana özel bir karışım hazırladık.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: AppColors.onSurface,
      ),
    );
  }
}

/// Mixer'da hâlâ aktif katmanlar varsa: doğrudan oynatıcıya devam et.
class _ContinueMixCard extends ConsumerWidget {
  const _ContinueMixCard({required this.mix});

  final MixerState mix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = mix.mixPlaying;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push(AppRoute.nowPlaying.path);
        },
        child: GlassCard(
          borderRadius: 20,
          useBackdropBlur: false,
          fillOpacity: 0.5,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPlaying ? 'Karışımın çalıyor' : 'Karışıma devam et',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mix.activeLayerCount} aktif katman',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(mixerControllerProvider.notifier)
                    .toggleMixPlayPause(),
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(isPlaying ? 'Duraklat' : 'Oynat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedPresetCard extends ConsumerWidget {
  const _RecommendedPresetCard({required this.preset});

  final PresetMix preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _launch(context, ref),
        child: GlassCard(
          borderRadius: 24,
          useBackdropBlur: false,
          fillOpacity: 0.45,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFA88BFF), Color(0xFF6CD8FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      preset.icon,
                      color: AppColors.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUGÜNÜN ÖNERİSİ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                preset.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _launch(context, ref),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Çal'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go(AppRoute.mixer.path);
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Mixer'),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context, WidgetRef ref) async {
    await ref.read(mixerControllerProvider.notifier).loadPresetMix(preset);
    if (!context.mounted) return;
    context.push(AppRoute.nowPlaying.path);
  }
}

class _QuickPresetGrid extends ConsumerWidget {
  const _QuickPresetGrid({required this.presets});

  final List<PresetMix> presets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GridView.count'in ekran ölçeğine göre yarattığı yükseklik bazı
    // cihazlarda olduğundan büyük kalıyor ve "Hızlı temalar" ile "Doğal
    // sesler" başlıkları arasında dengesiz bir boşluk doğuruyordu. Manuel
    // Column+Row düzeniyle tile yüksekliğini tam olarak kontrol ediyoruz.
    const double tileHeight = 84;
    const double rowSpacing = 12;
    const double colSpacing = 12;

    Widget tile(PresetMix p) => SizedBox(
          height: tileHeight,
          child: _QuickPresetTile(
            preset: p,
            onTap: () async {
              await ref
                  .read(mixerControllerProvider.notifier)
                  .loadPresetMix(p);
              if (!context.mounted) return;
              context.push(AppRoute.nowPlaying.path);
            },
          ),
        );

    final rows = <Widget>[];
    for (var i = 0; i < presets.length; i += 2) {
      final left = presets[i];
      final right = (i + 1 < presets.length) ? presets[i + 1] : null;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: rowSpacing));
      rows.add(
        Row(
          children: [
            Expanded(child: tile(left)),
            const SizedBox(width: colSpacing),
            Expanded(
              child: right != null
                  ? tile(right)
                  : const SizedBox(height: tileHeight),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _QuickPresetTile extends StatelessWidget {
  const _QuickPresetTile({required this.preset, required this.onTap});

  final PresetMix preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassCard(
          borderRadius: 18,
          useBackdropBlur: false,
          fillOpacity: 0.42,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(preset.icon, color: AppColors.primary, size: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yatay kayan tek-ses başlatıcılar; tıklayınca mevcut karışımı durdurup
/// solo çalar.
class _SoundChipsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = featuredTracks;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = tracks[i];
          final icon = _iconForCategory(t.category);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () =>
                  playSingleSoundscape(ref, t.id, openNowPlaying: context),
              child: GlassCard(
                borderRadius: 18,
                useBackdropBlur: false,
                fillOpacity: 0.42,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: SizedBox(
                  width: 122,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: AppColors.primary, size: 22),
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoritesStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryNotifierProvider);
    final tracks = featuredTracks
        .where((t) => lib.favoriteTrackIds.contains(t.id))
        .toList();
    if (tracks.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = tracks[i];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () =>
                  playSingleSoundscape(ref, t.id, openNowPlaying: context),
              child: GlassCard(
                borderRadius: 999,
                useBackdropBlur: false,
                fillOpacity: 0.42,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.title,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  return switch (category) {
    'forest' => Icons.forest_rounded,
    'waterfall' => Icons.water_rounded,
    'ocean' => Icons.waves_rounded,
    'birds' => Icons.flutter_dash_rounded,
    'fire' => Icons.local_fire_department_rounded,
    _ => Icons.music_note_rounded,
  };
}
