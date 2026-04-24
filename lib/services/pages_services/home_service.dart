class HomeService {
  // --- SEZIONI LIBRI ---
  static const List<Map<String, dynamic>> bookSections = [
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

  // --- SEZIONI FILM (Endpoints specifici per Movie) ---
  static const List<Map<String, dynamic>> movieSections = [
    {'header': 'FILM IN EVIDENZA'},
    {'title': 'Più Popolari', 'path': 'popular'},
    {'title': 'Al Cinema ora', 'path': 'now_playing'},
    {'title': 'Grandi Successi (Top)', 'path': 'top_rated'},
    {'title': 'Prossime Uscite', 'path': 'upcoming'},
    {'title': 'Trend della Settimana', 'path': 'trending'},
    {'title': 'TV Movie', 'path': 'with_genres=10770'},

    {'header': 'AZIONE & ADRENALINA'},
    {'title': 'Sci-Fi & Cyberpunk', 'path': 'with_genres=878'},
    {'title': 'Azione', 'path': 'with_genres=28'},
    {'title': 'Avventura', 'path': 'with_genres=12'},
    {'title': 'Thriller', 'path': 'with_genres=53'},
    {'title': 'Crime', 'path': 'with_genres=80'},
    {'title': 'Guerra', 'path': 'with_genres=10752'},
    {'title': 'Mistero Investigativo', 'path': 'with_genres=9648'},

    {'header': 'SENTIMENTO & STORIA'},
    {'title': 'Drammatico', 'path': 'with_genres=18'},
    {'title': 'Romantico', 'path': 'with_genres=10749'},
    {'title': 'Storico', 'path': 'with_genres=36'},
    {'title': 'Western', 'path': 'with_genres=37'},
    {'title': 'Guerra Storica', 'path': 'with_genres=10752'},

    {'header': 'FANTASTICO & DARK'},
    {'title': 'Fantasy', 'path': 'with_genres=14'},
    {'title': 'Horror', 'path': 'with_genres=27'},
    {'title': 'Mistero', 'path': 'with_genres=9648'},
    {'title': 'Sci-Fi Distopico', 'path': 'with_genres=878'},

    {'header': 'INTRATTENIMENTO'},
    {'title': 'Animazione', 'path': 'with_genres=16'},
    {'title': 'Commedia', 'path': 'with_genres=35'},
    {'title': 'Per la Famiglia', 'path': 'with_genres=10751'},
    {'title': 'Musica', 'path': 'with_genres=10402'},
    {'title': 'Documentari', 'path': 'with_genres=99'},
    {'title': 'Comedy Family', 'path': 'with_genres=35'},

    {'header': 'ESPERIENZE CINEMA'},
    {'title': 'Avventura Fantasy', 'path': 'with_genres=12'},
    {'title': 'Crime & Thriller', 'path': 'with_genres=80'},
    {'title': 'Horror Psicologico', 'path': 'with_genres=27'},
    {'title': 'Sci-Fi d’Autore', 'path': 'with_genres=878'},
    {'title': 'Classici Drammatici', 'path': 'with_genres=18'},
  ];

  // --- SEZIONI SERIE TV (Endpoints e IDs specifici per TV) ---
  static const List<Map<String, dynamic>> tvSections = [
    {'header': 'SERIE TV IN EVIDENZA'},
    {'title': 'Trending della Settimana', 'path': 'trending'},
    {'title': 'Più Popolari', 'path': 'popular'},
    {'title': 'Le Migliori di sempre', 'path': 'top_rated'},
    {'title': 'In onda Oggi', 'path': 'airing_today'},
    {'title': 'Novità in arrivo', 'path': 'on_the_air'},
    {'title': 'Docuserie Trend', 'path': 'with_genres=99'},

    {'header': 'SENSE OF WONDER'},
    {
      'title': 'Sci-Fi & Fantasy',
      'path': 'with_genres=10765',
    }, // ID specifico TV
    {
      'title': 'Action & Adventure',
      'path': 'with_genres=10759',
    }, // ID specifico TV
    {'title': 'Animazione', 'path': 'with_genres=16'},
    {'title': 'Fantasy Epico', 'path': 'with_genres=10765'},
    {'title': 'Superhero & Action', 'path': 'with_genres=10759'},

    {'header': 'DRAMMA & TENSIONE'},
    {'title': 'Crime', 'path': 'with_genres=80'},
    {'title': 'Drammatico', 'path': 'with_genres=18'},
    {'title': 'Mistero', 'path': 'with_genres=9648'},
    {
      'title': 'Guerra & Politica',
      'path': 'with_genres=10768',
    }, // ID specifico TV
    {'title': 'Thriller Psicologico', 'path': 'with_genres=9648'},
    {'title': 'Drama Crime', 'path': 'with_genres=80'},

    {'header': 'INTRATTENIMENTO TV'},
    {'title': 'Commedia', 'path': 'with_genres=35'},
    {'title': 'Documentari', 'path': 'with_genres=99'},
    {'title': 'Soap Opera', 'path': 'with_genres=10766'},
    {'title': 'Kids', 'path': 'with_genres=10762'},
    {'title': 'Reality & Talk', 'path': 'with_genres=10767'},
    {'title': 'Family Shows', 'path': 'with_genres=10751'},

    {'header': 'BINGE ZONE'},
    {'title': 'Sitcom & Light', 'path': 'with_genres=35'},
    {'title': 'Crime da Weekend', 'path': 'with_genres=80'},
    {'title': 'Teen & Young Adult', 'path': 'with_genres=10762'},
    {'title': 'Docu Crime', 'path': 'with_genres=99'},
    {'title': 'Action Night', 'path': 'with_genres=10759'},
  ];
}
