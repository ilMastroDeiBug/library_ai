class CastMember {
  final String name;
  final String character;
  final String? profilePath;

  CastMember({required this.name, required this.character, this.profilePath});

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'] ?? 'Sconosciuto',
      character: json['character'] ?? 'Ruolo non specificato',
      profilePath: json['profile_path'], // Può essere null
    );
  }

  String get fullProfileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath' // w185 è leggero, perfetto per i cerchietti
      : '';
}
