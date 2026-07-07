import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalogue/domain/artist.dart';
import '../../catalogue/presentation/catalogue_providers.dart';
import '../data/search_repository.dart';

/// Requête de recherche courante (pilotée par le champ texte).
class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);

/// Résultats de recherche pour la requête courante (AsyncValue).
final searchResultsProvider = FutureProvider.autoDispose<List<Artist>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref.watch(searchRepositoryProvider).search(query);
});

/// Contrôleur d'import : suit les mbid en cours d'import (pour l'UI) et
/// rafraîchit le catalogue une fois l'artiste importé.
class ImportController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool isImporting(String mbid) => state.contains(mbid);

  Future<void> importArtist(Artist artist) async {
    if (state.contains(artist.mbid)) return;
    state = {...state, artist.mbid};
    try {
      await ref.read(searchRepositoryProvider).importArtist(artist);
      // Le catalogue (bibliothèque) doit refléter le nouvel artiste.
      ref.invalidate(catalogueProvider);
    } finally {
      state = state.where((m) => m != artist.mbid).toSet();
    }
  }
}

final importControllerProvider =
    NotifierProvider<ImportController, Set<String>>(ImportController.new);
