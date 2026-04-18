import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/track_audio_source.dart';
import '../domain/audio_catalog.dart';
import '../domain/audio_track.dart';

enum PlayerRepeatMode { off, all, one }

class AudioPlayerState {
  const AudioPlayerState({
    required this.playlist,
    required this.currentIndex,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    required this.shuffleEnabled,
    required this.repeatMode,
    this.errorMessage,
  });

  factory AudioPlayerState.initial() => AudioPlayerState(
        playlist: List<AudioTrack>.from(featuredTracks),
        currentIndex: 0,
        isPlaying: false,
        isLoading: true,
        position: Duration.zero,
        duration: Duration.zero,
        shuffleEnabled: false,
        repeatMode: PlayerRepeatMode.off,
      );

  final List<AudioTrack> playlist;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final bool shuffleEnabled;
  final PlayerRepeatMode repeatMode;
  final String? errorMessage;

  AudioTrack get currentTrack => playlist[currentIndex];
  bool get hasNext => currentIndex < playlist.length - 1;
  bool get hasPrevious => currentIndex > 0;

  double get progress {
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) {
      return 0;
    }
    return (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }

  AudioPlayerState copyWith({
    List<AudioTrack>? playlist,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    bool? shuffleEnabled,
    PlayerRepeatMode? repeatMode,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AudioPlayerState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

final audioControllerProvider =
    StateNotifierProvider<AudioController, AudioPlayerState>((ref) {
      return AudioController();
    });

class AudioController extends StateNotifier<AudioPlayerState> {
  AudioController() : super(AudioPlayerState.initial()) {
    _ready = _init();
  }

  /// İlk frame’de tıklanırsa [setAudioSources] bitmeden [seek]/[play] çalışmayabilir;
  /// hep ilk parça (index 0) çalınıyormuş gibi görünür.
  late final Future<void> _ready;

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void> _ensureReady() async {
    await _ready;
  }

  Future<void> _init() async {
    _subscriptions.addAll([
      _player.playerStateStream.listen((playerState) {
        state = state.copyWith(
          isPlaying: playerState.playing,
          isLoading:
              playerState.processingState == ProcessingState.loading ||
              playerState.processingState == ProcessingState.buffering,
        );
      }),
      _player.positionStream.listen((position) {
        state = state.copyWith(position: position);
      }),
      _player.durationStream.listen((duration) {
        state = state.copyWith(duration: duration ?? Duration.zero);
      }),
      _player.currentIndexStream.listen((index) {
        if (index == null) {
          return;
        }
        state = state.copyWith(currentIndex: index, position: Duration.zero);
      }),
      _player.shuffleModeEnabledStream.listen((enabled) {
        state = state.copyWith(shuffleEnabled: enabled);
      }),
      _player.loopModeStream.listen((mode) {
        state = state.copyWith(repeatMode: _toRepeatMode(mode));
      }),
    ]);

    try {
      final sources = <AudioSource>[];
      for (final track in state.playlist) {
        sources.add(await audioSourceForTrack(track));
      }
      await _player.setAudioSources(sources, initialIndex: state.currentIndex);
      final duration = _player.duration ?? Duration.zero;
      state = state.copyWith(
        duration: duration,
        isLoading: false,
        clearErrorMessage: true,
      );
    } catch (_) {
      try {
        final fallback = <AudioSource>[];
        for (final track in state.playlist) {
          fallback.add(await audioSourceUriOnlyFallback(track));
        }
        await _player.setAudioSources(
          fallback,
          initialIndex: state.currentIndex,
        );
        final duration = _player.duration ?? Duration.zero;
        state = state.copyWith(
          duration: duration,
          isLoading: false,
          clearErrorMessage: true,
        );
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Audio stream could not be loaded.',
        );
      }
    }
  }

  Future<void> pause() async {
    await _ensureReady();
    await _player.pause();
  }

  void refreshFromPlayer() {
    final playerState = _player.playerState;
    state = state.copyWith(
      isPlaying: playerState.playing,
      isLoading:
          playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering,
      position: _player.position,
      duration: _player.duration ?? state.duration,
    );
  }

  /// Tamamen durdurur; mixer’daki birden fazla oynatıcı için native çıkışı serbest bırakır.
  Future<void> stopForMix() async {
    await _ensureReady();
    await _player.stop();
  }

  Future<void> togglePlayPause() async {
    await _ensureReady();
    if (state.isPlaying) {
      await _player.pause();
      return;
    }
    await _player.play();
  }

  Future<void> playTrackById(String trackId) async {
    await _ensureReady();
    final index = state.playlist.indexWhere((track) => track.id == trackId);
    if (index < 0) {
      return;
    }
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  Future<void> playNext() async {
    await _ensureReady();
    if (!state.hasNext) {
      return;
    }
    await _player.seekToNext();
    await _player.play();
  }

  Future<void> playPrevious() async {
    await _ensureReady();
    if (state.position > const Duration(seconds: 4)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (!state.hasPrevious) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.seekToPrevious();
    await _player.play();
  }

  Future<void> seekToProgress(double progress) async {
    await _ensureReady();
    final duration = state.duration;
    if (duration <= Duration.zero) {
      return;
    }
    final clamped = progress.clamp(0.0, 1.0);
    final targetMs = (duration.inMilliseconds * clamped).round();
    await _player.seek(Duration(milliseconds: targetMs));
  }

  Future<void> toggleShuffle() async {
    await _ensureReady();
    final nextEnabled = !state.shuffleEnabled;
    if (nextEnabled) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(nextEnabled);
  }

  Future<void> cycleRepeatMode() async {
    await _ensureReady();
    final next = switch (state.repeatMode) {
      PlayerRepeatMode.off => LoopMode.all,
      PlayerRepeatMode.all => LoopMode.one,
      PlayerRepeatMode.one => LoopMode.off,
    };
    await _player.setLoopMode(next);
  }

  PlayerRepeatMode _toRepeatMode(LoopMode mode) {
    return switch (mode) {
      LoopMode.off => PlayerRepeatMode.off,
      LoopMode.all => PlayerRepeatMode.all,
      LoopMode.one => PlayerRepeatMode.one,
    };
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
