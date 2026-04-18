import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mixer/application/mixer_controller.dart';
import 'audio_controller.dart';
import 'playback_owner_controller.dart';

Future<void> playSingleSoundscape(WidgetRef ref, String trackId) async {
  await ref.read(mixerControllerProvider.notifier).stopMix();
  ref.read(playbackOwnerProvider.notifier).activateSingle();
  await ref.read(audioControllerProvider.notifier).playTrackById(trackId);
}

Future<void> toggleSinglePlayPause(WidgetRef ref) async {
  final audio = ref.read(audioControllerProvider.notifier);
  final playing = ref.read(audioControllerProvider).isPlaying;
  if (playing) {
    ref.read(playbackOwnerProvider.notifier).activateSingle();
    await audio.pause();
    return;
  }
  await ref.read(mixerControllerProvider.notifier).stopMix();
  ref.read(playbackOwnerProvider.notifier).activateSingle();
  await audio.togglePlayPause();
}

Future<void> playSingleNext(WidgetRef ref) async {
  await ref.read(mixerControllerProvider.notifier).stopMix();
  ref.read(playbackOwnerProvider.notifier).activateSingle();
  await ref.read(audioControllerProvider.notifier).playNext();
}

Future<void> playSinglePrevious(WidgetRef ref) async {
  await ref.read(mixerControllerProvider.notifier).stopMix();
  ref.read(playbackOwnerProvider.notifier).activateSingle();
  await ref.read(audioControllerProvider.notifier).playPrevious();
}
