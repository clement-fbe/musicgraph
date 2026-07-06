import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalogue_repository.dart';
import '../domain/artist.dart';

/// ViewModel du catalogue (MVVM).
///
/// Expose un `AsyncValue<List<Artist>>` (loading / error / data) à la Vue.
/// La Vue s'y abonne ; elle ne connaît ni l'API ni le repository.
final catalogueProvider = FutureProvider<List<Artist>>((ref) {
  return ref.watch(catalogueRepositoryProvider).fetchArtists();
});
