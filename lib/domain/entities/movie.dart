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
  final double popularity;
  final List<String> genres;

  // Campi locali (Database)
  final String status;
  final String productionStatus;
  final String? aiAnalysis;
  final int? runtime;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.releaseDate,
    required this.popularity,
    this.genres = const [],
    this.originalLanguage = '',
    this.status = 'none',
    this.productionStatus = '',
    this.aiAnalysis,
    this.runtime,
  });

  // --- FIX QUI SOTTO ---
  // Abbiamo sostituito via.placeholder.com con placehold.co
  // Oppure puoi restituire '' (stringa vuota) e lasciare che la UI mostri il container grigio

  String get fullPosterUrl => posterPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : 'https://placehold.co/500x750/png?text=No+Poster'; // Servizio stabile

  String get fullBackdropUrl => backdropPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
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
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      genres:
          (json['genres'] as List?)
              ?.map((g) => g['name'].toString())
              .toList() ??
          [],
      runtime: json['runtime'] as int?,
      status: 'none',
      productionStatus: json['status'] ?? '',
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
      popularity: (data['popularity'] as num?)?.toDouble() ?? 0.0,
      genres:
          (data['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      runtime: data['runtime'] as int?,
      status: data['status'] ?? 'none',
      productionStatus: data['productionStatus'] ?? '',
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
      'popularity': popularity,
      'genres': genres,
      'runtime': runtime,
      'status': status,
      'productionStatus': productionStatus,
      'aiAnalysis': aiAnalysis,
      'type': 'movie',
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
    double? popularity,
    List<String>? genres,
    String? releaseDate,
    String? originalLanguage,
    String? status,
    String? productionStatus,
    String? aiAnalysis,
    int? runtime,
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
      popularity: popularity ?? this.popularity,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      productionStatus: productionStatus ?? this.productionStatus,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      runtime: runtime ?? this.runtime,
    );
  }
}
