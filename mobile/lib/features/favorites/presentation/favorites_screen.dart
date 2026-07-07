import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'favorites_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: favorites.isEmpty
          ? const _EmptyFavorites()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final a = favorites[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: (a.imageUrl == null || a.imageUrl!.isEmpty)
                          ? ColoredBox(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Icon(Icons.music_note),
                            )
                          : CachedNetworkImage(
                              imageUrl: a.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                    title: Text(a.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(a.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      tooltip: 'Retirer des favoris',
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(a),
                    ),
                    onTap: () => context.pushNamed(
                      AppRoutes.artistDetailName,
                      pathParameters: {'mbid': a.mbid},
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64),
          SizedBox(height: 12),
          Text('Aucun favori pour le moment.'),
          SizedBox(height: 4),
          Text('Ajoute des artistes depuis le catalogue.'),
        ],
      ),
    );
  }
}
