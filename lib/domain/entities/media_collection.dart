class MediaCollection {
  final int id;
  final String userId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String? coverUrl; // Derived from the first item added
  final int itemCount;

  const MediaCollection({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    this.coverUrl,
    this.itemCount = 0,
  });
}

class MediaCollectionItem {
  final int id;
  final int collectionId;
  final String itemId; // String because it can be an int from TMDB casted to string, or a google books string ID
  final String itemType; // 'movie', 'tv', 'book'
  final DateTime addedAt;
  
  // These fields are populated by joining with the actual media table
  final String? title;
  final String? posterUrl;

  const MediaCollectionItem({
    required this.id,
    required this.collectionId,
    required this.itemId,
    required this.itemType,
    required this.addedAt,
    this.title,
    this.posterUrl,
  });
}
