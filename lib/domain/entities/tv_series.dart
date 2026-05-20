class TvSeries {
  final int id;
  final String name;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final String firstAirDate;
  final String originalLanguage;
  final double popularity;
  final List<dynamic> seasons;

  // Campi locali (Database)
  final String status;
  final String? aiAnalysis;
  final int? runtime;
  final int? numberOfEpisodes;

  TvSeries({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.firstAirDate,
    required this.popularity,
    this.seasons = const [],
    this.originalLanguage = '',
    this.status = 'none',
    this.aiAnalysis,
    this.runtime,
    this.numberOfEpisodes,
  });

  String get fullPosterUrl => posterPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : 'https://placehold.co/500x750/png?text=No+Poster';

  String get fullBackdropUrl => backdropPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : '';

  TvSeries copyWith({
    int? id,
    String? name,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? voteCount,
    String? firstAirDate,
    String? originalLanguage,
    double? popularity,
    List<dynamic>? seasons,
    String? status,
    String? aiAnalysis,
    int? runtime,
    int? numberOfEpisodes,
  }) {
    return TvSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      popularity: popularity ?? this.popularity,
      seasons: seasons ?? this.seasons,
      status: status ?? this.status,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      runtime: runtime ?? this.runtime,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
    );
  }

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
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      seasons: json['seasons'] ?? [],
      runtime: json['episode_run_time'] != null && (json['episode_run_time'] as List).isNotEmpty
          ? (json['episode_run_time'][0] as num).toInt()
          : null,
      numberOfEpisodes: json['number_of_episodes'] as int?,
      status: 'none',
    );
  }

  factory TvSeries.fromFirestore(Map<String, dynamic> data, int id) {
    return TvSeries(
      id: id,
      name: data['title'] ?? '',
      overview: data['overview'] ?? '',
      posterPath: data['posterPath'] ?? '',
      backdropPath: data['backdropPath'] ?? '',
      voteAverage: (data['voteAverage'] as num?)?.toDouble() ?? 0.0,
      voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
      firstAirDate: data['releaseDate'] ?? '',
      originalLanguage: data['originalLanguage'] ?? '',
      popularity: (data['popularity'] as num?)?.toDouble() ?? 0,
      seasons: data['seasons'] ?? [],
      runtime: data['runtime'] as int?,
      numberOfEpisodes: data['numberOfEpisodes'] as int?,
      status: data['status'] ?? 'none',
      aiAnalysis: data['aiAnalysis'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':
          id, // <--- LA MAGIA È QUI: SENZA QUESTO SUPABASE INVENTAVA ID A CASO!
      'title': name,
      'overview': overview,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'releaseDate': firstAirDate,
      'originalLanguage': originalLanguage,
      'popularity': popularity,
      'seasons': seasons,
      'runtime': runtime,
      'numberOfEpisodes': numberOfEpisodes,
      'status': status,
      'aiAnalysis': aiAnalysis,
      'type': 'tv',
    };
  }
}
