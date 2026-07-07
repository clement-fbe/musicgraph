import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/external_actions.dart';
import '../data/tracks_repository.dart';
import '../domain/artist_detail.dart';
import 'track_tile.dart';

/// Page (empilée par-dessus la fiche artiste) listant les titres d'un album.
class AlbumTracksScreen extends ConsumerWidget {
  const AlbumTracksScreen({required this.album, super.key});

  final ArtistAlbum album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumId = album.spotifyId;

    return Scaffold(
      appBar: AppBar(
        title: Text(album.name),
        actions: [
          if (album.spotifyUrl != null && album.spotifyUrl!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Ouvrir dans Spotify',
              onPressed: () => openExternal(context, album.spotifyUrl),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
            onPressed: () => shareText(
              album.spotifyUrl == null
                  ? 'Album ${album.name} sur MusicGraph'
                  : 'Album ${album.name} : ${album.spotifyUrl}',
            ),
          ),
        ],
      ),
      body: albumId == null
          ? const Center(child: Text('Album non disponible.'))
          : ref.watch(albumTracksProvider(albumId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(albumTracksProvider(albumId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ),
                data: (tracks) => ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _AlbumHeader(album: album, trackCount: tracks.length),
                    const SizedBox(height: 16),
                    if (tracks.isEmpty)
                      const Center(child: Text('Aucun titre pour cet album.'))
                    else
                      for (final t in tracks) TrackTile(recording: t),
                  ],
                ),
              ),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({required this.album, required this.trackCount});

  final ArtistAlbum album;
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.album, size: 48, color: colorScheme.onSurfaceVariant),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 100,
            height: 100,
            child: (album.coverUrl == null || album.coverUrl!.isEmpty)
                ? placeholder
                : CachedNetworkImage(
                    imageUrl: album.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => placeholder,
                    errorWidget: (_, _, _) => placeholder,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                album.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (album.year != null) album.year!,
                  '$trackCount titre(s)',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
