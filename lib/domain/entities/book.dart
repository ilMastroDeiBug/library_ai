class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String thumbnailUrl;
  final int? pageCount;
  final double rating;
  final int ratingsCount;
  final String status; // 'read', 'toread'
  final String? aiAnalysis; // Campo extra per l'analisi

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description = '',
    this.thumbnailUrl = '',
    this.pageCount,
    this.rating = 0.0,
    this.ratingsCount = 0,
    this.status = 'toread',
    this.aiAnalysis,
  });

  // Getter per compatibilità UI (se usavi num)
  num? get averageRating => rating;

  // 1. Factory da Firestore (Database)
  factory Book.fromFirestore(Map<String, dynamic> data, String id) {
    return Book(
      id: id,
      title: data['title'] ?? 'Senza Titolo',
      author: data['author'] ?? 'Sconosciuto',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      pageCount: data['pageCount'],
      rating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: data['ratingsCount'] ?? 0,
      status: data['status'] ?? 'toread',
      aiAnalysis: data['aiAnalysis'],
    );
  }

  // 2. Factory Generico da API (OpenLibrary / GoogleBooks)
  factory Book.fromApi(Map<String, dynamic> json) {
    // Gestione ibrida per supportare entrambi i JSON
    final volumeInfo = json['volumeInfo']; // Tipico di Google Books
    final isGoogle = volumeInfo != null;

    final data = isGoogle ? volumeInfo : json;

    // Titolo
    String title = data['title'] ?? 'Senza Titolo';

    // Autore
    String author = 'Sconosciuto';
    if (isGoogle && data['authors'] != null) {
      author = (data['authors'] as List).first.toString();
    } else if (data['author_name'] != null) {
      // OpenLibrary
      author = (data['author_name'] as List).first.toString();
    } else if (data['author'] != null) {
      author = data['author'];
    }

    // Immagine
    String img = "";
    if (isGoogle && data['imageLinks'] != null) {
      img = data['imageLinks']['thumbnail'] ?? "";
    } else if (data['cover_i'] != null) {
      // OpenLibrary
      img = 'https://covers.openlibrary.org/b/id/${data['cover_i']}-L.jpg';
    } else if (json['thumbnailUrl'] != null) {
      img = json['thumbnailUrl'];
    }

    // ID
    String id = json['id'] ?? (json['key'] ?? DateTime.now().toString());
    // Pulizia ID per Firestore (via slash)
    id = id.replaceAll('/', '_');

    // Rating
    double rating = 0.0;
    int ratingsCount = 0;

    if (data['averageRating'] != null) {
      rating = (data['averageRating'] as num).toDouble();
    } else if (data['ratings_average'] != null) {
      rating = (data['ratings_average'] as num).toDouble();
    }

    if (data['ratingsCount'] != null) {
      ratingsCount = data['ratingsCount'];
    } else if (data['ratings_count'] != null) {
      ratingsCount = data['ratings_count'];
    }

    return Book(
      id: id,
      title: title,
      author: author,
      description:
          data['description'] ??
          (data['first_sentence'] != null ? data['first_sentence'][0] : ''),
      thumbnailUrl: img,
      pageCount: data['pageCount'] ?? data['number_of_pages_median'],
      rating: rating,
      ratingsCount: ratingsCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'pageCount': pageCount,
      'averageRating': rating,
      'ratingsCount': ratingsCount,
      'status': status,
      if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
    };
  }
}
