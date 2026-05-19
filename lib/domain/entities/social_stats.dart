/// Statistiche aggregate del profilo social di un utente.
class SocialStats {
  final int followersCount;
  final int followingCount;
  final int vaultCount;        // Totale opere nel vault (film + serie + libri)
  final int moviesCount;
  final int tvCount;
  final int booksCount;

  const SocialStats({
    this.followersCount = 0,
    this.followingCount = 0,
    this.vaultCount = 0,
    this.moviesCount = 0,
    this.tvCount = 0,
    this.booksCount = 0,
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
    );
  }
}
