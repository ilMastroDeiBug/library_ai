import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:library_ai/services/utility_services/cinelib_cache_service.dart';

void main() {
  late CinelibCacheService service;

  setUpAll(() async {
    final tempPath = Directory.systemTemp.createTempSync('hive_cache_test_').path;
    Hive.init(tempPath);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    await Hive.openBox(CinelibCacheService.boxName);
    service = CinelibCacheService();
  });

  tearDown(() async {
    await Hive.box(CinelibCacheService.boxName).clear();
    await Hive.box(CinelibCacheService.boxName).close();
  });

  group('CinelibCacheService - Media Items (Movies/TV)', () {
    final sampleRow = {
      'media_id': 123,
      'title': 'Test Movie',
      'status': 'watching',
    };

    test('upsertMediaItem saves the item and adds it to the status list', () async {
      await service.upsertMediaItem(
        userId: 'user1',
        mediaId: 123,
        row: sampleRow,
      );

      final box = Hive.box(CinelibCacheService.boxName);
      final detail = box.get('media_user1_123');
      expect(detail, isNotNull);
      expect(detail['title'], 'Test Movie');

      final watchingList = box.get('watchlist_user1_watching') as List?;
      expect(watchingList, isNotNull);
      expect(watchingList!.length, 1);
      expect(watchingList.first['media_id'], 123);
    });

    test('updateMediaStatus moves item to new list and removes from old', () async {
      await service.upsertMediaItem(
        userId: 'user1',
        mediaId: 123,
        row: sampleRow,
      );

      await service.updateMediaStatus(
        userId: 'user1',
        mediaId: 123,
        newStatus: 'watched',
        timestamp: '2023-01-01',
      );

      final box = Hive.box(CinelibCacheService.boxName);
      
      final watchingList = box.get('watchlist_user1_watching') as List?;
      expect(watchingList, isNotNull);
      expect(watchingList!.isEmpty, isTrue);

      final watchedList = box.get('watchlist_user1_watched') as List?;
      expect(watchedList, isNotNull);
      expect(watchedList!.length, 1);
      expect(watchedList.first['status'], 'watched');
      expect(watchedList.first['timestamp'], '2023-01-01');

      final detail = box.get('media_user1_123');
      expect(detail['status'], 'watched');
    });

    test('deleteMediaItem removes detail and cleans up status list', () async {
      await service.upsertMediaItem(
        userId: 'user1',
        mediaId: 123,
        row: sampleRow,
      );

      await service.deleteMediaItem(userId: 'user1', mediaId: 123);

      final box = Hive.box(CinelibCacheService.boxName);
      
      final detail = box.get('media_user1_123');
      expect(detail, isNull);

      final watchingList = box.get('watchlist_user1_watching') as List?;
      expect(watchingList!.isEmpty, isTrue);
    });
  });

  group('CinelibCacheService - Books', () {
    final sampleBook = {
      'book_id': 'OL123W',
      'title': 'Test Book',
      'status': 'reading',
    };

    test('upsertBook saves the book and adds it to the status list', () async {
      await service.upsertBook(
        userId: 'user1',
        bookId: 'OL123W',
        row: sampleBook,
      );

      final box = Hive.box(CinelibCacheService.boxName);
      final detail = box.get('book_user1_OL123W');
      expect(detail, isNotNull);
      expect(detail['title'], 'Test Book');

      final readingList = box.get('books_user1_reading') as List?;
      expect(readingList, isNotNull);
      expect(readingList!.length, 1);
      expect(readingList.first['book_id'], 'OL123W');
    });

    test('safeBookId replaces slashes correctly', () async {
      await service.upsertBook(
        userId: 'user1',
        bookId: '/works/OL123W',
        row: {'book_id': '/works/OL123W', 'status': 'read'},
      );

      final box = Hive.box(CinelibCacheService.boxName);
      // Key should be sanitized
      final detail = box.get('book_user1__works_OL123W');
      expect(detail, isNotNull);
      
      final readList = box.get('books_user1_read') as List?;
      expect(readList!.first['book_id'], '_works_OL123W');
    });

    test('updateBookStatus updates status list properly', () async {
      await service.upsertBook(
        userId: 'user1',
        bookId: 'OL123W',
        row: sampleBook,
      );

      await service.updateBookStatus(
        userId: 'user1',
        bookId: 'OL123W',
        newStatus: 'read',
      );

      final box = Hive.box(CinelibCacheService.boxName);
      expect((box.get('books_user1_reading') as List).isEmpty, isTrue);
      expect((box.get('books_user1_read') as List).length, 1);
    });

    test('deleteBook removes book completely', () async {
      await service.upsertBook(
        userId: 'user1',
        bookId: 'OL123W',
        row: sampleBook,
      );

      await service.deleteBook(userId: 'user1', bookId: 'OL123W');

      final box = Hive.box(CinelibCacheService.boxName);
      expect(box.get('book_user1_OL123W'), isNull);
      expect((box.get('books_user1_reading') as List).isEmpty, isTrue);
    });
  });
}
