import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../player/application/playback_owner_controller.dart';
import '../../player/application/audio_controller.dart';
import '../../player/data/track_audio_source.dart';
import '../../player/domain/audio_catalog.dart';
import '../../player/domain/audio_track.dart';
import '../../library/domain/user_saved_mix.dart';
import '../domain/mixable_tracks.dart';
import '../domain/preset_mix.dart';

const double _activeLevelThreshold = 1.0;

class MixerState {
  const MixerState({
    required this.levelsByTrackId,
    required this.mixPlaying,
    required this.mixLoading,
    required this.showInNowPlaying,
    this.loadedPresetId,
  });

  factory MixerState.initial() {
    final ids = mixableTrackIds();
    return MixerState(
      levelsByTrackId: {for (final id in ids) id: 0.0},
      mixPlaying: false,
      mixLoading: false,
      showInNowPlaying: false,
      loadedPresetId: null,
    );
  }

  final Map<String, double> levelsByTrackId;
  final bool mixPlaying;
  final bool mixLoading;
  final bool showInNowPlaying;

  /// Mevcut karışım, kataloğa ait bir hazır miks olarak yüklendiyse onun id'si;
  /// kullanıcı bir kanalı elle değiştirdiğinde sıfırlanır. UI bu alana bakarak
  /// "Karışımı kaydet" gibi gereksiz aksiyonları gizleyebilir.
  final String? loadedPresetId;

  int get activeLayerCount =>
      levelsByTrackId.values.where((v) => v > _activeLevelThreshold).length;

  MixerState copyWith({
    Map<String, double>? levelsByTrackId,
    bool? mixPlaying,
    bool? mixLoading,
    bool? showInNowPlaying,
    String? loadedPresetId,
    bool clearLoadedPresetId = false,
  }) {
    return MixerState(
      levelsByTrackId: levelsByTrackId ?? this.levelsByTrackId,
      mixPlaying: mixPlaying ?? this.mixPlaying,
      mixLoading: mixLoading ?? this.mixLoading,
      showInNowPlaying: showInNowPlaying ?? this.showInNowPlaying,
      loadedPresetId:
          clearLoadedPresetId ? null : (loadedPresetId ?? this.loadedPresetId),
    );
  }
}

final mixerControllerProvider =
    StateNotifierProvider<MixerController, MixerState>((ref) {
      return MixerController(ref);
    });

class MixerController extends StateNotifier<MixerState> {
  MixerController(this._ref) : super(MixerState.initial());

  final Ref _ref;
  final Map<String, AudioPlayer> _players = {};
  // Aynı trackId için aynı anda iki [_playerFor] çağrısı gelirse paylaşılan
  // [Future]'ı veririz; aksi halde iki ayrı [AudioPlayer] yaratılır ve haritaya
  // sonuncusu yazılır → ilk oynatıcı sızıntı şeklinde çalmaya devam eder.
  final Map<String, Future<AudioPlayer>> _pendingPlayerCreations = {};
  final Map<String, int> _volumeApplyGeneration = {};
  bool _playMixInFlight = false;

  /// [playMix] bitmeden yapılan iptal / duraklatma ile artırılır; eski [playMix]
  /// finally bloğu state’i ezmesin diye kullanılır.
  int _playMixToken = 0;

  void _invalidateAllVolumeApplies() {
    for (final id in mixableTrackIds()) {
      _volumeApplyGeneration[id] = (_volumeApplyGeneration[id] ?? 0) + 1;
    }
  }

