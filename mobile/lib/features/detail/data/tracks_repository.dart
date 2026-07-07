import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/artist_detail.dart';

/// Couche Data pour les titres : liste complète d'un artiste (paginée) et
/// titres d'un album.
class TracksRepository {
  TracksRepository(this._api);

  final ApiClient _api;

  static const int _pageSize = 50;
  static const int _maxPages = 20; // garde-fou (max 1000 titres)

  /// Récupère **tous** les titres d'un artiste en enchaînant les requêtes
  /// paginées (`/artists/{mbid}/recordings?limit&offset`) jusqu'à épuisement.
  Future<List<ArtistRecording>> fetchAllRecordings(String mbid) async {
    final all = <ArtistRecording>[];
    var offset = 0;
    for (var page = 0; page < _maxPages; page++) {
      final json = await _api.get(
        '/artists/$mbid/recordings?limit=$_pageSize&offset=$offset',
      );
      final list = json is Map<String, dynamic> ? json['recordings'] as List? : null;
      if (list == null || list.isEmpty) break;
      all.addAll(
        list.whereType<Map<String, dynamic>>().map(ArtistRecording.fromJson),
      );
      if (list.length < _pageSize) break; // dernière page
      offset += _pageSize;
    }
    return all;
  }

  /// Titres d'un album : `/albums/{spotifyId}/tracks`.
  Future<List<ArtistRecording>> fetchAlbumTracks(String albumSpotifyId) async {
    final json = await _api.get('/albums/$albumSpotifyId/tracks');
    final list = json is Map<String, dynamic> ? json['tracks'] as List? : null;
    if (list == null) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ArtistRecording.fromJson)
        .toList(growable: false);
  }
}

final tracksRepositoryProvider = Provider<TracksRepository>((ref) {
  return TracksRepository(ref.watch(apiClientProvider));
});

/// Tous les titres d'un artiste (par mbid).
final allRecordingsProvider =
    FutureProvider.autoDispose.family<List<ArtistRecording>, String>((ref, mbid) {
  return ref.watch(tracksRepositoryProvider).fetchAllRecordings(mbid);
});

/// Titres d'un album (par spotify_id).
final albumTracksProvider =
    FutureProvider.autoDispose.family<List<ArtistRecording>, String>((ref, albumId) {
  return ref.watch(tracksRepositoryProvider).fetchAlbumTracks(albumId);
});
