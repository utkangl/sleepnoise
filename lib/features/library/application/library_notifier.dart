import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mixer/application/mixer_controller.dart';
import '../domain/user_saved_mix.dart';

const _prefsKey = 'sleeping_noise_library_v1';

class LibraryState {
  const LibraryState({
    required this.favoriteTrackIds,
    required this.favoritePresetMixIds,
    required this.favoriteSavedMixIds,
    required this.savedMixes,
  });

  factory LibraryState.initial() => const LibraryState(
        favoriteTrackIds: {},
        favoritePresetMixIds: {},
        favoriteSavedMixIds: {},
        savedMixes: [],
      );

  final Set<String> favoriteTrackIds;
  final Set<String> favoritePresetMixIds;
  final Set<String> favoriteSavedMixIds;
  final List<UserSavedMix> savedMixes;

  LibraryState copyWith({
    Set<String>? favoriteTrackIds,
    Set<String>? favoritePresetMixIds,
    Set<String>? favoriteSavedMixIds,
    List<UserSavedMix>? savedMixes,
  }) {
    return LibraryState(
      favoriteTrackIds: favoriteTrackIds ?? this.favoriteTrackIds,
      favoritePresetMixIds:
          favoritePresetMixIds ?? this.favoritePresetMixIds,
      favoriteSavedMixIds: favoriteSavedMixIds ?? this.favoriteSavedMixIds,
      savedMixes: savedMixes ?? this.savedMixes,
    );
  }

  Map<String, dynamic> toJson() {
    final t = [...favoriteTrackIds]..sort();
    final p = [...favoritePresetMixIds]..sort();
    final s = [...favoriteSavedMixIds]..sort();
    return {
      'favTracks': t,
      'favPresets': p,
      'favSaved': s,
      'saved': savedMixes.map((e) => e.toJson()).toList(),
    };
  }

  factory LibraryState.fromJson(Map<String, dynamic> j) {
    final favT = (j['favTracks'] as List<dynamic>?)?.cast<String>() ?? [];
    final favP = (j['favPresets'] as List<dynamic>?)?.cast<String>() ?? [];
    final favS = (j['favSaved'] as List<dynamic>?)?.cast<String>() ?? [];
    final saved = <UserSavedMix>[];
    final rawSaved = j['saved'] as List<dynamic>?;
    if (rawSaved != null) {
      for (final item in rawSaved) {
        if (item is Map<String, dynamic>) {
          try {
            saved.add(UserSavedMix.fromJson(item));
          } catch (_) {}
        }
      }
    }
    return LibraryState(
      favoriteTrackIds: favT.toSet(),
      favoritePresetMixIds: favP.toSet(),
      favoriteSavedMixIds: favS.toSet(),
      savedMixes: saved,
    );
  }
}

final libraryNotifierProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier() : super(LibraryState.initial()) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = LibraryState.fromJson(map);
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  Future<void> toggleFavoriteTrack(String trackId) async {
    final next = Set<String>.from(state.favoriteTrackIds);
    if (next.contains(trackId)) {
      next.remove(trackId);
    } else {
      next.add(trackId);
    }
    state = state.copyWith(favoriteTrackIds: next);
    await _persist();
  }

  Future<void> toggleFavoritePresetMix(String presetId) async {
    final next = Set<String>.from(state.favoritePresetMixIds);
    if (next.contains(presetId)) {
      next.remove(presetId);
    } else {
      next.add(presetId);
    }
    state = state.copyWith(favoritePresetMixIds: next);
    await _persist();
  }

  Future<void> toggleFavoriteSavedMix(String savedMixId) async {
    final next = Set<String>.from(state.favoriteSavedMixIds);
    if (next.contains(savedMixId)) {
      next.remove(savedMixId);
    } else {
      next.add(savedMixId);
    }
    state = state.copyWith(favoriteSavedMixIds: next);
    await _persist();
  }

  /// [levelsByTrackId] mixer’daki tam harita (tüm kanallar).
  Future<void> saveMixFromLevels(
    Map<String, double> levelsByTrackId,
    String name, {
    bool addToFavorites = true,
  }) async {
    final id = 'mix_${DateTime.now().microsecondsSinceEpoch}';
    final mix = UserSavedMix(
      id: id,
      name: name.trim().isEmpty ? 'Karışım' : name.trim(),
      levelsByTrackId: Map<String, double>.from(levelsByTrackId),
      savedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    final nextSaved = List<UserSavedMix>.from(state.savedMixes)..add(mix);
    var fav = Set<String>.from(state.favoriteSavedMixIds);
    if (addToFavorites) {
      fav.add(id);
    }
    state = state.copyWith(
      savedMixes: nextSaved,
      favoriteSavedMixIds: fav,
    );
    await _persist();
  }

  Future<void> deleteSavedMix(String id) async {
    final nextSaved = state.savedMixes.where((m) => m.id != id).toList();
    final fav = Set<String>.from(state.favoriteSavedMixIds)..remove(id);
    state = state.copyWith(
      savedMixes: nextSaved,
      favoriteSavedMixIds: fav,
    );
    await _persist();
  }

  /// Mixer ekranından: anlık seviyeleri kaydet.
  Future<void> saveCurrentMixerMix(
    WidgetRef ref,
    String name, {
    bool addToFavorites = true,
  }) async {
    final mix = ref.read(mixerControllerProvider);
    final levels = Map<String, double>.from(mix.levelsByTrackId);
    const threshold = 1.0;
    if (levels.values.every((v) => v <= threshold)) {
      return;
    }
    await saveMixFromLevels(levels, name, addToFavorites: addToFavorites);
  }
}
