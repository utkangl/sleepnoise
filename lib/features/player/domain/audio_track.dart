class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.audioUrl,
    required this.category,
    required this.license,
    this.assetPath,
    this.sourceName,
    this.activeLayers,
    /// Uzak / linkten gelen parçalar da `true` yapılarak mikserde kullanılabilir.
    this.mixable = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final String artworkUrl;
  final String audioUrl;
  final String category;
  final String license;
  final String? assetPath;
  final String? sourceName;
  final int? activeLayers;
  final bool mixable;
}
