class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final String releaseDate;
  final String status; // 'watched', 'towatch'
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
    this.status = 'towatch',
    this.aiAnalysis,
  });

  // Factory da API (TMDB)
  factory Movie.fromTmdb(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Titolo Sconosciuto',
      overview: json['overview'] ?? 'Nessuna trama disponibile.',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? 'N/D',
    );
  }

  // Factory da Firestore
  factory Movie.fromFirestore(Map<String, dynamic> data, int id) {
    return Movie(
      id: id,
      title: data['title'] ?? '',
      overview: data['overview'] ?? '',
      posterPath: data['posterPath'] ?? '',
      backdropPath: data['backdropPath'] ?? '',
      voteAverage: (data['voteAverage'] as num?)?.toDouble() ?? 0.0,
      voteCount: data['voteCount'] ?? 0,
      releaseDate: data['releaseDate'] ?? '',
      status: data['status'] ?? 'towatch',
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
      'status': status,
      if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
    };
  }

  String get fullPosterUrl => posterPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : 'https://via.placeholder.com/500x750?text=No+Image';

  String get fullBackdropUrl => backdropPath.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : '';
}
