import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/artist_detail_repository.dart';
import '../domain/artist_detail.dart';

final artistDetailViewModelProvider = FutureProvider.autoDispose
    .family<ArtistDetail, String>((ref, mbid) {
      return ref.watch(artistDetailRepositoryProvider).getArtistDetail(mbid);
    });
