import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_download_cache.dart';
import '../domain/audio_track.dart';

bool _isRemoteHttpUrl(String s) {
  final u = Uri.tryParse(s.trim());
  return u != null &&
      u.hasScheme &&
      (u.scheme == 'http' || u.scheme == 'https');
}

/// Gömülü asset → dosya. Uzak URL: önce disk önbelleği (varsa), yoksa **URI
/// stream** (playlist başlatmayı bloklamaz). İndirme için [AudioDownloadCache.prefetchToCache].
Future<AudioSource> audioSourceForTrack(AudioTrack track) async {
  final assetPath = track.assetPath;
  if (assetPath != null && assetPath.isNotEmpty) {
    try {
      await rootBundle.load(assetPath);
      return AudioSource.asset(assetPath, tag: track.id);
    } catch (_) {
      // Pakette yok; URL’ye düş.
    }
  }

  final url = track.audioUrl.trim();
  if (url.isNotEmpty && _isRemoteHttpUrl(url)) {
    final cached =
        await AudioDownloadCache.instance.getCachedFileIfValid(track.id, url);
    if (cached != null) {
      return AudioSource.file(cached.path, tag: track.id);
    }
    return AudioSource.uri(Uri.parse(url), tag: track.id);
  }

  if (url.isNotEmpty) {
    return AudioSource.uri(Uri.parse(url), tag: track.id);
  }

  throw StateError('Ses kaynagi yok: ${track.id}');
}

/// [setAudioSources] ilk denemede patlarsa yedek: mümkün olduğunca URI stream.
Future<AudioSource> audioSourceUriOnlyFallback(AudioTrack track) async {
  final url = track.audioUrl.trim();
  if (url.isNotEmpty) {
    return AudioSource.uri(Uri.parse(url), tag: track.id);
  }
  final assetPath = track.assetPath;
  if (assetPath != null && assetPath.isNotEmpty) {
    await rootBundle.load(assetPath);
    return AudioSource.asset(assetPath, tag: track.id);
  }
  throw StateError('Ses kaynagi yok: ${track.id}');
}
