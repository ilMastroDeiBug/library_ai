import 'package:library_ai/domain/entities/media_collection.dart';
import 'package:library_ai/domain/repositories/collection_repository.dart';

class GetCollectionsStreamUseCase {
  final CollectionRepository repository;
  GetCollectionsStreamUseCase(this.repository);
  
  Stream<List<MediaCollection>> call(String userId) {
    return repository.getCollectionsStream(userId);
  }
}

class CreateCollectionUseCase {
  final CollectionRepository repository;
  CreateCollectionUseCase(this.repository);
  
  Future<MediaCollection> call(String userId, String name, {String? description}) {
    return repository.createCollection(userId, name, description: description);
  }
}

class DeleteCollectionUseCase {
  final CollectionRepository repository;
  DeleteCollectionUseCase(this.repository);
  
  Future<void> call(int collectionId) {
    return repository.deleteCollection(collectionId);
  }
}

class AddMediaToCollectionUseCase {
  final CollectionRepository repository;
  AddMediaToCollectionUseCase(this.repository);
  
  Future<void> call(int collectionId, String itemId, String itemType) {
    return repository.addMediaToCollection(collectionId, itemId, itemType);
  }
}

class RemoveMediaFromCollectionUseCase {
  final CollectionRepository repository;
  RemoveMediaFromCollectionUseCase(this.repository);
  
  Future<void> call(int collectionId, String itemId, String itemType) {
    return repository.removeMediaFromCollection(collectionId, itemId, itemType);
  }
}

class GetCollectionItemsStreamUseCase {
  final CollectionRepository repository;
  GetCollectionItemsStreamUseCase(this.repository);
  
  Stream<List<MediaCollectionItem>> call(int collectionId) {
    return repository.getCollectionItemsStream(collectionId);
  }
}

class GetItemCollectionIdsUseCase {
  final CollectionRepository repository;
  GetItemCollectionIdsUseCase(this.repository);
  
  Future<List<int>> call(String userId, String itemId, String itemType) {
    return repository.getItemCollectionIds(userId, itemId, itemType);
  }
}
