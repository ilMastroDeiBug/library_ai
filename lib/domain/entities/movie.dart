class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final String releaseDate;
  final String originalLanguage;

  // Campi locali (Database)
  final String status;
  final String? aiAnalysis;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.releaseDate,
    this.originalLanguage = '',
    this.status = 'none',
    this.aiAnalysis,
  });

  // --- FIX QUI SOTTO ---
  // Abbiamo sostituito via.placeholder.com con placehold.co
  // Oppure puoi restituire '' (stringa vuota) e lasciare che la UI mostri il container grigio

  String get fullPosterUrl => posterPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : 'https://placehold.co/500x750/png?text=No+Poster'; // Servizio stabile

  String get fullBackdropUrl => backdropPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : ''; // Per il backdrop lasciamo vuoto, la UI gestirà il gradiente

  factory Movie.fromTmdb(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Senza Titolo',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'] ?? '',
      originalLanguage: json['original_language'] ?? '',
      status: 'none',
    );
  }

  factory Movie.fromFirestore(Map<String, dynamic> data, int id) {
    return Movie(
      id: id,
      title: data['title'] ?? '',
      overview: data['overview'] ?? '',
      posterPath: data['posterPath'] ?? '',
      backdropPath: data['backdropPath'] ?? '',
      voteAverage: (data['voteAverage'] as num?)?.toDouble() ?? 0.0,
      voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
      releaseDate: data['releaseDate'] ?? '',
      originalLanguage: data['originalLanguage'] ?? '',
      status: data['status'] ?? 'none',
      aiAnalysis: data['aiAnalysis'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'releaseDate': releaseDate,
      'originalLanguage': originalLanguage,
      'status': status,
      'aiAnalysis': aiAnalysis,
    };
  }

  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? voteCount,
    String? releaseDate,
    String? originalLanguage,
    String? status,
    String? aiAnalysis,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      status: status ?? this.status,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    );
  }
}
