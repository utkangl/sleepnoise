import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../library/application/library_notifier.dart';
import '../../mixer/application/mixer_controller.dart';
import '../../mixer/application/mixer_mixable_catalog.dart';
import '../application/audio_controller.dart';
import '../application/playback_owner_controller.dart';
import '../application/playback_facade.dart';
import '../application/sleep_timer_controller.dart';
import 'widgets/expanded_mix_player_body.dart';
import 'widgets/looping_asset_video.dart';
import 'widgets/sleep_timer_bottom_sheet.dart';
import 'widgets/track_video_assets.dart';
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
  // NP açıldığında hangi modla açıldığını hatırla. Bu mod boyunca tek bir NP
  // gösteririz; kullanıcı modu değiştirirse veya kaynağı tamamen kapatırsa
  // ekran kendini kapatır. Sahibe (`PlaybackOwner`) doğrudan bağlanmıyoruz;
  // çünkü `toggleSinglePlayPause` gibi geçişlerde owner anlık olarak `none`
  // değerinden geçer ve bu, ekranı yanlışlıkla kapatır.
  _NowPlayingMode? _mode;

  // Single modda NP ilk açıldığında bir kez auto-resume tetikleyelim.
  bool _autoResumeChecked = false;

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(playbackOwnerProvider);

    // Modu ilk anlamlı owner ile sabitle; sonra sadece "modu sona eren"
    // koşullarda kapat. Böylece mix NP açıkken miks tamamen kapanırsa
    // (= aktif katman 0 ve oynatma yok) NP kapanır; tek-ses modunda ise
    // play/pause sırasında yaşanan anlık owner=none kapatma yapmaz.
    if (_mode == null) {
      if (owner == PlaybackOwner.mix) {
        _mode = _NowPlayingMode.mix;
      } else if (owner == PlaybackOwner.single) {
        _mode = _NowPlayingMode.single;
      }
    }

    if (_mode == _NowPlayingMode.mix) {
      // Mix modunda: kullanıcı tüm sesleri kapatsa bile NP açık kalsın
      // (kullanıcı tekrar açabilmeli). Sadece yeni bir tek-ses başlatılırsa
      // (owner = single) NP'yi kapatıp single NP'nin açılışına yer veririz.
      final switchedToSingle = owner == PlaybackOwner.single;
      if (switchedToSingle) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.canPop()) {
            context.pop();
          }
        });
      }
    }

    // Single modunda otomatik kapatma yok; kullanıcı pause edip play
    // yapabilmeli. Mix'e geçiş olursa (mix başlatılırsa) NP'yi yenilemek
    // yerine kullanıcının manuel akışına bırakıyoruz.

    // NP single modda açıldığında ses durmuş olabilir (örn. mini player'dan
    // gelinmiş veya başka bir kaynak araya girmiş). Yüklenirken/loading
    // durumunda dokunmuyoruz; ama owner=single ve isPlaying=false ise bir
    // kez play tetikliyoruz ki kullanıcı NP'yi açar açmaz oynatma görsün.
    if (_mode == _NowPlayingMode.single && !_autoResumeChecked) {
      _autoResumeChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final st = ref.read(audioControllerProvider);
        if (!st.isPlaying && !st.isLoading) {
          ref.read(playbackOwnerProvider.notifier).activateSingle();
          unawaited(
            ref
                .read(audioControllerProvider.notifier)
                .playTrackById(st.currentTrack.id),
          );
        }
      });
    }

    // Hangi UI'nın gösterileceği `_mode`a göre belirlenir; owner anlık olarak
    // none olabilse de kullanıcı NP'yi mix olarak açtıysa mix UI'da kalır.
    final showMix = _mode == _NowPlayingMode.mix;

    if (showMix) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _PlayerMeshBackdrop(),
            const _NowPlayingMixVideoBackdrop(),
            const _NowPlayingScrim(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: _PlayerAppBar(
                          title: 'Karışım',
                          onClose: () => context.pop(),
                        ),
                      ),
                    ),
                  ),
                  // İçeriği aşağı doğru hizalamak için reverse:true; küçük
                  // ekranlarda overflow olursa kullanıcı yukarı kaydırabilir.
                  Expanded(
                    child: SingleChildScrollView(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: const ExpandedMixPlayerBody(),
                        ),
                      ),
                    ),
                  ),
                ],
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
          _NowPlayingSingleVideoBackdrop(
            trackId: state.currentTrack.id,
            category: state.currentTrack.category,
            isPlaying: state.isPlaying,
          ),
          const _NowPlayingScrim(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: _PlayerAppBar(
                        title: 'Şu an çalıyor',
                        onClose: () => context.pop(),
                      ),
                    ),
                  ),
                ),
                // Ortadaki büyük yuvarlak (album art + glow) kaldırıldığı
                // için içerikleri ekranın alt yarısına yaklaştırıyoruz;
                // arka plan video görsel kimliği zaten taşıyor.
                Expanded(
                  child: SingleChildScrollView(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TrackRow(
                              title: state.currentTrack.title,
                              subtitle: state.currentTrack.subtitle,
                              loved: library.favoriteTrackIds
                                  .contains(state.currentTrack.id),
                              onToggleLove: () => ref
                                  .read(libraryNotifierProvider.notifier)
                                  .toggleFavoriteTrack(
                                    state.currentTrack.id,
                                  ),
                            ),
                            const SizedBox(height: 22),
                            _SpectralProgressSection(
                              progress: state.progress,
                              onSeekRequested: (v) =>
                                  controller.seekToProgress(v),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _NowPlayingMode { mix, single }

String _fmtDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Aktif (level > eşik) katmanların videolarını sırayla gösterir. Sabit
/// süreli timer yok: bitişe [_crossfadeLeadIn] kadar süre kala sıradaki video
/// yüklenir; böylece crossfade mevcut klibin son saniyeleriyle üst üste biner.
/// Yedek olarak klip tam bittiğinde de geçiş tetiklenebilir. Tek aktif
/// katmanda video loop'lanır.
class _NowPlayingMixVideoBackdrop extends ConsumerStatefulWidget {
  const _NowPlayingMixVideoBackdrop();

  @override
  ConsumerState<_NowPlayingMixVideoBackdrop> createState() =>
      _NowPlayingMixVideoBackdropState();
}

class _NowPlayingMixVideoBackdropState
    extends ConsumerState<_NowPlayingMixVideoBackdrop> {
  static const _fadeDuration = Duration(milliseconds: 2400);

  /// Crossfade süresinden biraz uzun: sonraki video init + opacity geçişi
  /// sırasında mevcut klip hâlâ oynasın.
  static const _crossfadeLeadIn = Duration(milliseconds: 3000);

  List<String> _activeIds = const [];
  int _activeIndex = 0;

  /// İndirilmiş uzak parçalar da kategorilerine (ör. 'fire', 'waterfall')
  /// göre video alır; bu harita `_computeActive` ile birlikte güncellenir ve
  /// slotlara asset çözerken kullanılır.
  Map<String, String> _idToAsset = const {};

  // Çift slot: biri görünür, diğeri sıradaki için crossfade. Aynı asset'in
  // yeniden init edilmesini önlemek için sabit ValueKey'ler kullanılır.
  bool _slotAIsCurrent = true;
  String? _slotAAsset;
  String? _slotBAsset;

  // Yeni asset slota yerleşti ama controller henüz init olmadıysa fade'i
  // başlatmıyoruz; aksi halde kısa bir an "video yok" arka planı görünür.
  // Yeni slot ready olduğunda flip'i [_commitFlip] uygular.
  bool _pendingFlip = false;
  Timer? _pendingFlipFallback;

  @override
  void initState() {
    super.initState();
    final mix = ref.read(mixerControllerProvider);
    final tracks = ref.read(mixerMixableTracksProvider);
    _idToAsset = _buildIdToAsset(tracks);
    _applyActiveList(_computeActive(mix));
  }

  Map<String, String> _buildIdToAsset(List<dynamic> tracks) {
    final map = <String, String>{};
    for (final t in tracks) {
      final asset = resolveTrackVideoAsset(
        trackId: t.id as String,
        category: t.category as String,
      );
      if (asset != null) {
        map[t.id as String] = asset;
      }
    }
    return map;
  }

  List<String> _computeActive(MixerState mix) => [
        for (final id in _idToAsset.keys)
          if ((mix.levelsByTrackId[id] ?? 0) > 1.0) id,
      ];

  String? _idForAsset(String? asset) {
    if (asset == null) return null;
    for (final e in _idToAsset.entries) {
      if (e.value == asset) return e.key;
    }
    return null;
  }

  void _applyActiveList(List<String> next) {
    if (listEquals(next, _activeIds)) return;
    setState(() {
      _activeIds = next;
      if (next.isEmpty) {
        return;
      }

      final currentAsset = _slotAIsCurrent ? _slotAAsset : _slotBAsset;
      final currentId = _idForAsset(currentAsset);

      if (currentId == null || !next.contains(currentId)) {
        _activeIndex = 0;
        final firstAsset = _idToAsset[next[0]];
        if (_slotAIsCurrent) {
          _slotAAsset = firstAsset;
        } else {
          _slotBAsset = firstAsset;
        }
      } else {
        _activeIndex = next.indexOf(currentId);
      }

      // Pre-loading yok: ikinci decoder'ı sadece geçiş gerektiğinde mount
      // ederiz. Tek aktifte de diğer slot boş kalır.
      if (_slotAIsCurrent) {
        _slotBAsset = null;
      } else {
        _slotAAsset = null;
      }
    });
  }

  /// Bitişe yaklaşıldı → sıradaki videoyu yükle; crossfade mevcut oynatmayla
  /// üst üste biner.
  void _onCurrentCrossfadeLeadIn(bool isSlotA) {
    if (!mounted || _pendingFlip) return;
    final isCurrent =
        (isSlotA && _slotAIsCurrent) || (!isSlotA && !_slotAIsCurrent);
    if (!isCurrent) return;
    if (_activeIds.length <= 1) return;
    _cycle();
  }

  /// Görünen slot'un videosu sona erdi (yedek sinyal).
  void _onCurrentVideoCompleted(bool isSlotA) {
    if (!mounted || _pendingFlip) return;
    final isCurrent =
        (isSlotA && _slotAIsCurrent) || (!isSlotA && !_slotAIsCurrent);
    if (!isCurrent) return;
    if (_activeIds.length <= 1) return; // Tek video → loop, geçiş yok.
    _cycle();
  }

  void _cycle() {
    if (!mounted || _activeIds.length <= 1) return;
    if (_pendingFlip) return;
    setState(() {
      _activeIndex = (_activeIndex + 1) % _activeIds.length;
      final nextAsset = _idToAsset[_activeIds[_activeIndex]];
      // Yeni asset'i mevcut OLMAYAN slota yerleştir; fakat hemen flip etme.
      // Yeni video ready olunca [_onSlotReady] crossfade'i tetikleyecek.
      if (_slotAIsCurrent) {
        _slotBAsset = nextAsset;
      } else {
        _slotAAsset = nextAsset;
      }
      _pendingFlip = true;
    });
    // Güvenlik ağı: ready sinyali bir nedenle gelmezse 5 sn sonra yine de
    // geçiş yapılır.
    _pendingFlipFallback?.cancel();
    _pendingFlipFallback = Timer(const Duration(seconds: 5), _commitFlip);
  }

  void _onSlotReady(bool isSlotA) {
    if (!_pendingFlip || !mounted) return;
    // Yeni asset, mevcut olmayan slotta. O slot ready olunca commit et.
    final newSlotIsA = !_slotAIsCurrent;
    if (isSlotA != newSlotIsA) return;
    _commitFlip();
  }

  void _commitFlip() {
    if (!mounted || !_pendingFlip) return;
    _pendingFlipFallback?.cancel();
    _pendingFlipFallback = null;
    setState(() {
      _pendingFlip = false;
      _slotAIsCurrent = !_slotAIsCurrent;
    });
    // Crossfade bitince eski slotu unmount et: çoğu zaman tek decoder kalır,
    // CPU/GPU yükü düşer. Yine de kullanıcı bu süre içinde aktif katman
    // listesini değiştirirse [_applyActiveList] doğrudan slotları yönetir.
    Future.delayed(_fadeDuration + const Duration(milliseconds: 250), () {
      if (!mounted || _activeIds.length <= 1) return;
      setState(() {
        if (_slotAIsCurrent) {
          _slotBAsset = null;
        } else {
          _slotAAsset = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _pendingFlipFallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mix = ref.watch(mixerControllerProvider);
    final mixableTracks = ref.watch(mixerMixableTracksProvider);
    final rebuilt = _buildIdToAsset(mixableTracks);
    if (!mapEquals(rebuilt, _idToAsset)) {
      _idToAsset = rebuilt;
    }
    final next = _computeActive(mix);
    if (!listEquals(next, _activeIds)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyActiveList(next);
      });
    }

    // Mix yüklenirken videoyu duraklatma; sadece tamamen pause olduğunda dur.
    final shouldRun =
        (mix.mixPlaying || mix.mixLoading) && _activeIds.isNotEmpty;

    // Birden fazla aktif katman varsa video bitince geçeceğiz → loop=false.
    // Tek aktifte sürekli aynı görüntü → loop=true.
    final loop = _activeIds.length <= 1;

    // Her iki slot da mount olduğu sürece oynar. Böylece crossfade boyunca
    // giden slot **durmaz** (son karede donmaz); fade sona erdikten sonra
    // [_commitFlip] zaten eski slotu unmount ediyor. "Pause + fade" hissi
    // yerine gerçek bir crossfade elde ederiz.
    final playA = shouldRun && _slotAAsset != null;
    final playB = shouldRun && _slotBAsset != null;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_slotAAsset != null)
            LoopingAssetVideo(
              key: const ValueKey('mix_video_slot_a'),
              asset: _slotAAsset!,
              shouldPlay: playA,
              opacity: _slotAIsCurrent ? 1.0 : 0.0,
              fadeDuration: _fadeDuration,
              loop: loop,
              // Yalnızca mevcut (görünür) slot bitiş sinyallerini tetiklesin;
              // gizli ama oynayan kopya cycle’ı çift tetiklemesin.
              endCrossfadeLeadIn: !loop ? _crossfadeLeadIn : null,
              onEndCrossfadeLeadIn: !loop && _slotAIsCurrent
                  ? () => _onCurrentCrossfadeLeadIn(true)
                  : null,
              onReady: () => _onSlotReady(true),
              onCompleted: !loop && _slotAIsCurrent
                  ? () => _onCurrentVideoCompleted(true)
                  : null,
            ),
          if (_slotBAsset != null)
            LoopingAssetVideo(
              key: const ValueKey('mix_video_slot_b'),
              asset: _slotBAsset!,
              shouldPlay: playB,
              opacity: !_slotAIsCurrent ? 1.0 : 0.0,
              fadeDuration: _fadeDuration,
              loop: loop,
              endCrossfadeLeadIn: !loop ? _crossfadeLeadIn : null,
              onEndCrossfadeLeadIn: !loop && !_slotAIsCurrent
                  ? () => _onCurrentCrossfadeLeadIn(false)
                  : null,
              onReady: () => _onSlotReady(false),
              onCompleted: !loop && !_slotAIsCurrent
                  ? () => _onCurrentVideoCompleted(false)
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Tekli oynatıcı için arka plan video: kategori/track id eşleşirse oynatılır.
class _NowPlayingSingleVideoBackdrop extends StatelessWidget {
  const _NowPlayingSingleVideoBackdrop({
    required this.trackId,
    required this.category,
    required this.isPlaying,
  });

  final String trackId;
  final String category;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final asset = resolveTrackVideoAsset(trackId: trackId, category: category);
    if (asset == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: LoopingAssetVideo(
        asset: asset,
        shouldPlay: isPlaying,
        opacity: 1.0,
      ),
    );
  }
}

/// Video üstüne yumuşak vignette + alt-koyulaşma; UI okunaklı kalsın diye.
class _NowPlayingScrim extends StatelessWidget {
  const _NowPlayingScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.45),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
