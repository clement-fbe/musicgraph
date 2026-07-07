import '../../catalogue/domain/artist.dart';

class ArtistDetail {
  const ArtistDetail({
    required this.artist,
    this.recordings = const [],
    this.collaborators = const [],
    this.albums = const [],
  });

  final Artist artist;
  final List<ArtistRecording> recordings;
  final List<ArtistCollaborator> collaborators;
  final List<ArtistAlbum> albums;

  factory ArtistDetail.fromJson(Map<String, dynamic> json) {
    final artistJson = json['artist'];

    return ArtistDetail(
      artist: Artist.fromJson(
        artistJson is Map<String, dynamic> ? artistJson : const {},
      ),
      recordings: _listOfMaps(
        json['recordings'],
      ).map(ArtistRecording.fromJson).toList(growable: false),
      collaborators: _listOfMaps(
        json['collaborators'],
      ).map(ArtistCollaborator.fromJson).toList(growable: false),
      albums: _listOfMaps(
        json['albums'],
      ).map(ArtistAlbum.fromJson).toList(growable: false),
    );
  }
}

class ArtistAlbum {
  const ArtistAlbum({
    required this.name,
    this.coverUrl,
    this.releaseDate,
    this.albumType,
    this.totalTracks,
  });

  final String name;
  final String? coverUrl;
  final String? releaseDate;
  final String? albumType;
  final int? totalTracks;

  factory ArtistAlbum.fromJson(Map<String, dynamic> json) {
    return ArtistAlbum(
      name: (json['name'] ?? 'Album inconnu').toString(),
      coverUrl: json['cover_url'] as String?,
      releaseDate: json['release_date'] as String?,
      albumType: json['album_type'] as String?,
      totalTracks: _intOrNull(json['total_tracks']),
    );
  }

  /// Année de sortie si disponible.
  String? get year {
    if (releaseDate == null || releaseDate!.isEmpty) return null;
    return releaseDate!.length >= 4 ? releaseDate!.substring(0, 4) : releaseDate;
  }
}

class ArtistRecording {
  const ArtistRecording({
    required this.name,
    this.mbid,
    this.relationType,
    this.position,
    this.lengthMs,
  });

  final String name;
  final String? mbid;
  final String? relationType;
  final int? position;
  final int? lengthMs;

  factory ArtistRecording.fromJson(Map<String, dynamic> json) {
    final recording = json['recording'];
    final recordingJson = recording is Map<String, dynamic>
        ? recording
        : const <String, dynamic>{};

    return ArtistRecording(
      name: (recordingJson['name'] ?? recordingJson['title'] ?? 'Titre inconnu')
          .toString(),
      mbid: recordingJson['mbid']?.toString(),
      relationType: json['rel_type']?.toString(),
      position: _intOrNull(json['position']),
      lengthMs: _intOrNull(recordingJson['length_ms']),
    );
  }
}

class ArtistCollaborator {
  const ArtistCollaborator({required this.artist, this.collaborationCount});

  final Artist artist;
  final int? collaborationCount;

  factory ArtistCollaborator.fromJson(Map<String, dynamic> json) {
    final artistJson = json['artist'];

    return ArtistCollaborator(
      artist: Artist.fromJson(
        artistJson is Map<String, dynamic> ? artistJson : const {},
      ),
      collaborationCount: _intOrNull(json['collaboration_count']),
    );
  }
}

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
