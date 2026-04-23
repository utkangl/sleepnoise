/// Her track id için döngülü arka plan videosu. Tüm temel katmanların
/// kendi videosu var; yeni track eklenirse buraya satır eklemek yeterli.
const Map<String, String> kTrackVideoAssets = {
  'ocean': 'assets/video/ocean.mp4',
  'waterfall': 'assets/video/waterfall.mp4',
  'birds': 'assets/video/birds.mp4',
  'forest': 'assets/video/forest.mp4',
  'fire': 'assets/video/fire.mp4',
};

/// Önce track id ile dener; yoksa kategoriye göre video bulur.
String? resolveTrackVideoAsset({
  required String trackId,
  required String category,
}) {
  final byId = kTrackVideoAssets[trackId];
  if (byId != null) return byId;
  final normalizedCategory = category.trim().toLowerCase();
  if (normalizedCategory.isEmpty) return null;
  return kTrackVideoAssets[normalizedCategory];
}
