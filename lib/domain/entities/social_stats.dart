/// Statistiche aggregate del profilo social di un utente.
class SocialStats {
  final int followersCount;
  final int followingCount;
  final int vaultCount;        // Totale opere nel vault (film + serie + libri)
  final int moviesCount;
  final int tvCount;
  final int booksCount;
  
  final int totalMinutes;
  final int yearMinutes;
  final int monthMinutes;
  final int weekMinutes;
  final int watchlistCount;

  const SocialStats({
    this.followersCount = 0,
    this.followingCount = 0,
    this.vaultCount = 0,
    this.moviesCount = 0,
    this.tvCount = 0,
    this.booksCount = 0,
    this.totalMinutes = 0,
    this.yearMinutes = 0,
    this.monthMinutes = 0,
    this.weekMinutes = 0,
    this.watchlistCount = 0,
  });

  factory SocialStats.fromMap(Map<String, dynamic> map) {
    final movies = (map['movies_count'] as num?)?.toInt() ?? 0;
    final tv = (map['tv_count'] as num?)?.toInt() ?? 0;
    final books = (map['books_count'] as num?)?.toInt() ?? 0;
    return SocialStats(
      followersCount: (map['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (map['following_count'] as num?)?.toInt() ?? 0,
      vaultCount: movies + tv + books,
      moviesCount: movies,
      tvCount: tv,
      booksCount: books,
      totalMinutes: (map['total_minutes'] as num?)?.toInt() ?? 0,
      yearMinutes: (map['year_minutes'] as num?)?.toInt() ?? 0,
      monthMinutes: (map['month_minutes'] as num?)?.toInt() ?? 0,
      weekMinutes: (map['week_minutes'] as num?)?.toInt() ?? 0,
      watchlistCount: (map['watchlist_count'] as num?)?.toInt() ?? 0,
    );
  }
}
