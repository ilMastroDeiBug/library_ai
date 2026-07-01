import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:library_ai/domain/entities/media_collection.dart';
import 'package:library_ai/domain/repositories/collection_repository.dart';
import 'package:library_ai/injection_container.dart' as di;
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:library_ai/services/utility_services/open_library_service.dart';

class SupabaseCollectionRepositoryImpl implements CollectionRepository {
  final SupabaseClient _supabase;

  SupabaseCollectionRepositoryImpl(this._supabase);

  // CACHE LOCAL
  final Map<String, StreamController<List<MediaCollection>>>
  _collectionsControllers = {};
  final Map<String, List<MediaCollection>> _cachedCollections = {};

  final Map<int, StreamController<List<MediaCollectionItem>>>
  _itemsControllers = {};
  final Map<int, List<MediaCollectionItem>> _cachedItems = {};

  @override
  Stream<List<MediaCollection>> getCollectionsStream(String userId) async* {
    // 1. Fetch data with normal select (Bypass Realtime issue + 0 egress in background)
    final initialCols = await _fetchCollections(userId);
    _cachedCollections[userId] = initialCols;
    yield initialCols;

    if (!_collectionsControllers.containsKey(userId)) {
      _collectionsControllers[userId] =
          StreamController<List<MediaCollection>>.broadcast();
    }
    yield* _collectionsControllers[userId]!.stream;
  }

  Future<List<MediaCollection>> _fetchCollections(String userId) async {
    try {
      final response = await _supabase
          .from('collections')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<MediaCollection> collections = [];
      for (var row in response) {
        try {
          // Ottieni copertina
          final itemsResponse = await _supabase
              .from('collection_items')
              .select('item_id, item_type')
              .eq('collection_id', row['id'])
              .order('added_at', ascending: true)
              .limit(1)
              .maybeSingle();

          String? coverUrl;
          if (itemsResponse != null) {
            final type = itemsResponse['item_type'];
            final itemIdStr = itemsResponse['item_id'].toString();

            try {
              if (type == 'movie') {
                final mediaResp = await di.sl<TmdbService>().getMovieDetails(
                  int.parse(itemIdStr),
                );
                if (mediaResp.posterPath.isNotEmpty) {
                  coverUrl =
                      'https://image.tmdb.org/t/p/w500${mediaResp.posterPath}';
                }
              } else if (type == 'tv') {
                final mediaResp = await di.sl<TmdbService>().getTvSeriesDetails(
                  int.parse(itemIdStr),
                );
                if (mediaResp.posterPath.isNotEmpty) {
                  coverUrl =
                      'https://image.tmdb.org/t/p/w500${mediaResp.posterPath}';
                }
              } else if (type == 'book') {
                final mediaResp = await OpenLibraryService().fetchBooks(
                  itemIdStr,
                );
                if (mediaResp.isNotEmpty) {
                  coverUrl = mediaResp.first.thumbnailUrl;
                }
              }
            } catch (e) {
              debugPrint('Errore recupero cover $type: $e');
            }
          }

          // Conta elementi in modo sicuro
          final countRes = await _supabase
              .from('collection_items')
              .select('id')
              .eq('collection_id', row['id']);
          final count = (countRes as List).length;

          collections.add(
            MediaCollection(
              id: row['id'],
              userId: row['user_id'],
              name: row['name'],
              description: row['description'],
              createdAt:
                  DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              coverUrl: coverUrl,
              itemCount: count,
            ),
          );
        } catch (e) {
          debugPrint("Errore parsing singola raccolta: $e");
        }
      }
      return collections;
    } catch (e) {
      debugPrint("Errore fetch raccolte: $e");
      return [];
    }
  }

  @override
  Future<MediaCollection> createCollection(
    String userId,
    String name, {
    String? description,
  }) async {
    final response = await _supabase
        .from('collections')
        .insert({'user_id': userId, 'name': name, 'description': description})
        .select()
        .single();

    final newCollection = MediaCollection(
      id: response['id'],
      userId: response['user_id'],
      name: response['name'],
      description: response['description'],
      createdAt: DateTime.parse(response['created_at']),
      itemCount: 0,
    );

    // Aggiornamento ottimistico
    if (_cachedCollections.containsKey(userId)) {
      _cachedCollections[userId] = [
        newCollection,
        ..._cachedCollections[userId]!,
      ];
      _collectionsControllers[userId]?.add(_cachedCollections[userId]!);
    }

    return newCollection;
  }

  @override
  Future<void> deleteCollection(int collectionId) async {
    String? foundUserId;
    for (var entry in _cachedCollections.entries) {
      if (entry.value.any((c) => c.id == collectionId)) {
        foundUserId = entry.key;
        break;
      }
    }

    await _supabase.from('collections').delete().eq('id', collectionId);

    if (foundUserId != null) {
      _cachedCollections[foundUserId]!.removeWhere((c) => c.id == collectionId);
      _collectionsControllers[foundUserId]?.add(
        _cachedCollections[foundUserId]!,
      );
    }
  }

  @override
  Future<void> addMediaToCollection(
    int collectionId,
    String itemId,
    String itemType,
  ) async {
    await _supabase.from('collection_items').upsert({
      'collection_id': collectionId,
      'item_id': itemId,
      'item_type': itemType,
      'added_at': DateTime.now().toIso8601String(),
    });

    // Incrementa ottimisticamente il contatore
    String? foundUserId;
    for (var entry in _cachedCollections.entries) {
      final index = entry.value.indexWhere((c) => c.id == collectionId);
      if (index != -1) {
        final c = entry.value[index];
        entry.value[index] = MediaCollection(
          id: c.id,
          userId: c.userId,
          name: c.name,
          description: c.description,
          createdAt: c.createdAt,
          coverUrl: c.coverUrl,
          itemCount: c.itemCount + 1,
        );
        foundUserId = entry.key;
        break;
      }
    }
    if (foundUserId != null) {
      _collectionsControllers[foundUserId]?.add(
        _cachedCollections[foundUserId]!,
      );
    }

    _triggerBackgroundRefresh(collectionId);
  }

