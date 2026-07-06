import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalogue/domain/artist.dart';
import '../data/scan_repository.dart';
import '../domain/scan_payload.dart';

class ScanViewModel extends Notifier<AsyncValue<Artist?>> {
  @override
  AsyncValue<Artist?> build() => const AsyncData(null);

  Future<Artist> resolve(String rawValue) async {
    state = const AsyncLoading();

    try {
      final payload = ScanPayload.parse(rawValue);
      final searchResult = await ref
          .read(scanRepositoryProvider)
          .searchFirstArtist(payload.query);
      final artist =
          searchResult ??
          (payload.hasSpotifyArtistId
              ? Artist(mbid: payload.spotifyArtistId!, name: 'Artiste Spotify')
              : null);

      if (artist == null || artist.mbid.isEmpty) {
        throw const ScanPayloadException('Aucun artiste trouve.');
      }

      state = AsyncData(artist);
      return artist;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final scanViewModelProvider =
    NotifierProvider<ScanViewModel, AsyncValue<Artist?>>(ScanViewModel.new);
