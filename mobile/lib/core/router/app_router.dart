import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalogue/presentation/catalogue_screen.dart';
import '../../features/detail/presentation/artist_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.homePath,
    routes: [
      GoRoute(
        name: AppRoutes.homeName,
        path: AppRoutes.homePath,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        name: AppRoutes.catalogueName,
        path: AppRoutes.cataloguePath,
        builder: (context, state) => const CatalogueScreen(),
      ),
      GoRoute(
        name: AppRoutes.artistDetailName,
        path: AppRoutes.artistDetailPath,
        builder: (context, state) {
          final mbid = state.pathParameters['mbid'] ?? '';
          return ArtistDetailScreen(mbid: mbid);
        },
      ),
      GoRoute(
        name: AppRoutes.scanName,
        path: AppRoutes.scanPath,
        builder: (context, state) => const ScanScreen(),
      ),
    ],
  );
});
