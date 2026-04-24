// lib/domain/entities/tv_series.dart

class TvSeries {
  final int id;
  final String name; // Serie TV usano "name", non "title"
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final String firstAirDate; // Invece di releaseDate
  final String originalLanguage;

  // Campi locali (Database)
  final String status;
  final String? aiAnalysis;

  TvSeries({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.firstAirDate,
    this.originalLanguage = '',
    this.status = 'none',
    this.aiAnalysis,
  });

  String get fullPosterUrl => posterPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : 'https://placehold.co/500x750/png?text=No+Poster';

  String get fullBackdropUrl => backdropPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : '';

  factory TvSeries.fromTmdb(Map<String, dynamic> json) {
    return TvSeries(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Senza Nome',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] ?? 0,
      firstAirDate: json['first_air_date'] ?? '',
      originalLanguage: json['original_language'] ?? '',
      status: 'none',
    );
  }

  // Per Firestore, useremo la stessa logica di mappatura ma adattata
  factory TvSeries.fromFirestore(Map<String, dynamic> data, int id) {
    return TvSeries(
      id: id,
      name:
          data['title'] ??
          '', // Su Firestore salviamo tutto come 'title' per uniformità query
      overview: data['overview'] ?? '',
      posterPath: data['posterPath'] ?? '',
      backdropPath: data['backdropPath'] ?? '',
      voteAverage: (data['voteAverage'] as num?)?.toDouble() ?? 0.0,
      voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
      firstAirDate:
          data['releaseDate'] ??
          '', // Su DB usiamo releaseDate come campo comune
      originalLanguage: data['originalLanguage'] ?? '',
      status: data['status'] ?? 'none',
      aiAnalysis: data['aiAnalysis'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': name, // Salviamo come title per coerenza nel DB misto
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'releaseDate': firstAirDate,
      'originalLanguage': originalLanguage,
      'status': status,
      'aiAnalysis': aiAnalysis,
      'type': 'tv', // Flag fondamentale per distinguere nel DB
    };
  }
}