  AudioTrack? _trackById(String id) {
    try {
      return featuredTracks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<AudioPlayer> _playerFor(String trackId) {
    final existing = _players[trackId];
    if (existing != null) {
      return Future<AudioPlayer>.value(existing);
    }
    final pending = _pendingPlayerCreations[trackId];
    if (pending != null) {
      return pending;
    }
    final future = _createPlayerForTrack(trackId);
    _pendingPlayerCreations[trackId] = future;
    return future.whenComplete(() {
      _pendingPlayerCreations.remove(trackId);
    });
  }

  Future<AudioPlayer> _createPlayerForTrack(String trackId) async {
    final track = _trackById(trackId);
    if (track == null) {
      throw StateError('Unknown track id: $trackId');
    }
    final player = AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
      androidApplyAudioAttributes: false,
    );
    final source = await audioSourceForTrack(track);
    await player.setAudioSource(source);
    await player.setLoopMode(LoopMode.all);
    _players[trackId] = player;
    return player;
  }

  Map<String, double> _levelsFromPreset(PresetMix preset) {
    final next = <String, double>{};
    for (final id in mixableTrackIds()) {
      next[id] = (preset.levels[id] ?? 0).clamp(0.0, 100.0);
    }
    return next;
  }

  void _syncAllChannelVolumesFromState() {
    _invalidateAllVolumeApplies();
    for (final id in mixableTrackIds()) {
      final v = state.levelsByTrackId[id] ?? 0;
      final gen = (_volumeApplyGeneration[id] ?? 0) + 1;
      _volumeApplyGeneration[id] = gen;
      unawaited(_applyVolumeForTrack(id, v, gen).catchError((Object _) {}));
    }
  }

  /// Hazır miksi yükler; [autoPlay] true ise (veya zaten mix çalıyorsa) sesleri günceller.
  Future<void> loadPresetMix(
    PresetMix preset, {
    bool autoPlay = true,
  }) async {
    if (state.mixLoading) {
      await _abortMixLoading();
    }

    final merged = _levelsFromPreset(preset);
    state = state.copyWith(
      levelsByTrackId: merged,
      loadedPresetId: preset.id,
    );

    final noActiveLayers = merged.values.every(
      (value) => value <= _activeLevelThreshold,
    );
    if (noActiveLayers) {
      _invalidateAllVolumeApplies();
      unawaited(_pauseEveryMixPlayer());
      _ref.read(playbackOwnerProvider.notifier).clear();
      state = state.copyWith(
        mixPlaying: false,
        mixLoading: false,
        showInNowPlaying: false,
      );
      return;
    }

    if (state.mixPlaying) {
      _ref.read(playbackOwnerProvider.notifier).activateMix();
      state = state.copyWith(showInNowPlaying: true);
      _syncAllChannelVolumesFromState();
      return;
    }

    if (autoPlay) {
      await playMix();
    }
  }

  /// Kütüphanede kayıtlı kullanıcı karışımı.
  Future<void> loadUserSavedMix(
    UserSavedMix mix, {
    bool autoPlay = true,
  }) async {
    final preset = PresetMix(
      id: mix.id,
      title: mix.name,
      subtitle: 'Kayıtlı karışım',
      levels: mix.levelsByTrackId,
    );
    await loadPresetMix(preset, autoPlay: autoPlay);
  }

  void setChannelLevel(String trackId, double percent) {
    final v = percent.clamp(0.0, 100.0).toDouble();
    final prev = state.levelsByTrackId[trackId] ?? 0;
    final next = Map<String, double>.from(state.levelsByTrackId);
    next[trackId] = v;
    // Kullanıcı eliyle bir kanalı oynattığı an, "yüklü hazır miks" bağlantısı
    // kopar; karışım artık özel.
    state = state.copyWith(
      levelsByTrackId: next,
      clearLoadedPresetId: true,
    );

    final noActiveLayers = next.values.every(
      (value) => value <= _activeLevelThreshold,
    );
    if (noActiveLayers) {
      _invalidateAllVolumeApplies();
      unawaited(_pauseEveryMixPlayer());
      _ref.read(playbackOwnerProvider.notifier).clear();
      state = state.copyWith(
        mixPlaying: false,
        mixLoading: false,
        showInNowPlaying: false,
      );
      return;
    }

    final newlyActivated =
        prev <= _activeLevelThreshold && v > _activeLevelThreshold;

    if (!state.mixPlaying) {
      // Duraklatılmış veya henüz oynatılmamış miks: state her zaman güncellenir;
      // ses motorunu da (sessiz veya tam oynatma) senkron tut.
      if (newlyActivated) {
        unawaited(ensureMixPlaying().catchError((Object _) {}));
      } else {
        final gen = (_volumeApplyGeneration[trackId] ?? 0) + 1;
        _volumeApplyGeneration[trackId] = gen;
        unawaited(
          _applyVolumeForTrack(
            trackId,
            v,
            gen,
            allowPlayback: false,
          ).catchError((Object _) {}),
        );
      }
      return;
    }

    final gen = (_volumeApplyGeneration[trackId] ?? 0) + 1;
    _volumeApplyGeneration[trackId] = gen;
    unawaited(_applyVolumeForTrack(trackId, v, gen).catchError((Object _) {}));
  }

  bool _isStale(String trackId, int gen) =>
      _volumeApplyGeneration[trackId] != gen;

  Future<void> _applyVolumeForTrack(
    String trackId,
    double percent,
    int gen, {
    bool allowPlayback = true,
  }) async {
    if (percent <= _activeLevelThreshold) {
      final player = _players[trackId];
      if (player != null) {
        // Sessize de al; geciken play() ile pause() arasındaki yarış sonrası
        // kanal yanlışlıkla açık kalırsa duyulmasın.
        try {
          await player.setVolume(0);
        } catch (_) {}
        try {
          await player.pause();
        } catch (_) {}
      }
      return;
    }
    final player = await _playerFor(trackId);
    if (_isStale(trackId, gen)) {
      await _reconcileChannelToState(trackId, player);
      return;
    }
    await player.setVolume(percent / 100.0);
    if (_isStale(trackId, gen)) {
      await _reconcileChannelToState(trackId, player);
      return;
    }
    await player.setLoopMode(LoopMode.all);
    if (_isStale(trackId, gen)) {
      await _reconcileChannelToState(trackId, player);
      return;
    }
    if (allowPlayback && !player.playing) {
      await player.play();
      // play() çözüldükten sonra kullanıcı çoktan 0'a çekmiş olabilir.
      if (_isStale(trackId, gen)) {
        await _reconcileChannelToState(trackId, player);
      }
    }
  }

  /// Stale callback son durumda kanalı 0'a çekmiş olabilir; oyuncuyu güncel
  /// state'e göre senkronize et (gerekiyorsa sessize alıp duraklat).
  Future<void> _reconcileChannelToState(
    String trackId,
    AudioPlayer player,
  ) async {
    final latest = state.levelsByTrackId[trackId] ?? 0;
    if (latest <= _activeLevelThreshold) {
      try {
        await player.setVolume(0);
      } catch (_) {}
      try {
        await player.pause();
      } catch (_) {}
    }
  }

  /// Stops layered mix; single-track player is unchanged until something else plays.
  Future<void> stopMix() async {
    _invalidateAllVolumeApplies();
    for (final p in _players.values) {
      await p.pause();
    }
    _ref.read(playbackOwnerProvider.notifier).clear();
    state = state.copyWith(
      mixPlaying: false,
      mixLoading: false,
      showInNowPlaying: false,
    );
  }

  Future<void> _pauseEveryMixPlayer() async {
    for (final p in _players.values) {
      try {
        await p.pause();
      } catch (_) {
        // Ara sıra platform pause hatası; diğer kanalları ve state güncellemesini engelleme.
      }
    }
  }

  Future<void> _resumeExistingMix() async {
    final levels = Map<String, double>.from(state.levelsByTrackId);
    final activeIds = mixableTrackIds()
        .where((id) => (levels[id] ?? 0) > _activeLevelThreshold)
        .toList();
    if (activeIds.isEmpty) {
      return;
    }
    // State'te 0 olan ama daha önce aktif olmuş oyuncular varsa sessize al
    // ve duraklat: aksi halde resume sonrası "kapatılmış" sesler tekrar duyulur.
    for (final id in mixableTrackIds()) {
      if ((levels[id] ?? 0) > _activeLevelThreshold) {
        continue;
      }
      final p = _players[id];
      if (p != null) {
        try {
          await p.setVolume(0);
        } catch (_) {}
        try {
          await p.pause();
        } catch (_) {}
      }
    }
    for (final id in activeIds) {
      final player = await _playerFor(id);
      await player.setVolume((levels[id] ?? 0) / 100.0);
      await player.setLoopMode(LoopMode.all);
      if (!player.playing) {
        unawaited(player.play());
      }
    }
    _ref.read(playbackOwnerProvider.notifier).activateMix();
    state = state.copyWith(
      mixPlaying: true,
      mixLoading: false,
      showInNowPlaying: true,
    );
  }

  Future<void> _startMixChannel(String trackId, double level) async {
    final player = await _playerFor(trackId);
    await player.setVolume(level / 100.0);
    await player.setLoopMode(LoopMode.all);
    unawaited(player.play());
  }

  Future<void> playMix() async {
    final levels = Map<String, double>.from(state.levelsByTrackId);
    final anyOn = levels.values.any((v) => v > _activeLevelThreshold);
    if (!anyOn) {
      return;
    }
    if (_playMixInFlight) {
      return;
    }
    final myToken = ++_playMixToken;
    _playMixInFlight = true;
    _ref.read(playbackOwnerProvider.notifier).activateMix();
    state = state.copyWith(
      mixLoading: true,
      mixPlaying: false,
      showInNowPlaying: true,
    );

    var success = false;
    try {
      await _ref.read(audioControllerProvider.notifier).stopForMix();

      for (final id in mixableTrackIds()) {
        if ((levels[id] ?? 0) > _activeLevelThreshold) {
          continue;
        }
        final p = _players[id];
        if (p != null) {
          try {
            await p.pause();
          } catch (_) {}
        }
      }

      final activeIds = mixableTrackIds()
          .where((id) => (levels[id] ?? 0) > _activeLevelThreshold)
          .toList();

      await Future.wait([
        for (final id in activeIds)
          _startMixChannel(id, levels[id] ?? 0),
      ]);
      // Abort sırasında token değiştiyse yükleme iptal; sessizce durdur.
      if (myToken != _playMixToken) {
        await _pauseEveryMixPlayer();
      } else {
        success = true;
      }
    } catch (_) {
      await _pauseEveryMixPlayer();
    } finally {
      _playMixInFlight = false;
      if (myToken == _playMixToken) {
        state = state.copyWith(
          mixPlaying: success,
          mixLoading: false,
          showInNowPlaying: success || state.activeLayerCount > 0,
        );
      }
    }
  }

  /// Yükleme sırasında kullanıcı duraklat / vazgeç dediğinde: yarım kalan
  /// [playMix] tamamlanınca state’i ezmesin diye token artırılır.
  Future<void> _abortMixLoading() async {
    _playMixToken++;
    _invalidateAllVolumeApplies();
    await _pauseEveryMixPlayer();
    _playMixInFlight = false;
    _ref.read(playbackOwnerProvider.notifier).activateMix();
    state = state.copyWith(
      mixLoading: false,
      mixPlaying: false,
      showInNowPlaying: state.activeLayerCount > 0,
    );
  }

  Future<void> toggleMixPlayPause() async {
    if (state.mixLoading) {
      await _abortMixLoading();
      return;
    }
    if (state.mixPlaying) {
      _invalidateAllVolumeApplies();
      await _pauseEveryMixPlayer();
      _ref.read(playbackOwnerProvider.notifier).activateMix();
      state = state.copyWith(
        mixPlaying: false,
        mixLoading: false,
        showInNowPlaying: true,
      );
      return;
    }
    if (_players.isNotEmpty) {
      await _resumeExistingMix();
      return;
    }
    await playMix();
  }

  Future<void> ensureMixPlaying() async {
    if (state.mixPlaying) {
      return;
    }
    if (_players.isNotEmpty) {
      await _resumeExistingMix();
      return;
    }
    await playMix();
  }

  void refreshFromPlayers() {
    final anyPlaying = _players.values.any((p) => p.playing);
    if (state.mixPlaying == anyPlaying && !state.mixLoading) {
      return;
    }
    state = state.copyWith(
      mixPlaying: anyPlaying,
      mixLoading: false,
      showInNowPlaying: anyPlaying || state.showInNowPlaying,
    );
  }

  bool get isMixAudible => state.mixPlaying;

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
    super.dispose();
  }
}
