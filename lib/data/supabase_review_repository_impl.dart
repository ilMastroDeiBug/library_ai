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
      await _supabase.from('reviews').insert(row);
    }
  }

  @override
  Future<void> voteReview(String reviewId, String userId, int vote) async {
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
    await _supabase
        .from('reviews')
        .delete()
        .eq('id', reviewId)
        .eq('user_id', userId);
    await _removeReviewFromHiveCache(reviewId);
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
            user_id, author, avatar_url,
            review_votes (vote, user_id)
          '''
        : '''
            id, content, rating, created_at,
            user_id,
            review_votes (vote, user_id)
          ''';

    final response = await _supabase
        .from('reviews')
        .select(fields)
        .eq('media_id', mediaId)
        .eq('media_type', mediaType);

    return response
        .map(
          (data) =>
              _mapCustomReview(Map<String, dynamic>.from(data), currentUserId),
        )
        .toList();
  }

  Review _mapCustomReview(Map<String, dynamic> data, String currentUserId) {
    var likes = 0;
    var dislikes = 0;
    var userVote = 0;

    final votes = data['review_votes'] as List<dynamic>? ?? [];
    for (final voteData in votes) {
      final vote = voteData is Map ? voteData['vote'] : null;
      if (vote == 1) likes++;
      if (vote == -1) dislikes++;
      if (voteData is Map && voteData['user_id'] == currentUserId) {
        userVote = vote is int ? vote : 0;
      }
    }

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
      likes: likes,
      dislikes: dislikes,
      userVote: userVote,
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

  Future<void> _removeReviewFromHiveCache(String reviewId) async {
    for (final boxName in const ['cinelib_cache', 'tmdb_cache']) {
      if (!Hive.isBoxOpen(boxName)) continue;

      final box = Hive.box(boxName);
      for (final key in box.keys.toList(growable: false)) {
        final mutation = _removeReviewFromCachedValue(box.get(key), reviewId);
        if (!mutation.changed) continue;

        if (mutation.value == null) {
          await box.delete(key);
        } else {
          await box.put(key, mutation.value);
        }
      }
    }
  }

  _CacheMutation _removeReviewFromCachedValue(Object? value, String reviewId) {
    if (value is List) {
      var changed = false;
      final nextList = <dynamic>[];

      for (final item in value) {
        final mutation = _removeReviewFromCachedValue(item, reviewId);
        if (mutation.changed) {
          changed = true;
        }
        if (mutation.value != null) {
          nextList.add(mutation.value);
        }
      }

      return _CacheMutation(
        value: changed ? nextList : value,
        changed: changed,
      );
    }

    if (value is Map) {
      if (_isCachedReview(value, reviewId)) {
        return const _CacheMutation(value: null, changed: true);
      }

      var changed = false;
      final nextMap = Map<dynamic, dynamic>.from(value);
      for (final entry in nextMap.entries.toList(growable: false)) {
        final mutation = _removeReviewFromCachedValue(entry.value, reviewId);
        if (!mutation.changed) continue;

        changed = true;
        if (mutation.value == null) {
          nextMap.remove(entry.key);
        } else {
          nextMap[entry.key] = mutation.value;
        }
      }

      return _CacheMutation(value: changed ? nextMap : value, changed: changed);
    }

    return _CacheMutation(value: value, changed: false);
  }

  bool _isCachedReview(Map<dynamic, dynamic> value, String reviewId) {
    final id = value['id']?.toString();
    return id == reviewId &&
        value.containsKey('content') &&
        value.containsKey('rating');
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
