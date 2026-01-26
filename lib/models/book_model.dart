class Book {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl; // L'URL della copertina
  final String description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.description,
  });

  // Questa funzione "magica" converte il casino di dati di Google in un nostro Libro pulito
  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Titolo Sconosciuto',
      author:
          (volumeInfo['authors'] as List<dynamic>?)?.first ??
          'Autore Sconosciuto',
      // Prendiamo l'immagine, se non c'è mettiamo un placeholder vuoto
      thumbnailUrl: volumeInfo['imageLinks']?['thumbnail'] ?? '',
      description:
          volumeInfo['description'] ?? 'Nessuna descrizione disponibile.',
    );
  }
}
