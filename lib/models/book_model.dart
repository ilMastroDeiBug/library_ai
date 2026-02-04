class Book {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String description;
  // --- NUOVI CAMPI ---
  final int? pageCount; // Numero pagine (può essere null)
  final num? averageRating; // Voto medio (es. 4.5)
  final int? ratingsCount; // Quanti voti totali (es. 120)

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.description,
    this.pageCount,
    this.averageRating,
    this.ratingsCount,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Titolo Sconosciuto',
      author:
          (volumeInfo['authors'] as List<dynamic>?)?.first ??
          'Autore Sconosciuto',
      thumbnailUrl: volumeInfo['imageLinks']?['thumbnail'] ?? '',
      description:
          volumeInfo['description'] ?? 'Nessuna descrizione disponibile.',
      // --- MAPPING NUOVI CAMPI ---
      pageCount: volumeInfo['pageCount'],
      averageRating: volumeInfo['averageRating'],
      ratingsCount: volumeInfo['ratingsCount'],
    );
  }
}
