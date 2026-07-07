import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../domain/artist_detail.dart';

/// Tuile d'un titre : cover (si dispo) + nom + durée / type de relation.
class TrackTile extends StatelessWidget {
  const TrackTile({required this.recording, super.key});

  final ArtistRecording recording;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
    );

    final subtitleParts = <String>[
      if (recording.relationType != null) _relLabel(recording.relationType!),
      if (recording.lengthMs != null) _formatDuration(recording.lengthMs!),
    ];

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
