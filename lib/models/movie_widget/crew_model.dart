class CrewMember {
  final int id;
  final String name;
  final String department;
  final String job;
  final String? profilePath;

  CrewMember({
    required this.id,
    required this.name,
    required this.department,
    required this.job,
    this.profilePath,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sconosciuto',
      department: json['department'] ?? 'Altro',
      job: json['job'] ?? 'Ruolo non specificato',
      profilePath: json['profile_path'],
    );
  }

  String get fullProfileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : '';
}
