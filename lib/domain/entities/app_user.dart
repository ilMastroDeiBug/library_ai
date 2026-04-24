class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? bio;
  final String? photoUrl;
  final bool isPublic; // <--- NUOVO CAMPO

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.isPublic = true, // Default true
  });
}
