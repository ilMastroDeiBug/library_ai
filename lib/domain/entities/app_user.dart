class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? bio;
  final String? photoUrl;
  final bool isPublic;
  final String languagePreference;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.isPublic = true,
    this.languagePreference = 'it-IT',
  });
}
