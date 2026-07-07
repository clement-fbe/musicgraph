import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/external_actions.dart';
import '../../catalogue/domain/artist.dart';
import '../../favorites/presentation/favorites_providers.dart';
import '../domain/artist_detail.dart';
import 'album_tracks_screen.dart';
import 'all_recordings_screen.dart';
import 'artist_detail_view_model.dart';
import 'track_tile.dart';

class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({required this.mbid, super.key});

  final String mbid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(artistDetailViewModelProvider(mbid));

    return Scaffold(
      body: detail.when(
        loading: () => const _DetailLoading(),
        error: (error, stackTrace) => _DetailError(
          message: error.toString(),
          onRetry: () => ref.invalidate(artistDetailViewModelProvider(mbid)),
        ),
        data: (detail) => _DetailContent(detail: detail),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final ArtistDetail detail;

  @override
  Widget build(BuildContext context) {
    final artist = detail.artist;
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          pinned: true,
          expandedHeight: 320,
          title: Text(artist.name),
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final isFav = ref.watch(isFavoriteProvider(artist.mbid));
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null,
                  ),
                  tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(artist),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroImage(
              imageUrl: artist.imageUrl,
              fallbackLabel: artist.name,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(artist.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                _ArtistActions(artist: artist),
                const SizedBox(height: 24),
                _InfoGrid(
                  items: [
                    _InfoItem('Pays', artist.country),
                    _InfoItem('Type', artist.type),
                    _InfoItem('Date', artist.beginDate ?? artist.year),
                  ],
                ),
                if (artist.genres.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Genres', count: artist.genres.length),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final genre in artist.genres)
                        Chip(label: Text(genre)),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                _AlbumsSection(albums: detail.albums),
                const SizedBox(height: 28),
                _RecordingsSection(
                  recordings: detail.recordings,
                  mbid: artist.mbid,
                  artistName: artist.name,
                ),
                const SizedBox(height: 28),
                _CollaboratorsSection(collaborators: detail.collaborators),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtistActions extends StatelessWidget {
  const _ArtistActions({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (artist.spotifyUrl != null && artist.spotifyUrl!.isNotEmpty)
          FilledButton.tonalIcon(
            onPressed: () => openExternal(context, artist.spotifyUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir dans Spotify'),
          ),
        OutlinedButton.icon(
          onPressed: () => shareText(
            artist.spotifyUrl == null
                ? 'Découvre ${artist.name} sur MusicGraph'
                : 'Découvre ${artist.name} : ${artist.spotifyUrl}',
          ),
          icon: const Icon(Icons.share),
          label: const Text('Partager'),
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl, required this.fallbackLabel});

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _ImageFallback(label: fallbackLabel);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              _ImageFallback(label: fallbackLabel),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colorScheme.surface.withValues(alpha: 0.84),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.album, size: 76, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.value != null && item.value!.isNotEmpty)
        .toList(growable: false);

    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 4.4 : 2.3,
          ),
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return _InfoTile(label: item.label, value: item.value!);
          },
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumsSection extends StatelessWidget {
  const _AlbumsSection({required this.albums});

  final List<ArtistAlbum> albums;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Albums', count: albums.length),
        const SizedBox(height: 12),
        if (albums.isEmpty)
          Text('Aucun album disponible.',
              style: Theme.of(context).textTheme.bodyMedium)
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _AlbumCard(album: albums[index]),
            ),
          ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final ArtistAlbum album;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.album, size: 48, color: colorScheme.onSurfaceVariant),
    );

    return SizedBox(
      width: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AlbumTracksScreen(album: album)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 150,
                height: 150,
              child: (album.coverUrl == null || album.coverUrl!.isEmpty)
                  ? placeholder
                  : CachedNetworkImage(
                      imageUrl: album.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          ColoredBox(color: colorScheme.surfaceContainerHighest),
                      errorWidget: (_, _, _) => placeholder,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            [
              if (album.year != null) album.year!,
              if (album.totalTracks != null) '${album.totalTracks} titres',
            ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingsSection extends StatelessWidget {
  const _RecordingsSection({
    required this.recordings,
    required this.mbid,
    required this.artistName,
  });

  final List<ArtistRecording> recordings;
  final String mbid;
  final String artistName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Titres', count: recordings.length),
        const SizedBox(height: 8),
        if (recordings.isEmpty)
          Text('Aucun titre disponible.',
              style: Theme.of(context).textTheme.bodyMedium)
        else ...[
          for (final recording in recordings.take(10))
            TrackTile(recording: recording),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AllRecordingsScreen(mbid: mbid, artistName: artistName),
                ),
              ),
              icon: const Icon(Icons.library_music),
              label: const Text('Afficher tous les titres'),
            ),
          ),
        ],
      ],
    );
  }
}

class _CollaboratorsSection extends StatelessWidget {
  const _CollaboratorsSection({required this.collaborators});

  final List<ArtistCollaborator> collaborators;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Collaborateurs',
      count: collaborators.length,
      emptyMessage: 'Aucun collaborateur disponible.',
      children: [
        for (final collaborator in collaborators.take(8))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.group),
            title: Text(collaborator.artist.name),
            subtitle: Text(
              [
                if (collaborator.artist.type != null) collaborator.artist.type!,
                if (collaborator.collaborationCount != null)
                  '${collaborator.collaborationCount} collaboration(s)',
              ].join(' · '),
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final int count;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, count: count),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium)
        else
          ...children,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Badge(label: Text(count.toString())),
      ],
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail artiste')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail artiste')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger le detail artiste.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String? value;
}

