import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/application/remote_catalog_controller.dart';
import '../../library/application/track_download_controller.dart';
import '../../player/domain/audio_catalog.dart';
import '../../player/domain/audio_track.dart';

/// Mikserde kanal olarak gösterilen parçalar: yerleşik [AudioTrack.mixable]
/// olanlar + uzak katalogdan **indirilmiş** sesler (dosya önbelleği üzerinden
/// çalınır; indirilmemiş uzak parça mikse konmaz).
final mixerMixableTracksProvider = Provider<List<AudioTrack>>((ref) {
  final builtIn = featuredTracks.where((t) => t.mixable).toList();
  final remoteAsync = ref.watch(remoteCatalogProvider);
  final remote = remoteAsync.valueOrNull ?? const <AudioTrack>[];
  final downloads = ref.watch(trackDownloadControllerProvider);
  final downloadedRemote = remote
      .where(
        (t) =>
            downloads.statusFor(t.id).status == TrackDownloadStatus.downloaded,
      )
      .toList();

  final seen = <String>{};
  final out = <AudioTrack>[];
  for (final t in builtIn) {
    if (seen.add(t.id)) {
      out.add(t);
    }
  }
  for (final t in downloadedRemote) {
    if (seen.add(t.id)) {
      out.add(t);
    }
  }
  return out;
});
