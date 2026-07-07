import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../catalogue/domain/artist.dart';

class ScanRepository {
  const ScanRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Artist?> searchFirstArtist(String query) async {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final json = await _apiClient.get('/search/artists?q=$encodedQuery');

    if (json is! Map<String, dynamic>) {
      throw const ApiException('Reponse recherche invalide.');
    }

    final artists = json['artists'];
    if (artists is! List || artists.isEmpty) return null;

    final first = artists.first;
    if (first is! Map) {
      throw const ApiException('Artiste recherche invalide.');
    }

    return Artist.fromJson(first.cast<String, dynamic>());
  }
}

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository(ref.watch(apiClientProvider));
});
