/// Kullanıcının kaydettiği özel karışım (kanal seviyeleri).
class UserSavedMix {
  const UserSavedMix({
    required this.id,
    required this.name,
    required this.levelsByTrackId,
    required this.savedAtMillis,
  });

  final String id;
  final String name;
  final Map<String, double> levelsByTrackId;
  final int savedAtMillis;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'levels': levelsByTrackId.map((k, v) => MapEntry(k, v)),
        'savedAt': savedAtMillis,
      };

  factory UserSavedMix.fromJson(Map<String, dynamic> j) {
    final rawLevels = j['levels'];
    final levels = <String, double>{};
    if (rawLevels is Map<String, dynamic>) {
      for (final e in rawLevels.entries) {
        final n = e.value;
        if (n is num) {
          levels[e.key] = n.toDouble();
        }
      }
    }
    return UserSavedMix(
      id: j['id'] as String,
      name: j['name'] as String,
      levelsByTrackId: levels,
      savedAtMillis: (j['savedAt'] as num?)?.toInt() ?? 0,
    );
  }
}
