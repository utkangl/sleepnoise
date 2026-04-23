import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/domain/audio_track.dart';
import '../data/remote_catalog_repository.dart';

final remoteCatalogRepositoryProvider = Provider<RemoteCatalogRepository>((ref) {
  return const RemoteCatalogRepository();
});

final remoteCatalogProvider = FutureProvider<List<AudioTrack>>((ref) async {
  final repo = ref.watch(remoteCatalogRepositoryProvider);
  return repo.fetchActiveTracks();
});
