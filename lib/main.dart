import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/audio/app_audio_session.dart';
import 'features/player/data/audio_catalog_loader.dart';
import 'features/player/domain/audio_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureSleepingNoiseAudioSession();
  try {
    final raw = await rootBundle.loadString('assets/data/audio_catalog.json');
    final parsed = parseAudioCatalogJson(raw);
    if (parsed.isNotEmpty) {
      setAudioCatalogTracks(parsed);
    }
  } catch (_) {
    // JSON yok / bozuksa [builtInFeaturedTracks] kullanılır.
  }
  runApp(const ProviderScope(child: SleepingNoiseApp()));
}
