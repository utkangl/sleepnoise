import '../../player/domain/audio_catalog.dart';
import '../../player/domain/audio_track.dart';

/// Mikserde kanal olarak gösterilecek parçalar. [AudioTrack.mixable] ile kontrol edilir;
/// linkten eklenen sesler için JSON’da `"mixable": true` yeterli.
List<String> mixableTrackIds() =>
    featuredTracks.where((t) => t.mixable).map((t) => t.id).toList();

List<AudioTrack> mixableTracks() =>
    featuredTracks.where((t) => t.mixable).toList();
