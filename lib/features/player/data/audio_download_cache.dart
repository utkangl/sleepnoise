import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Uzak sesler için isteğe bağlı dosya önbelleği. Oynatıcı başlatılırken **ağdan
/// indirme yapılmaz** — sadece daha önce indirilmiş geçerli dosya varsa kullanılır.
/// İndirmek için [prefetchToCache] çağrılır.
class AudioDownloadCache {
  AudioDownloadCache._();
  static final AudioDownloadCache instance = AudioDownloadCache._();

  final Map<String, Future<File>> _inFlight = {};

  static const _subDir = 'remote_audio_cache';

  Future<Directory> _ensureDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$_subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _audioPath(Directory dir, String trackId) =>
      '${dir.path}/$trackId.mp3';

  String _metaPath(Directory dir, String trackId) =>
      '${dir.path}/$trackId.url.txt';

  /// Diskte bu URL için geçerli önbellek varsa döner; yoksa `null` (ağ çağrısı yok).
  Future<File?> getCachedFileIfValid(String trackId, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }
    final dir = await _ensureDir();
    final audioFile = File(_audioPath(dir, trackId));
    final metaFile = File(_metaPath(dir, trackId));
    if (!await audioFile.exists() || !await metaFile.exists()) {
      return null;
    }
    final savedUrl = (await metaFile.readAsString()).trim();
    if (savedUrl != url.trim()) {
      return null;
    }
    final len = await audioFile.length();
    if (len <= 0) {
      return null;
    }
    return audioFile;
  }

  /// Arka planda veya “İndir” ile; tamamlanınca [getCachedFileIfValid] dosya döner.
  Future<File> prefetchToCache({
    required String trackId,
    required String url,
  }) {
    final key = trackId;
    return _inFlight[key] ??= _downloadLocked(trackId, url);
  }

  Future<File> _downloadLocked(String trackId, String url) async {
    try {
      return await _download(trackId, url);
    } finally {
      _inFlight.remove(trackId);
    }
  }

  Future<File> _download(String trackId, String url) async {
    final uri = Uri.parse(url.trim());
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw ArgumentError('Sadece http/https: $url');
    }

    final dir = await _ensureDir();
    final audioFile = File(_audioPath(dir, trackId));
    final metaFile = File(_metaPath(dir, trackId));

    await _deleteIfExists(audioFile);
    await _deleteIfExists(metaFile);

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 45), onTimeout: () {
      throw HttpException('Ses indirme zaman asimi', uri: uri);
    });
    if (response.statusCode != 200) {
      throw HttpException(
        'Ses indirilemedi (${response.statusCode})',
        uri: uri,
      );
    }
    if (response.bodyBytes.isEmpty) {
      throw HttpException('Bos ses yaniti', uri: uri);
    }

    await audioFile.writeAsBytes(response.bodyBytes, flush: true);
    await metaFile.writeAsString(url.trim(), flush: true);
    return audioFile;
  }

  Future<void> _deleteIfExists(File f) async {
    if (await f.exists()) {
      await f.delete();
    }
  }

  Future<void> clearAll() async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/$_subDir');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
