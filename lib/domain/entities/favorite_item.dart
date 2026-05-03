class FavoriteItem {
  final String id;
  final String userId;
  final int itemId;
  final String itemType; // 'movie', 'tv', 'person'
  final String title;
  final String? posterUrl;
  final DateTime createdAt;

  FavoriteItem({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.title,
    this.posterUrl,
    required this.createdAt,
  });

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'],
      userId: map['user_id'],
      itemId: map['item_id'],
      itemType: map['item_type'],
      title: map['title'],
      posterUrl: map['poster_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
