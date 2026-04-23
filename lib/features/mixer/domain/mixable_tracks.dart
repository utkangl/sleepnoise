import '../../player/domain/audio_catalog.dart';
import '../../player/domain/audio_track.dart';

/// Sadece paket içi, JSON ile işaretlenmiş miklenebilir parçalar.
/// Uzak + indirilmiş kanallar için [mixerMixableTracksProvider] kullanılır.
List<String> builtInMixableTrackIds() =>
    featuredTracks.where((t) => t.mixable).map((t) => t.id).toList();

List<AudioTrack> builtInMixableTracks() =>
    featuredTracks.where((t) => t.mixable).toList();
