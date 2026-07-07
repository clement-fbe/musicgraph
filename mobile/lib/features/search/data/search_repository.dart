import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../catalogue/domain/artist.dart';

/// Couche Data de la recherche : interroge l'API (Spotify) et importe dans Neo4j.
class SearchRepository {
  SearchRepository(this._api);

  final ApiClient _api;

  /// Timeout allongé pour les opérations lentes (import + enrichissement).
  static const Duration _longTimeout = Duration(seconds: 60);

  /// `GET /search/artists?q=` → résultats de recherche (source Spotify).
  Future<List<Artist>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final json = await _api.get('/search/artists?q=${Uri.encodeQueryComponent(q)}');
    final list = json is Map<String, dynamic> ? json['artists'] as List? : null;
    if (list == null) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Artist.fromJson)
        .toList(growable: false);
  }

  /// Importe un artiste dans Neo4j puis l'enrichit (photo, albums, collaborations),
  /// en reproduisant le flux du front web : import → enrich → enrichSpotify.
  Future<void> importArtist(Artist artist) async {
    await _api.post(
      '/import/artists',
      timeout: _longTimeout,
      body: {
        'mbid': artist.mbid,
        'name': artist.name,
        'country': artist.country,
        'type': artist.type,
        'disambiguation': artist.disambiguation,
        'begin_date': artist.beginDate,
      },
    );
    // Collaborations / recordings (peut échouer sans bloquer l'import).
    await _api.post(
      '/enrich/artists',
      timeout: _longTimeout,
      body: {'mbid': artist.mbid, 'fetch_recordings': true},
    );
    // Photo + pochettes d'albums via Spotify.
    await _api.post(
      '/enrich/spotify',
      timeout: _longTimeout,
      body: {'mbid': artist.mbid},
    );
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(apiClientProvider));
});
