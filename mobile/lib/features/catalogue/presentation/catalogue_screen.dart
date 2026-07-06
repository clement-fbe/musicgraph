import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router/app_routes.dart';
import '../domain/artist.dart';
import 'catalogue_providers.dart';

/// Breakpoint à partir duquel on considère un écran "tablette".
const double _kTabletBreakpoint = 600;

class CatalogueScreen extends ConsumerWidget {
  const CatalogueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(catalogueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      body: artistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err is ApiException ? err.message : 'Erreur de chargement.',
          onRetry: () => ref.invalidate(catalogueProvider),
        ),
        data: (artists) {
          if (artists.isEmpty) {
            return _EmptyView(onRefresh: () => ref.invalidate(catalogueProvider));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(catalogueProvider.future),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsivité (critère #2) : liste sur mobile, grille sur tablette.
                final isTablet = constraints.maxWidth >= _kTabletBreakpoint;
                return isTablet
                    ? _ArtistGrid(artists: artists)
                    : _ArtistList(artists: artists);
              },
            ),
          );
        },
      ),
    );
  }
}

void _openDetail(BuildContext context, Artist artist) {
  context.pushNamed(
    AppRoutes.artistDetailName,
    pathParameters: {'mbid': artist.mbid},
  );
}

/// Mobile → liste verticale.
class _ArtistList extends StatelessWidget {
  const _ArtistList({required this.artists});

  final List<Artist> artists;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: artists.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = artists[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: _Thumb(url: a.imageUrl, size: 56),
            title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle:
                Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: a.year != null ? Text(a.year!) : null,
            onTap: () => _openDetail(context, a),
          ),
        );
      },
    );
  }
}

/// Tablette → grille.
class _ArtistGrid extends StatelessWidget {
  const _ArtistGrid({required this.artists});

  final List<Artist> artists;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: artists.length,
      itemBuilder: (context, i) {
        final a = artists[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDetail(context, a),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _Thumb(url: a.imageUrl)),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Vignette image avec placeholder (gère l'absence d'URL / l'erreur de chargement).
class _Thumb extends StatelessWidget {
  const _Thumb({this.url, this.size});

  final String? url;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.music_note)),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.library_music_outlined, size: 64),
          const SizedBox(height: 12),
          const Text('Aucun artiste dans le catalogue.'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Rafraîchir'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
