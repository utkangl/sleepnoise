import 'dart:convert';

import '../domain/audio_track.dart';

/// `assets/data/audio_catalog.json` içeriğini [AudioTrack] listesine çevirir.
List<AudioTrack> parseAudioCatalogJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    return const [];
  }
  final arr = decoded['tracks'];
  if (arr is! List<dynamic>) {
    return const [];
  }
  final out = <AudioTrack>[];
  for (final item in arr) {
    if (item is! Map<String, dynamic>) {
      continue;
    }
    final t = audioTrackFromJson(item);
    if (t != null) {
      out.add(t);
    }
  }
  return out;
}

AudioTrack? audioTrackFromJson(Map<String, dynamic> j) {
  final id = j['id'] as String?;
  final title = j['title'] as String?;
  final subtitle = j['subtitle'] as String?;
  final category = j['category'] as String?;
  final license = j['license'] as String? ?? 'unknown';
  final artworkUrl = j['artworkUrl'] as String? ?? '';
  final audioUrl = j['audioUrl'] as String? ?? '';
  if (id == null || title == null || subtitle == null || category == null) {
    return null;
  }
  return AudioTrack(
    id: id,
    title: title,
    subtitle: subtitle,
    artworkUrl: artworkUrl,
    audioUrl: audioUrl,
    category: category,
    license: license,
    assetPath: j['assetPath'] as String?,
    sourceName: j['sourceName'] as String?,
    activeLayers: (j['activeLayers'] as num?)?.toInt(),
    mixable: j['mixable'] != false,
  );
}
