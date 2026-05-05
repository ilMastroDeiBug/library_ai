class Review {
  final String id;
  final String? userId;
  final String author;
  final String content;
  final double rating; // Normalizzato su 5 stelle
  final DateTime? createdAt;
  final String? avatarUrl;
  final bool isCustom; // True se è nostra, False se è di TMDB
  final int likes;
  final int dislikes;
  final int userVote; // 1 (Like), -1 (Dislike), 0 (Nessun voto)

  Review({
    required this.id,
    this.userId,
    required this.author,
    required this.content,
    required this.rating,
    this.createdAt,
    this.avatarUrl,
    required this.isCustom,
    this.likes = 0,
    this.dislikes = 0,
    this.userVote = 0,
  });

  int get relevanceScore => likes - dislikes;

  bool isWrittenBy(String? userId) =>
      isCustom && userId != null && this.userId == userId;

  Review copyWith({int? likes, int? dislikes, int? userVote}) {
    return Review(
      id: id,
      userId: userId,
      author: author,
      content: content,
      rating: rating,
      createdAt: createdAt,
      avatarUrl: avatarUrl,
      isCustom: isCustom,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      userVote: userVote ?? this.userVote,
    );
  }
}
