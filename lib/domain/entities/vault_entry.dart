/// Una voce nel Diario Recente dell'utente.
/// Aggrega in un unico modello qualsiasi tipo di contenuto aggiunto di recente.
class VaultEntry {
  final String id;
  final String userId;
  final int mediaId;
  final String mediaType; // 'movie' | 'tv' | 'book'
  final String title;
  final String? posterUrl;
  final double? rating;       // stelline date (null se non votato)
  final String? reviewSnippet; // prime ~100 char della recensione
  final String status;        // 'watched', 'reading', 'completed', ecc.
  final DateTime addedAt;

  const VaultEntry({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    required this.title,
    this.posterUrl,
    this.rating,
    this.reviewSnippet,
    required this.status,
    required this.addedAt,
  });

  factory VaultEntry.fromMap(Map<String, dynamic> map) {
    return VaultEntry(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      mediaId: (map['media_id'] as num?)?.toInt() ?? 0,
      mediaType: map['media_type']?.toString() ?? 'movie',
      title: map['title']?.toString() ?? '',
      posterUrl: map['poster_url']?.toString(),
      rating: (map['rating'] as num?)?.toDouble(),
      reviewSnippet: map['review_snippet']?.toString(),
      status: map['status']?.toString() ?? '',
      addedAt: map['added_at'] != null
          ? DateTime.tryParse(map['added_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
