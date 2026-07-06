import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/artist_detail.dart';

class ArtistDetailRepository {
  const ArtistDetailRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ArtistDetail> getArtistDetail(String mbid) async {
    final json = await _apiClient.get('/artists/$mbid');

    if (json is! Map<String, dynamic>) {
      throw const ApiException('Reponse detail artiste invalide.');
    }

    return ArtistDetail.fromJson(json);
  }
}

final artistDetailRepositoryProvider = Provider<ArtistDetailRepository>((ref) {
  return ArtistDetailRepository(ref.watch(apiClientProvider));
});
