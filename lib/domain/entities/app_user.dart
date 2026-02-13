class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? bio;
  final bool isPublic; // <--- NUOVO CAMPO

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.bio,
    this.isPublic = true, // Default true
  });
}
