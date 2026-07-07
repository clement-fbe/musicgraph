import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('MusicGraph')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MusicGraph Mobile',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Catalogue d\'artistes, detail complet et scan QR.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.pushNamed(AppRoutes.catalogueName),
                    icon: const Icon(Icons.library_music),
                    label: const Text('Voir le catalogue'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => context.pushNamed(AppRoutes.searchName),
                    icon: const Icon(Icons.search),
                    label: const Text('Rechercher / importer'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.pushNamed(AppRoutes.scanName),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scanner un QR code'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.pushNamed(AppRoutes.favoritesName),
                    icon: const Icon(Icons.favorite),
                    label: const Text('Mes favoris'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
