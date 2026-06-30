import 'package:library_ai/domain/entities/media_collection.dart';

abstract class CollectionRepository {
  Stream<List<MediaCollection>> getCollectionsStream(String userId);
  Future<MediaCollection> createCollection(String userId, String name, {String? description});
  Future<void> deleteCollection(int collectionId);
  Future<void> addMediaToCollection(int collectionId, String itemId, String itemType);
  Future<void> removeMediaFromCollection(int collectionId, String itemId, String itemType);
  Stream<List<MediaCollectionItem>> getCollectionItemsStream(int collectionId);
  Future<List<int>> getItemCollectionIds(String userId, String itemId, String itemType);
}
