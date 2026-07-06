import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/artist.dart';

/// Couche Data du catalogue : récupère les artistes depuis l'API MusicGraph.
class CatalogueRepository {
  CatalogueRepository(this._api);

  final ApiClient _api;

  /// `GET /artists` → liste des artistes importés dans le graphe.
  /// Réponse attendue : `{"artists": [ {..}, {..} ]}`.
  Future<List<Artist>> fetchArtists() async {
    final json = await _api.get('/artists');
    final list = json is Map<String, dynamic> ? json['artists'] as List? : null;
    if (list == null) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Artist.fromJson)
        .toList(growable: false);
  }
}

final catalogueRepositoryProvider = Provider<CatalogueRepository>((ref) {
  return CatalogueRepository(ref.watch(apiClientProvider));
});
