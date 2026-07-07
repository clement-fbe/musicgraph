import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/shared_preferences_provider.dart';
import '../../catalogue/domain/artist.dart';

/// Persistance des artistes favoris via SharedPreferences (stockage JSON).
class FavoritesRepository {
  FavoritesRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'favorite_artists';

  /// Lecture protégée : en cas de JSON corrompu on renvoie une liste vide
  /// (on évite le crash — cf. cours).
  List<Artist> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Artist.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<Artist> favorites) async {
    final raw = jsonEncode(favorites.map((a) => a.toJson()).toList());
    await _prefs.setString(_key, raw);
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(sharedPreferencesProvider));
});
