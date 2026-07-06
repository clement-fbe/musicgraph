/// Modèle métier immuable d'un artiste (couche Domain).
///
/// Contrat partagé entre toutes les features. Les clés de [fromJson]
/// correspondent au nœud `Artist` renvoyé par l'API MusicGraph
/// (`/api/artists`, `/api/artists/{mbid}`).
class Artist {
  final String mbid;
  final String name;
  final String? imageUrl;
  final String? country;
  final String? type;
  final String? disambiguation;
  final String? beginDate;
  final List<String> genres;

  const Artist({
    required this.mbid,
    required this.name,
    this.imageUrl,
    this.country,
    this.type,
    this.disambiguation,
    this.beginDate,
    this.genres = const [],
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      mbid: (json['mbid'] ?? '').toString(),
      name: (json['name'] ?? 'Artiste inconnu').toString(),
      imageUrl: json['image_url'] as String?,
      country: json['country'] as String?,
      type: json['type'] as String?,
      disambiguation: json['disambiguation'] as String?,
      beginDate: json['beginDate'] as String?,
      genres: (json['genres'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'mbid': mbid,
        'name': name,
        'image_url': imageUrl,
        'country': country,
        'type': type,
        'disambiguation': disambiguation,
        'beginDate': beginDate,
        'genres': genres,
      };

  /// Description lisible pour le catalogue / le détail (critère « Description »).
  String get description {
    final parts = <String>[
      if (disambiguation != null && disambiguation!.isNotEmpty) disambiguation!,
      if (type != null && type!.isNotEmpty) type!,
      if (country != null && country!.isNotEmpty) country!,
      if (genres.isNotEmpty) genres.take(3).join(', '),
    ];
    return parts.isEmpty ? 'Pas de description disponible.' : parts.join(' · ');
  }

  /// Année de début si disponible (critère « Date »).
  String? get year {
    if (beginDate == null || beginDate!.isEmpty) return null;
    return beginDate!.length >= 4 ? beginDate!.substring(0, 4) : beginDate;
  }
}