  @override
  Future<void> removeMediaFromCollection(
    int collectionId,
    String itemId,
    String itemType,
  ) async {
    await _supabase
        .from('collection_items')
        .delete()
        .eq('collection_id', collectionId)
        .eq('item_id', itemId)
        .eq('item_type', itemType);

    // Decrementa ottimisticamente il contatore
    String? foundUserId;
    for (var entry in _cachedCollections.entries) {
      final index = entry.value.indexWhere((c) => c.id == collectionId);
      if (index != -1) {
        final c = entry.value[index];
        entry.value[index] = MediaCollection(
          id: c.id,
          userId: c.userId,
          name: c.name,
          description: c.description,
          createdAt: c.createdAt,
          coverUrl: c.coverUrl,
          itemCount: (c.itemCount - 1).clamp(0, 999999),
        );
        foundUserId = entry.key;
        break;
      }
    }
    if (foundUserId != null) {
      _collectionsControllers[foundUserId]?.add(
        _cachedCollections[foundUserId]!,
      );
    }

    _triggerBackgroundRefresh(collectionId);
  }

  void _triggerBackgroundRefresh(int collectionId) async {
    // Ricarica items della collection se in vista
    if (_itemsControllers.containsKey(collectionId)) {
      final items = await _fetchCollectionItems(collectionId);
      _cachedItems[collectionId] = items;
      if (!_itemsControllers[collectionId]!.isClosed) {
        _itemsControllers[collectionId]!.add(items);
      }
    }

    // Ricarica collezioni dell'utente per cover image
    String? foundUserId;
    for (var entry in _cachedCollections.entries) {
      if (entry.value.any((c) => c.id == collectionId)) {
        foundUserId = entry.key;
        break;
      }
    }
    if (foundUserId != null) {
      final cols = await _fetchCollections(foundUserId);
      _cachedCollections[foundUserId] = cols;
      if (!_collectionsControllers[foundUserId]!.isClosed) {
        _collectionsControllers[foundUserId]!.add(cols);
      }
    }
  }

  @override
  Stream<List<MediaCollectionItem>> getCollectionItemsStream(
    int collectionId,
  ) async* {
    final initialItems = await _fetchCollectionItems(collectionId);
    _cachedItems[collectionId] = initialItems;
    yield initialItems;

    if (!_itemsControllers.containsKey(collectionId)) {
      _itemsControllers[collectionId] =
          StreamController<List<MediaCollectionItem>>.broadcast();
    }
    yield* _itemsControllers[collectionId]!.stream;
  }

  Future<List<MediaCollectionItem>> _fetchCollectionItems(
    int collectionId,
  ) async {
    try {
      final response = await _supabase
          .from('collection_items')
          .select()
          .eq('collection_id', collectionId)
          .order('added_at', ascending: false);

      List<MediaCollectionItem> items = [];
      for (var row in response) {
        try {
          String? title;
          String? posterUrl;

          final type = row['item_type'];
          final itemIdStr = row['item_id'].toString();

          try {
            if (type == 'movie') {
              final mediaResp = await di.sl<TmdbService>().getMovieDetails(
                int.parse(itemIdStr),
              );
              title = mediaResp.title;
              if (mediaResp.posterPath.isNotEmpty) {
                posterUrl =
                    'https://image.tmdb.org/t/p/w500${mediaResp.posterPath}';
              }
            } else if (type == 'tv') {
              final mediaResp = await di.sl<TmdbService>().getTvSeriesDetails(
                int.parse(itemIdStr),
              );
              title = mediaResp.name;
              if (mediaResp.posterPath.isNotEmpty) {
                posterUrl =
                    'https://image.tmdb.org/t/p/w500${mediaResp.posterPath}';
              }
            } else if (type == 'book') {
              final mediaResp = await OpenLibraryService().fetchBooks(
                itemIdStr,
              );
              if (mediaResp.isNotEmpty) {
                title = mediaResp.first.title;
                posterUrl = mediaResp.first.thumbnailUrl;
              }
            }
          } catch (e) {
            debugPrint('Errore recupero dettagli media: $e');
          }

          items.add(
            MediaCollectionItem(
              id: row['id'],
              collectionId: row['collection_id'],
              itemId: itemIdStr,
              itemType: type,
              addedAt:
                  DateTime.tryParse(row['added_at']?.toString() ?? '') ??
                  DateTime.now(),
              title: title,
              posterUrl: posterUrl,
            ),
          );
        } catch (e) {
          debugPrint("Errore parsing singolo item: $e");
        }
      }
      return items;
    } catch (e) {
      debugPrint("Errore fetch items: $e");
      return [];
    }
  }

  @override
  Future<List<int>> getItemCollectionIds(
    String userId,
    String itemId,
    String itemType,
  ) async {
    final collections = await _supabase
        .from('collections')
        .select('id')
        .eq('user_id', userId);

    if (collections.isEmpty) return [];

    final List<int> userColIds = (collections as List)
        .map((c) => c['id'] as int)
        .toList();

    final items = await _supabase
        .from('collection_items')
        .select('collection_id')
        .eq('item_id', itemId)
        .eq('item_type', itemType)
        .inFilter('collection_id', userColIds);

    return (items as List).map((i) => i['collection_id'] as int).toList();
  }
}
