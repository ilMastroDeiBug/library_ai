class ActorCredit {
  final int id;
  final String title; // Unifica 'title' (film) e 'name' (serie tv)
  final String? posterPath;
  final String mediaType; // 'movie' o 'tv'
  final double voteAverage;
  final String? character; // Il ruolo interpretato
  final String? releaseDate; // Unifica 'release_date' e 'first_air_date'

  ActorCredit({
    required this.id,
    required this.title,
    this.posterPath,
    required this.mediaType,
    required this.voteAverage,
    this.character,
    this.releaseDate,
  });
}

class Actor {
  final int id;
  final String name;
  final String biography;
  final String? profilePath;
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final double popularity;
  final String knownForDepartment;
  final List<ActorCredit> credits;

  Actor({
    required this.id,
    required this.name,
    required this.biography,
    this.profilePath,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    required this.popularity,
    required this.knownForDepartment,
    required this.credits,
  });
}
