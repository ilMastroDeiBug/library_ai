class HomeService {
  // Struttura dati per le sezioni
  static const List<Map<String, dynamic>> bookSections = [
    {'header': 'NARRATIVA'},
    {'title': 'Bestsellers & Classici', 'query': 'fiction'},
    {'title': 'Thriller & Suspense', 'query': 'thriller'},
    {'title': 'Sci-Fi & Cyberpunk', 'query': 'science_fiction'},
    {'title': 'Fantasy Epico', 'query': 'fantasy'},
    {'title': 'Avventura', 'query': 'adventure'},
    {'title': 'Romance & Love Stories', 'query': 'romance'},
    {'title': 'Horror & Dark', 'query': 'horror'},
    {'title': 'Gialli & Mistery', 'query': 'mystery'},
    {'title': 'Romanzi Storici', 'query': 'historical_fiction'},

    {'header': 'CONOSCENZA & SVILUPPO'},
    {'title': 'Mindset & Crescita', 'query': 'self_help'},
    {'title': 'Business & Finanza', 'query': 'business'},
    {'title': 'Psicologia', 'query': 'psychology'},
    {'title': 'Filosofia', 'query': 'philosophy'},
    {'title': 'Scienza & Tecnologia', 'query': 'science'},
    {'title': 'Storia', 'query': 'history'},
    {'title': 'Biografie', 'query': 'biography'},
    {'title': 'Arte & Design', 'query': 'art'},

    {'header': 'ALTRI INTERESSI'},
    {'title': 'Graphic Novels & Manga', 'query': 'graphic_novels'},
    {'title': 'Cucina & Food', 'query': 'cooking'},
    {'title': 'Viaggi', 'query': 'travel'},
  ];

  static const List<Map<String, dynamic>> movieSections = [
    {'header': 'IN EVIDENZA'},
    {'title': 'Trending Now', 'path': 'movie/popular'},
    {'title': 'Al Cinema', 'path': 'movie/now_playing'},
    {'title': 'In Arrivo', 'path': 'movie/upcoming'},
    {'title': 'Capolavori Assoluti', 'path': 'movie/top_rated'},

    {'header': 'AZIONE & SCI-FI'},
    {'title': 'Sci-Fi & Cyberpunk', 'path': 'discover/movie?with_genres=878'},
    {
      'title': 'Adrenalina Pura (Azione)',
      'path': 'discover/movie?with_genres=28',
    },
    {'title': 'Avventura', 'path': 'discover/movie?with_genres=12'},
    {'title': 'Thriller', 'path': 'discover/movie?with_genres=53'},
    {'title': 'Guerra', 'path': 'discover/movie?with_genres=10752'},
    {'title': 'Western', 'path': 'discover/movie?with_genres=37'},

    {'header': 'EMOZIONI & STORIE'},
    {'title': 'Drammatici', 'path': 'discover/movie?with_genres=18'},
    {'title': 'Commedia', 'path': 'discover/movie?with_genres=35'},
    {'title': 'Romance', 'path': 'discover/movie?with_genres=10749'},
    {'title': 'Family', 'path': 'discover/movie?with_genres=10751'},
    {'title': 'Animazione', 'path': 'discover/movie?with_genres=16'},

    {'header': 'CULT & DARK'},
    {'title': 'Horror', 'path': 'discover/movie?with_genres=27'},
    {'title': 'Mistero', 'path': 'discover/movie?with_genres=9648'},
    {'title': 'Crime', 'path': 'discover/movie?with_genres=80'},
    {'title': 'Documentari', 'path': 'discover/movie?with_genres=99'},
    {'title': 'Storici', 'path': 'discover/movie?with_genres=36'},
  ];
}
