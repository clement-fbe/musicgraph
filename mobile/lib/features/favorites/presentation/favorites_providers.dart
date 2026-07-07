import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalogue/domain/artist.dart';
import '../data/favorites_repository.dart';

/// ViewModel des favoris (MVVM).
///
/// Charge l'état initial depuis SharedPreferences puis persiste à chaque
/// modification. La Vue s'abonne à [favoritesProvider].
class FavoritesNotifier extends Notifier<List<Artist>> {
  @override
  List<Artist> build() => ref.read(favoritesRepositoryProvider).load();

  bool isFavorite(String mbid) => state.any((a) => a.mbid == mbid);

  Future<void> toggle(Artist artist) async {
    state = isFavorite(artist.mbid)
        ? state.where((a) => a.mbid != artist.mbid).toList(growable: false)
        : [...state, artist];
    await ref.read(favoritesRepositoryProvider).save(state);
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<Artist>>(FavoritesNotifier.new);

/// Indique si un artiste (par mbid) est en favori — rebuild ciblé pour les boutons.
final isFavoriteProvider = Provider.family<bool, String>((ref, mbid) {
  return ref.watch(favoritesProvider).any((a) => a.mbid == mbid);
});
