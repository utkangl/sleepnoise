import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'playback_owner_controller.dart';

/// True while any output is starting or audible (single-track or layered mix).
final anyPlaybackActiveProvider = Provider<bool>((ref) {
  final owner = ref.watch(playbackOwnerProvider);
  return owner != PlaybackOwner.none;
});

/// Bottom chrome (mini player) for the shell tab at [path].
/// Kartın görünürlüğü global: herhangi bir single veya mix çıktısı varsa gösterilir.
final shellPlaybackChromeVisibleProvider = Provider.family<bool, String>((
  ref,
  path,
) {
  final owner = ref.watch(playbackOwnerProvider);
  return owner != PlaybackOwner.none;
});
