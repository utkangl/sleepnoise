import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlaybackOwner { none, single, mix }

final playbackOwnerProvider =
    StateNotifierProvider<PlaybackOwnerController, PlaybackOwner>((ref) {
  return PlaybackOwnerController();
});

class PlaybackOwnerController extends StateNotifier<PlaybackOwner> {
  PlaybackOwnerController() : super(PlaybackOwner.none);

  void activateSingle() => state = PlaybackOwner.single;

  void activateMix() => state = PlaybackOwner.mix;

  void clear() => state = PlaybackOwner.none;
}
