// Test de fumée basique pour l'app MusicGraph.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:musicgraph_mobile/main.dart';

void main() {
  testWidgets('L\'app démarre et affiche l\'accueil', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MusicGraphApp()));

    expect(find.text('MusicGraph Mobile'), findsOneWidget);
  });
}
