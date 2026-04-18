import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routing/app_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/sleeping_noise_app_bar.dart';
import '../../mixer/application/mixer_controller.dart';
import '../../mixer/domain/preset_mix.dart';
import '../../mixer/domain/preset_mix_catalog.dart';
import '../../player/application/playback_facade.dart';
import '../../player/application/playback_visibility.dart';
import '../../player/domain/audio_catalog.dart';
import '../application/library_notifier.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(libraryNotifierProvider);
    final chrome = ref.watch(
      shellPlaybackChromeVisibleProvider(AppRoute.library.path),
    );
    final bottomPad =
        MediaQuery.paddingOf(context).bottom + (chrome ? 210 : 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SafeArea(bottom: false, child: SleepingNoiseAppBar()),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'Katalog'),
                    Tab(text: 'Favoriler'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _LibraryCatalogTab(bottomPad: bottomPad),
                      _LibraryFavoritesTab(bottomPad: bottomPad),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryCatalogTab extends ConsumerWidget {
  const _LibraryCatalogTab({required this.bottomPad});

  final double bottomPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryNotifierProvider);
    final libCtl = ref.read(libraryNotifierProvider.notifier);
    final mixCtl = ref.read(mixerControllerProvider.notifier);
    final tracks = featuredTracks;

    return ListView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad),
      children: [
        Text(
          'Sesler',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        ...tracks.map((t) {
          final fav = lib.favoriteTrackIds.contains(t.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              borderRadius: 14,
              blurSigma: 8,
              useBackdropBlur: false,
              fillOpacity: 0.42,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          t.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: fav ? 'Favoriden çıkar' : 'Favorilere ekle',
                    onPressed: () => libCtl.toggleFavoriteTrack(t.id),
                    icon: Icon(
                      fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: fav ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => playSingleSoundscape(ref, t.id),
                    child: const Text('Çal'),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        Text(
          'Hazır mikslar',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        ...presetMixCatalog.map((PresetMix p) {
          final fav = lib.favoritePresetMixIds.contains(p.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              borderRadius: 14,
              blurSigma: 8,
              useBackdropBlur: false,
              fillOpacity: 0.42,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(p.icon, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          p.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: fav ? 'Favoriden çıkar' : 'Favorilere ekle',
                    onPressed: () => libCtl.toggleFavoritePresetMix(p.id),
                    icon: Icon(
                      fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: fav ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      await mixCtl.loadPresetMix(p);
                      if (context.mounted) {
                        context.go(AppRoute.mixer.path);
                      }
                    },
                    child: const Text('Yükle'),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        Text(
          'Kayıtlı miksim',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Miks ekranından veya tam ekran oynatıcıdan “Kaydet” ile eklenir.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        if (lib.savedMixes.isEmpty)
          Text(
            'Henüz kayıtlı miks yok.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          )
        else
          ...lib.savedMixes.map((m) {
            final fav = lib.favoriteSavedMixIds.contains(m.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                borderRadius: 14,
                blurSigma: 8,
                useBackdropBlur: false,
                fillOpacity: 0.42,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Kayıtlı karışım',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: fav ? 'Favoriden çıkar' : 'Favorilere ekle',
                      onPressed: () =>
                          libCtl.toggleFavoriteSavedMix(m.id),
                      icon: Icon(
                        fav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                            fav ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () => libCtl.deleteSavedMix(m.id),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        await mixCtl.loadUserSavedMix(m);
                        if (context.mounted) {
                          context.go(AppRoute.mixer.path);
                        }
                      },
                      child: const Text('Yükle'),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _LibraryFavoritesTab extends ConsumerWidget {
  const _LibraryFavoritesTab({required this.bottomPad});

  final double bottomPad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryNotifierProvider);
    final libCtl = ref.read(libraryNotifierProvider.notifier);
    final mixCtl = ref.read(mixerControllerProvider.notifier);
    final tracks = featuredTracks;

    final favTracks =
        tracks.where((t) => lib.favoriteTrackIds.contains(t.id)).toList();
    final favPresets = presetMixCatalog
        .where((p) => lib.favoritePresetMixIds.contains(p.id))
        .toList();
    final favSaved =
        lib.savedMixes.where((m) => lib.favoriteSavedMixIds.contains(m.id)).toList();

    final empty = favTracks.isEmpty && favPresets.isEmpty && favSaved.isEmpty;

    if (empty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(24, 32, 24, bottomPad),
        children: [
          Text(
            'Henüz favori yok.\nKatalog sekmesinden ses veya miks yıldızlayabilirsin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad),
      children: [
        if (favTracks.isNotEmpty) ...[
          Text(
            'Sesler',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ...favTracks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  borderRadius: 14,
                  blurSigma: 8,
                  useBackdropBlur: false,
                  fillOpacity: 0.42,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => libCtl.toggleFavoriteTrack(t.id),
                        icon: const Icon(Icons.favorite_rounded,
                            color: AppColors.primary),
                      ),
                      FilledButton.tonal(
                        onPressed: () => playSingleSoundscape(ref, t.id),
                        child: const Text('Çal'),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
        ],
        if (favPresets.isNotEmpty) ...[
          Text(
            'Hazır mikslar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ...favPresets.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  borderRadius: 14,
                  blurSigma: 8,
                  useBackdropBlur: false,
                  fillOpacity: 0.42,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(p.icon, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            libCtl.toggleFavoritePresetMix(p.id),
                        icon: const Icon(Icons.favorite_rounded,
                            color: AppColors.primary),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          await mixCtl.loadPresetMix(p);
                          if (context.mounted) {
                            context.go(AppRoute.mixer.path);
                          }
                        },
                        child: const Text('Yükle'),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
        ],
        if (favSaved.isNotEmpty) ...[
          Text(
            'Kayıtlı miksim',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ...favSaved.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  borderRadius: 14,
                  blurSigma: 8,
                  useBackdropBlur: false,
                  fillOpacity: 0.42,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            libCtl.toggleFavoriteSavedMix(m.id),
                        icon: const Icon(Icons.favorite_rounded,
                            color: AppColors.primary),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          await mixCtl.loadUserSavedMix(m);
                          if (context.mounted) {
                            context.go(AppRoute.mixer.path);
                          }
                        },
                        child: const Text('Yükle'),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }
}
