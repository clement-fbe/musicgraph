import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/artist_detail.dart';
import 'audio_preview_provider.dart';

/// Tuile d'un titre : cover (si dispo) + nom + durée + lecture d'un extrait 30s.
class TrackTile extends ConsumerWidget {
  const TrackTile({required this.recording, super.key});

  final ArtistRecording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
    );

    final subtitleParts = <String>[
      if (recording.relationType != null) _relLabel(recording.relationType!),
      if (recording.lengthMs != null) _formatDuration(recording.lengthMs!),
    ];

    final preview = recording.previewUrl;
    final isPlaying = preview != null && ref.watch(audioPreviewProvider) == preview;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 48,
          height: 48,
          child: (recording.coverUrl == null || recording.coverUrl!.isEmpty)
              ? placeholder
              : CachedNetworkImage(
                  imageUrl: recording.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
        ),
      ),
      title: Text(recording.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
      trailing: preview == null || preview.isEmpty
          ? null
          : IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
              tooltip: isPlaying ? 'Pause' : 'Écouter un extrait',
              onPressed: () =>
                  ref.read(audioPreviewProvider.notifier).toggle(preview),
            ),
    );
  }
}

String _relLabel(String relType) {
  switch (relType) {
    case 'PERFORMED':
      return 'Interprète';
    case 'FEATURED_ON':
      return 'Featuring';
    default:
      return relType;
  }
}

String _formatDuration(int lengthMs) {
  final duration = Duration(milliseconds: lengthMs);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
