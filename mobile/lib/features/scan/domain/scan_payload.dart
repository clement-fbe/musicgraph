class ScanPayload {
  const ScanPayload._({required this.query, this.spotifyArtistId});

  final String query;
  final String? spotifyArtistId;

  bool get hasSpotifyArtistId =>
      spotifyArtistId != null && spotifyArtistId!.isNotEmpty;

  factory ScanPayload.parse(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      throw const ScanPayloadException('QR code vide.');
    }

    final spotifyUriId = _spotifyUriArtistId(value);
    if (spotifyUriId != null) {
      return ScanPayload._(query: spotifyUriId, spotifyArtistId: spotifyUriId);
    }

    final spotifyUrlId = _spotifyUrlArtistId(value);
    if (spotifyUrlId != null) {
      return ScanPayload._(query: spotifyUrlId, spotifyArtistId: spotifyUrlId);
    }

    return ScanPayload._(query: value);
  }
}

class ScanPayloadException implements Exception {
  const ScanPayloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

String? _spotifyUriArtistId(String value) {
  final parts = value.split(':');
  if (parts.length >= 3 &&
      parts[0].toLowerCase() == 'spotify' &&
      parts[1].toLowerCase() == 'artist') {
    return _cleanSpotifyId(parts[2]);
  }

  return null;
}

String? _spotifyUrlArtistId(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  final isSpotifyHost =
      host == 'open.spotify.com' || host.endsWith('.open.spotify.com');
  if (!isSpotifyHost) return null;

  final segments = uri.pathSegments;
  final artistIndex = segments.indexWhere(
    (segment) => segment.toLowerCase() == 'artist',
  );
  if (artistIndex < 0 || artistIndex + 1 >= segments.length) return null;

  return _cleanSpotifyId(segments[artistIndex + 1]);
}

String? _cleanSpotifyId(String value) {
  final id = value.trim();
  if (id.isEmpty) return null;
  return id.split('?').first.split('/').first;
}
