class Review {
  final String author;
  final String content;
  final String? avatarPath;
  final double? rating;
  final String createdAt;

  Review({
    required this.author,
    required this.content,
    this.avatarPath,
    this.rating,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final authorDetails = json['author_details'] ?? {};

    return Review(
      author: json['author'] ?? 'Anonimo',
      content: json['content'] ?? '',
      avatarPath: _normalizeAvatarPath(authorDetails['avatar_path']),
      rating: (authorDetails['rating'] as num?)?.toDouble(),
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  static String? _normalizeAvatarPath(dynamic rawAvatarPath) {
    if (rawAvatarPath == null) return null;

    final avatar = rawAvatarPath.toString().trim();
    if (avatar.isEmpty) return null;

    // TMDB a volte restituisce URL assoluti malformati con slash iniziale.
    if (avatar.startsWith('/http://') || avatar.startsWith('/https://')) {
      return avatar.substring(1);
    }

    // URL assoluto già valido.
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }

    // Path relativo TMDB.
    return 'https://image.tmdb.org/t/p/w185$avatar';
  }
}
