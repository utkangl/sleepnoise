import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/domain/audio_track.dart';
import '../../player/data/audio_download_cache.dart';

enum TrackDownloadStatus { idle, downloading, downloaded, failed }

class TrackDownloadItemState {
  const TrackDownloadItemState({
    required this.status,
    this.errorMessage,
  });

  final TrackDownloadStatus status;
  final String? errorMessage;

  TrackDownloadItemState copyWith({
    TrackDownloadStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TrackDownloadItemState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TrackDownloadState {
  const TrackDownloadState({required this.byTrackId});

  factory TrackDownloadState.initial() => const TrackDownloadState(byTrackId: {});

  final Map<String, TrackDownloadItemState> byTrackId;

  TrackDownloadItemState statusFor(String trackId) =>
      byTrackId[trackId] ?? const TrackDownloadItemState(status: TrackDownloadStatus.idle);

  TrackDownloadState copyWith({
    Map<String, TrackDownloadItemState>? byTrackId,
  }) {
    return TrackDownloadState(byTrackId: byTrackId ?? this.byTrackId);
  }
}

final trackDownloadControllerProvider =
    StateNotifierProvider<TrackDownloadController, TrackDownloadState>((ref) {
      return TrackDownloadController();
    });

class TrackDownloadController extends StateNotifier<TrackDownloadState> {
  TrackDownloadController() : super(TrackDownloadState.initial());

  final Set<String> _hydratedTrackIds = <String>{};

  bool _isRemoteHttpUrl(String s) {
    final u = Uri.tryParse(s.trim());
    return u != null &&
        u.hasScheme &&
        (u.scheme == 'http' || u.scheme == 'https');
  }

  Future<void> refreshTrack(AudioTrack track) async {
    final url = track.audioUrl.trim();
    if (!_isRemoteHttpUrl(url)) {
      return;
    }
    final cached = await AudioDownloadCache.instance.getCachedFileIfValid(track.id, url);
    _setStatus(
      track.id,
      cached == null ? TrackDownloadStatus.idle : TrackDownloadStatus.downloaded,
      clearError: true,
    );
  }

  Future<void> ensureHydrated(List<AudioTrack> tracks) async {
    for (final track in tracks) {
      if (_hydratedTrackIds.contains(track.id)) {
        continue;
      }
      await refreshTrack(track);
      _hydratedTrackIds.add(track.id);
    }
  }

  Future<void> downloadTrack(AudioTrack track) async {
    if (track.assetPath != null && track.assetPath!.isNotEmpty) {
      _setStatus(
        track.id,
        TrackDownloadStatus.failed,
        errorMessage: 'Bu ses uygulama ile birlikte geliyor; indirme gerekmez.',
      );
      return;
    }
    final url = track.audioUrl.trim();
    if (!_isRemoteHttpUrl(url)) {
      _setStatus(
        track.id,
        TrackDownloadStatus.failed,
        errorMessage: 'Bu ses için indirilebilir uzak dosya yok.',
      );
      return;
    }
    _setStatus(track.id, TrackDownloadStatus.downloading, clearError: true);
    try {
      await AudioDownloadCache.instance.prefetchToCache(trackId: track.id, url: url);
      _setStatus(track.id, TrackDownloadStatus.downloaded, clearError: true);
    } catch (e) {
      _setStatus(
        track.id,
        TrackDownloadStatus.failed,
        errorMessage: 'İndirme başarısız: $e',
      );
    }
  }

  Future<void> removeTrack(AudioTrack track) async {
    await AudioDownloadCache.instance.removeTrack(track.id);
    _setStatus(track.id, TrackDownloadStatus.idle, clearError: true);
  }

  void _setStatus(
    String trackId,
    TrackDownloadStatus status, {
    String? errorMessage,
    bool clearError = false,
  }) {
    final next = Map<String, TrackDownloadItemState>.from(state.byTrackId);
    final prev = next[trackId] ?? const TrackDownloadItemState(status: TrackDownloadStatus.idle);
    next[trackId] = prev.copyWith(
      status: status,
      errorMessage: errorMessage,
      clearError: clearError,
    );
    state = state.copyWith(byTrackId: next);
  }
}
