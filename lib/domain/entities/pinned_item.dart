/// Rappresenta un'opera "pinnata" (fissata) nella vetrina del profilo.
/// L'utente può pinnare fino a 4 opere di qualsiasi tipo (film, serie, libro).
class PinnedItem {
  final String id;
  final String userId;
  final int mediaId;         // ID numerico TMDB o hash per libri
  final String mediaType;    // 'movie' | 'tv' | 'book'
  final String title;
  final String? posterUrl;
  final int position;        // 0..3 - ordine nella vetrina
  final DateTime createdAt;

  const PinnedItem({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    required this.title,
    this.posterUrl,
    required this.position,
    required this.createdAt,
  });

  factory PinnedItem.fromMap(Map<String, dynamic> map) {
    return PinnedItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      mediaId: (map['media_id'] as num?)?.toInt() ?? 0,
      mediaType: map['media_type']?.toString() ?? 'movie',
      title: map['title']?.toString() ?? '',
      posterUrl: map['poster_url']?.toString(),
      position: (map['position'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'media_id': mediaId,
        'media_type': mediaType,
        'title': title,
        'poster_url': posterUrl,
        'position': position,
      };
}
