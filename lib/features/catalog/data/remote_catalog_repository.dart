import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/remote_catalog_config.dart';
import '../../player/domain/audio_track.dart';

/// Supabase REST'ten uzak katalog çeker.
///
/// Beklenen kolonlar:
/// - id (uuid veya string)
/// - title (string)
/// - subtitle (string, optional)
/// - category (string)
/// - audio_url (string)  -> indirilecek dosya URL'i
/// - artwork_url (string, optional)
/// - license (string, optional)
/// - is_active (bool, optional; default true)
class RemoteCatalogRepository {
  const RemoteCatalogRepository();

  bool get isConfigured =>
      kRemoteCatalogBaseUrl.trim().isNotEmpty &&
      kRemoteCatalogAnonKey.trim().isNotEmpty;

  Future<List<AudioTrack>> fetchActiveTracks() async {
    if (!isConfigured) {
      return const [];
    }
    final base = kRemoteCatalogBaseUrl.trim();
    final table = kRemoteCatalogTable.trim().isEmpty
        ? 'tracks'
        : kRemoteCatalogTable.trim();
    final uri = Uri.parse(
      '$base/rest/v1/$table?select=id,title,subtitle,category,audio_url,artwork_url,license,is_active&is_active=eq.true&order=title.asc',
    );

    final response = await http.get(
      uri,
      headers: {
        'apikey': kRemoteCatalogAnonKey,
        'Authorization': 'Bearer $kRemoteCatalogAnonKey',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Remote katalog alınamadı (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    final out = <AudioTrack>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final id = (item['id'] ?? '').toString().trim();
      final title = (item['title'] ?? '').toString().trim();
      final audioUrl = (item['audio_url'] ?? '').toString().trim();
      if (id.isEmpty || title.isEmpty || audioUrl.isEmpty) {
        continue;
      }
      out.add(
        AudioTrack(
          id: id,
          title: title,
          subtitle: (item['subtitle'] ?? '').toString().trim(),
          artworkUrl: (item['artwork_url'] ?? '').toString().trim(),
          audioUrl: audioUrl,
          category: (item['category'] ?? 'remote').toString().trim(),
          license: (item['license'] ?? 'remote').toString().trim(),
          // Remote katalog parçaları indirilebilir olsun.
          assetPath: null,
          sourceName: 'remote_catalog',
          mixable: false,
        ),
      );
    }
    return out;
  }
}
