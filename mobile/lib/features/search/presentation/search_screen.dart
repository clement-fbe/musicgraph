import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/api/api_client.dart';
import '../../../core/router/app_routes.dart';
import '../../catalogue/domain/artist.dart';
import '../../catalogue/presentation/catalogue_providers.dart';
import 'search_view_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  Timer? _debounce;
  bool _isListening = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).update(value.trim());
    });
  }

  /// Recherche vocale (micro) : reconnaissance vocale native -> champ + requête.
  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Micro / reconnaissance vocale indisponible.')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: 'fr_FR'),
      onResult: (result) {
        _controller.text = result.recognizedWords;
        if (result.finalResult) {
          ref
              .read(searchQueryProvider.notifier)
              .update(result.recognizedWords.trim());
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un artiste…',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      color: _isListening ? Colors.red : null,
                      tooltip: 'Recherche vocale',
                      onPressed: _toggleVoiceSearch,
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchQueryProvider.notifier).update('');
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: query.isEmpty
                ? const _Hint()
                : results.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text(
                        err is ApiException ? err.message : 'Erreur de recherche.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    data: (artists) {
                      if (artists.isEmpty) {
                        return const Center(child: Text('Aucun résultat.'));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: artists.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _ResultTile(artist: artists[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importing = ref.watch(importControllerProvider).contains(artist.mbid);
    // L'artiste est-il déjà dans le catalogue (importé) ?
    final imported = ref.watch(catalogueProvider).value?.any(
              (a) => a.mbid == artist.mbid,
            ) ??
        false;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
          child: (artist.imageUrl == null || artist.imageUrl!.isEmpty)
              ? ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note),
                )
              : CachedNetworkImage(imageUrl: artist.imageUrl!, fit: BoxFit.cover),
        ),
        title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(artist.description,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: _buildTrailing(context, ref, importing: importing, imported: imported),
        // Une fois importé, on ouvre sa fiche artiste au tap sur la ligne.
        onTap: imported
            ? () => context.pushNamed(
                  AppRoutes.artistDetailName,
                  pathParameters: {'mbid': artist.mbid},
                )
            : null,
      ),
    );
  }

  Widget _buildTrailing(
    BuildContext context,
    WidgetRef ref, {
    required bool importing,
    required bool imported,
  }) {
    if (importing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (imported) {
      // Déjà importé : on retire l'icône de téléchargement, on indique
      // que la fiche est accessible.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const Icon(Icons.chevron_right),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.download),
      tooltip: 'Importer',
      onPressed: () => _import(context, ref),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(importControllerProvider.notifier).importArtist(artist);
      messenger.showSnackBar(
        SnackBar(content: Text('${artist.name} importé au catalogue.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec de l\'import de ${artist.name}.')),
      );
    }
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64),
          SizedBox(height: 12),
          Text('Recherche un artiste pour l\'ajouter au catalogue.'),
        ],
      ),
    );
  }
}
