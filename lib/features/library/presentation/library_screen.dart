import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:ui';

import '../../../core/navigation/tab_reselect_provider.dart';
import '../../../core/routing/app_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/sleeping_noise_app_bar.dart';
import '../../mixer/application/mixer_controller.dart';
import '../../mixer/domain/preset_mix.dart';
import '../../mixer/domain/preset_mix_catalog.dart';
import '../../player/application/audio_controller.dart';
import '../../player/application/playback_facade.dart';
import '../../player/application/playback_owner_controller.dart';
import '../../player/application/playback_visibility.dart';
import '../../player/domain/audio_catalog.dart';
import '../../catalog/application/remote_catalog_controller.dart';
import '../application/library_notifier.dart';
import '../application/track_download_controller.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );
  final _catalogScroll = ScrollController();
  final _favoritesScroll = ScrollController();

  @override
  void dispose() {
    _tabController.dispose();
    _catalogScroll.dispose();
    _favoritesScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(libraryNotifierProvider);
    listenLibraryTabScrollToTop(
      ref,
      AppRoute.library.path,
      _tabController,
      _catalogScroll,
      _favoritesScroll,
    );
    final chrome = ref.watch(
      shellPlaybackChromeVisibleProvider(AppRoute.library.path),
    );
    final mq = MediaQuery.paddingOf(context);
    const tabBarHeight = 48.0;
    final headerHeight = mq.top + SleepingNoiseAppBar.height + tabBarHeight;
    final bottomPad = mq.bottom + (chrome ? 210 : 100);

    return Stack(
      children: [
        Positioned(
          top: headerHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: TabBarView(
            controller: _tabController,
            children: [
              _LibraryCatalogTab(
                bottomPad: bottomPad,
                scrollController: _catalogScroll,
              ),
              _LibraryFavoritesTab(
                bottomPad: bottomPad,
                scrollController: _favoritesScroll,
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SafeArea(bottom: false, child: SleepingNoiseAppBar()),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: AppColors.surface.withValues(alpha: 0.18),
                    child: TabBar(
                      controller: _tabController,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LibraryCatalogTab extends ConsumerWidget {
  const _LibraryCatalogTab({
    required this.bottomPad,
    required this.scrollController,
  });

  final double bottomPad;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryNotifierProvider);
    final libCtl = ref.read(libraryNotifierProvider.notifier);
    final downloads = ref.watch(trackDownloadControllerProvider);
    final downloadCtl = ref.read(trackDownloadControllerProvider.notifier);
    final remoteCatalog = ref.watch(remoteCatalogProvider);
    final mixCtl = ref.read(mixerControllerProvider.notifier);
    final localTracks = featuredTracks;
    final downloadedRemoteTracks = remoteCatalog.maybeWhen(
      data: (items) => items
          .where(
            (t) =>
                downloads.statusFor(t.id).status ==
                TrackDownloadStatus.downloaded,
          )
          .toList(),
      orElse: () => const [],
    );
    final tracks = [...localTracks, ...downloadedRemoteTracks];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      downloadCtl.ensureHydrated(localTracks);
      remoteCatalog.whenData(downloadCtl.ensureHydrated);
    });

    return ListView(
      controller: scrollController,
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
          final isBuiltIn = t.assetPath != null && t.assetPath!.isNotEmpty;
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
                    onPressed: () async {
                      await libCtl.toggleFavoriteTrack(t.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Text(
                            fav
                                ? '${t.title} favorilerden çıkarıldı'
                                : '${t.title} favorilere eklendi',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: fav ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (t.assetPath == null || t.assetPath!.isEmpty)
                    Builder(
                      builder: (context) {
                        final status = downloads.statusFor(t.id).status;
                        final downloading =
                            status == TrackDownloadStatus.downloading;
                        final downloaded =
                            status == TrackDownloadStatus.downloaded;
                        return IconButton(
                          tooltip:
                              downloaded ? 'İndirilen dosyayı sil' : 'Cihaza indir',
                          onPressed: downloading
                              ? null
                              : () async {
                                  if (downloaded) {
                                    final audioState =
                                        ref.read(audioControllerProvider);
                                    if (audioState.currentTrack.id == t.id) {
                                      await ref
                                          .read(audioControllerProvider.notifier)
                                          .pause();
                                      ref
                                          .read(playbackOwnerProvider.notifier)
                                          .clear();
                                    }
                                    await downloadCtl.removeTrack(t);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        duration: const Duration(seconds: 1),
                                        content: Text(
                                          '${t.title} cihazdan silindi',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await downloadCtl.downloadTrack(t);
                                  if (!context.mounted) return;
                                  final nextStatus = ref
                                      .read(trackDownloadControllerProvider)
                                      .statusFor(t.id)
                                      .status;
                                  final ok =
                                      nextStatus == TrackDownloadStatus.downloaded;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 1),
                                      content: Text(
                                        ok
                                            ? '${t.title} indirildi'
                                            : '${t.title} indirilemedi',
                                      ),
                                    ),
                                  );
                                },
                          icon: downloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  downloaded
                                      ? Icons.delete_outline_rounded
                                      : Icons.download_rounded,
                                  color: downloaded
                                      ? AppColors.error
                                      : AppColors.onSurfaceVariant,
                                ),
                        );
                      },
                    ),
                  FilledButton.tonal(
                    onPressed: () {
                      if (isBuiltIn) {
                        playSingleSoundscape(
                          ref,
                          t.id,
                          openNowPlaying: context,
                        );
                        return;
                      }
                      playSingleTrack(
                        ref,
                        t,
                        openNowPlaying: context,
                      );
                    },
                    child: const Text('Çal'),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Text(
          'İndirilebilir katalog',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        remoteCatalog.when(
          data: (remoteTracks) {
            if (remoteTracks.isEmpty) {
              return Text(
                'Henüz uzak katalog içeriği yok.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              );
            }
            return Column(
              children: [
                for (final t in remoteTracks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      borderRadius: 14,
                      blurSigma: 8,
                      useBackdropBlur: false,
                      fillOpacity: 0.42,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                                  t.subtitle.isEmpty
                                      ? 'Uzak katalog sesi'
                                      : t.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final status = downloads.statusFor(t.id).status;
                              final downloading =
                                  status == TrackDownloadStatus.downloading;
                              final downloaded =
                                  status == TrackDownloadStatus.downloaded;
                              return IconButton(
                                tooltip: downloaded
                                    ? 'İndirilen dosyayı sil'
                                    : 'Cihaza indir',
                                onPressed: downloading
                                    ? null
                                    : () async {
                                        if (downloaded) {
                                          final audioState =
                                              ref.read(audioControllerProvider);
                                          if (audioState.currentTrack.id == t.id) {
                                            await ref
                                                .read(
                                                  audioControllerProvider.notifier,
                                                )
                                                .pause();
                                            ref
                                                .read(
                                                  playbackOwnerProvider.notifier,
                                                )
                                                .clear();
                                          }
                                          await downloadCtl.removeTrack(t);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              duration:
                                                  const Duration(seconds: 1),
                                              content: Text(
                                                '${t.title} cihazdan silindi',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        await downloadCtl.downloadTrack(t);
                                        if (!context.mounted) return;
                                        final nextStatus = ref
                                            .read(trackDownloadControllerProvider)
                                            .statusFor(t.id)
                                            .status;
                                        final ok = nextStatus ==
                                            TrackDownloadStatus.downloaded;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            duration:
                                                const Duration(seconds: 1),
                                            content: Text(
                                              ok
                                                  ? '${t.title} indirildi'
                                                  : '${t.title} indirilemedi',
                                            ),
                                          ),
                                        );
                                      },
                                icon: downloading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        downloaded
                                            ? Icons.delete_outline_rounded
                                            : Icons.download_rounded,
                                        color: downloaded
                                            ? AppColors.error
                                            : AppColors.onSurfaceVariant,
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stackTrace) => Text(
            'Uzak katalog alınamadı.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ),
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
  const _LibraryFavoritesTab({
    required this.bottomPad,
    required this.scrollController,
  });

  final double bottomPad;
  final ScrollController scrollController;

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
        controller: scrollController,
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
      controller: scrollController,
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
                        onPressed: () => playSingleSoundscape(
                          ref,
                          t.id,
                          openNowPlaying: context,
                        ),
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
