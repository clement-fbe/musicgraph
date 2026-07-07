import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tracks_repository.dart';
import 'track_tile.dart';

/// Page (empilée par-dessus la fiche artiste) listant TOUS les titres.
class AllRecordingsScreen extends ConsumerWidget {
  const AllRecordingsScreen({required this.mbid, this.artistName, super.key});

  final String mbid;
  final String? artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(allRecordingsProvider(mbid));

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName == null ? 'Tous les titres' : 'Titres · $artistName'),
      ),
      body: recordings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorRetry(
          onRetry: () => ref.invalidate(allRecordingsProvider(mbid)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun titre disponible.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(allRecordingsProvider(mbid).future),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: list.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text(
                      '${list.length} titre(s)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                return TrackTile(recording: list[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Impossible de charger les titres.'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
