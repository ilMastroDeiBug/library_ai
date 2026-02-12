class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String thumbnailUrl;
  final int? pageCount;
  final num? averageRating; // Usa num perché può essere int o double
  final int? ratingsCount;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.thumbnailUrl,
    this.pageCount,
    this.averageRating,
    this.ratingsCount,
  });

  // Factory per creare un Book da JSON (da Google Books o Firebase)
  factory Book.fromJson(Map<String, dynamic> json, {String? id}) {
    // Gestione un po' complessa per Google Books che ha 'volumeInfo'
    // Se i dati arrivano già piatti (da Firebase), usiamo json direttamente.
    // Se arrivano da Google Books, usiamo volumeInfo.
    final data = json['volumeInfo'] ?? json;

    // Gestione immagini sicura
    String img = "";
    if (data['imageLinks'] != null && data['imageLinks']['thumbnail'] != null) {
      img = data['imageLinks']['thumbnail'];
    } else if (json['thumbnailUrl'] != null) {
      img = json['thumbnailUrl'];
    }

    return Book(
      id: id ?? json['id'] ?? '', // L'ID può venire dall'esterno o dal JSON
      title: data['title'] ?? 'Titolo Sconosciuto',
      author: (data['authors'] != null && (data['authors'] as List).isNotEmpty)
          ? data['authors'][0]
          : (data['author'] ?? 'Autore Sconosciuto'), // Fallback per Firebase
      description: data['description'] ?? '',
      thumbnailUrl: img,
      pageCount: data['pageCount'],
      averageRating: data['averageRating'],
      ratingsCount: data['ratingsCount'],
    );
  }

  // Factory semplificata se hai mappature diverse (opzionale, ma utile)
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book.fromJson(map);
  }

  // --- AGGIUNGI QUESTO METODO ---
  // Questo è il metodo che mancava per risolvere l'errore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'pageCount': pageCount,
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
    };
  }
}
