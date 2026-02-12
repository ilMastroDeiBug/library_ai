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

    // Gestione avatar (a volte inizia con /https, a volte è un path parziale)
    String? avatar = authorDetails['avatar_path'];
    if (avatar != null && !avatar.startsWith('http')) {
      avatar = 'https://image.tmdb.org/t/p/w185$avatar';
    } else if (avatar != null && avatar.startsWith('/http')) {
      avatar = avatar.substring(1); // Rimuovi lo slash iniziale errato di TMDB
    }

    return Review(
      author: json['author'] ?? 'Anonimo',
      content: json['content'] ?? '',
      avatarPath: avatar,
      rating: (authorDetails['rating'] as num?)?.toDouble(),
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
