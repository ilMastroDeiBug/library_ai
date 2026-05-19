import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/repositories/review_repository.dart';
import '../domain/entities/review.dart';
import '../services/utility_services/tmdb_service.dart';
import '../injection_container.dart';

class SupabaseReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _supabase;
  final TmdbService _tmdbService;

  SupabaseReviewRepositoryImpl({
    SupabaseClient? supabaseClient,
    TmdbService? tmdbService,
  }) : _supabase = supabaseClient ?? Supabase.instance.client,
       _tmdbService = tmdbService ?? sl<TmdbService>();

  @override
  Future<List<Review>> getMediaReviews(
    int mediaId,
    String mediaType,
    String currentUserId, {
    String sortBy = 'relevance',
  }) async {
    final allReviews = <Review>[];

    try {
      allReviews.addAll(
        await _fetchCustomReviews(
          mediaId: mediaId,
          mediaType: mediaType,
          currentUserId: currentUserId,
          includeAuthorFields: true,
        ),
      );
    } on PostgrestException catch (e) {
      try {
        allReviews.addAll(
          await _fetchCustomReviews(
            mediaId: mediaId,
            mediaType: mediaType,
            currentUserId: currentUserId,
            includeAuthorFields: false,
          ),
        );
      } catch (fallbackError) {
        print("Errore Supabase Reviews: $e / fallback: $fallbackError");
      }
    } catch (e) {
      print("Errore Supabase Reviews: $e");
    }

    try {
      final tmdbReviews = await _tmdbService.fetchReviews(
        mediaId,
        isTv: mediaType == 'tv',
      );
      allReviews.addAll(tmdbReviews);
    } catch (e) {
      print("Errore TMDB Reviews: $e");
    }

    final customList = allReviews.where((review) => review.isCustom).toList();
    final tmdbList = allReviews.where((review) => !review.isCustom).toList();

    int sortFunction(Review a, Review b) {
      switch (sortBy) {
        case 'recent':
          return (b.createdAt ?? DateTime(2000)).compareTo(
            a.createdAt ?? DateTime(2000),
          );
        case 'rating_desc':
          return b.rating.compareTo(a.rating);
        case 'rating_asc':
          return a.rating.compareTo(b.rating);
        case 'relevance':
        default:
          return b.relevanceScore.compareTo(a.relevanceScore);
      }
    }

    customList.sort(sortFunction);
    tmdbList.sort(sortFunction);

    return [...customList, ...tmdbList];
  }

  @override
  Future<void> submitReview(
    int mediaId,
    String mediaType,
    String userId,
    String content,
    double rating,
  ) async {
    final author = await _resolveReviewAuthor(userId);
    final row = <String, dynamic>{
      'media_id': mediaId,
      'media_type': mediaType,
      'user_id': userId,
      'content': content,
      'rating': rating,
      'author': author.name,
      'avatar_url': author.avatarUrl,
    };

    try {
      await _supabase.from('reviews').insert(row);
    } on PostgrestException catch (_) {
      row.remove('author');
      row.remove('avatar_url');
      try {
        await _supabase.from('reviews').insert(row);
      } catch (_) {}
    } catch (_) {
      // Ignora errori di connessione
    }
  }

  @override
  Future<void> voteReview(String reviewId, String userId, int vote) async {
    try {
      if (vote == 0) {
        await _supabase
            .from('review_votes')
            .delete()
            .eq('review_id', reviewId)
            .eq('user_id', userId);
      } else {
        await _supabase.from('review_votes').upsert({
          'review_id': reviewId,
          'user_id': userId,
          'vote': vote,
        }, onConflict: 'review_id,user_id');
      }
    } catch (_) {
      // Ignora errori di rete offline
    }
  }

  @override
  Future<void> deleteReview(String reviewId, String userId) async {
    final ownedReview = await _supabase
        .from('reviews')
        .select('id')
        .eq('id', reviewId)
        .eq('user_id', userId)
        .maybeSingle();

    if (ownedReview == null) {
      throw Exception('Puoi eliminare solo le recensioni che hai scritto tu.');
    }

    try {
      await _supabase.from('review_votes').delete().eq('review_id', reviewId);
    } catch (_) {
      // Se il DB ha ON DELETE CASCADE, la delete della review pulira i voti.
    }
    try {
      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', userId);
      // Il collo di bottiglia di Hive (O(N) full table scan) è stato rimosso
      // in quanto le recensioni Custom non vengono memorizzate e rilette
      // in 'tmdb_cache' o 'cinelib_cache' come intere istanze.
    } catch (_) {}
  }

  Future<List<Review>> _fetchCustomReviews({
    required int mediaId,
    required String mediaType,
    required String currentUserId,
    required bool includeAuthorFields,
  }) async {
    final fields = includeAuthorFields
        ? '''
            id, content, rating, created_at,
            user_id, author, avatar_url, likes_count, dislikes_count
          '''
        : '''
            id, content, rating, created_at,
            user_id, likes_count, dislikes_count
          ''';

    final response = await _supabase
        .from('reviews')
        .select(fields)
        .eq('media_id', mediaId)
        .eq('media_type', mediaType);

    final customReviews = response
        .map(
          (data) =>
              _mapCustomReview(Map<String, dynamic>.from(data), currentUserId),
        )
        .toList();

    // Fix Data Overfetching (N+1): Scarichiamo solo il voto dell'utente corrente!
    if (customReviews.isNotEmpty) {
      try {
        final reviewIds = customReviews.map((r) => r.id).toList();
        final votesResponse = await _supabase
            .from('review_votes')
            .select('review_id, vote')
            .eq('user_id', currentUserId)
            .filter('review_id', 'in', '(${reviewIds.join(",")})');

        final userVotes = <String, int>{};
        for (final voteData in votesResponse) {
           userVotes[voteData['review_id'].toString()] = voteData['vote'] as int;
        }

        for (var i = 0; i < customReviews.length; i++) {
          final rev = customReviews[i];
          if (userVotes.containsKey(rev.id)) {
            customReviews[i] = rev.copyWith(userVote: userVotes[rev.id]);
          }
        }
      } catch (e) {
        print("Errore nel recupero voti utente: $e");
      }
    }

    return customReviews;
  }

  Review _mapCustomReview(Map<String, dynamic> data, String currentUserId) {
    return Review(
      id: data['id'].toString(),
      userId: data['user_id']?.toString(),
      author: _readString(data['author']) ?? 'Utente CineShare',
      content: data['content'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      avatarUrl: _readString(data['avatar_url']),
      isCustom: true,
      likes: data['likes_count'] as int? ?? 0,
      dislikes: data['dislikes_count'] as int? ?? 0,
      userVote: 0, // Verrà popolato dalla seconda query ottimizzata
    );
  }

  Future<_ReviewAuthor> _resolveReviewAuthor(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('display_name, photo_url, email')
          .eq('id', userId)
          .maybeSingle();

      if (profile != null) {
        final name =
            _readString(profile['display_name']) ??
            _readString(profile['email']);
        if (name != null) {
          return _ReviewAuthor(
            name: name,
            avatarUrl: _readString(profile['photo_url']),
          );
        }
      }
    } catch (_) {
      // Fallback sui metadata auth.
    }

    final currentUser = _supabase.auth.currentUser;
    final metadata = currentUser?.userMetadata ?? {};
    final name =
        _readString(metadata['display_name']) ??
        _readString(metadata['name']) ??
        _readString(currentUser?.email) ??
        'Utente CineShare';

    return _ReviewAuthor(
      name: name,
      avatarUrl:
          _readString(metadata['avatar_url']) ??
          _readString(metadata['picture']),
    );
  }

  String? _readString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class _ReviewAuthor {
  final String name;
  final String? avatarUrl;

  const _ReviewAuthor({required this.name, this.avatarUrl});
}

class _CacheMutation {
  final Object? value;
  final bool changed;

  const _CacheMutation({required this.value, required this.changed});
}
