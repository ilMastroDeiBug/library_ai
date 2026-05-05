import 'package:hive/hive.dart';

typedef _CacheRowPredicate = bool Function(Map<String, dynamic> row);
typedef _CacheRowTransform =
    Map<String, dynamic> Function(Map<String, dynamic> row);

class CinelibCacheService {
  static const String boxName = 'cinelib_cache';

  Box get _box => Hive.box(boxName);

  Future<void> upsertMediaItem({
    required String userId,
    required int mediaId,
    required Map<String, dynamic> row,
  }) async {
    final normalizedRow = Map<String, dynamic>.from(row);
    await _box.put(_mediaDetailKey(userId, mediaId), normalizedRow);

    final status = normalizedRow['status']?.toString();
    if (status == null || status.isEmpty) return;

    await _moveRowAcrossStatusLists(
      listKeyPrefix: _watchlistPrefix(userId),
      destinationStatus: status,
      matches: (row) => _sameCacheValue(row['media_id'], mediaId),
      transform: (_) => Map<String, dynamic>.from(normalizedRow),
      fallbackRow: normalizedRow,
    );
  }

  Future<void> updateMediaStatus({
    required String userId,
    required int mediaId,
    required String newStatus,
    String? timestamp,
  }) async {
    final detailKey = _mediaDetailKey(userId, mediaId);
    final cachedDetail = _readRow(_box.get(detailKey));

    Map<String, dynamic> applyStatus(Map<String, dynamic> row) {
      final updatedRow = Map<String, dynamic>.from(row);
      updatedRow['status'] = newStatus;
      if (timestamp != null) {
        updatedRow['timestamp'] = timestamp;
      }
      return updatedRow;
    }

    final updatedRow = await _moveRowAcrossStatusLists(
      listKeyPrefix: _watchlistPrefix(userId),
      destinationStatus: newStatus,
      matches: (row) => _sameCacheValue(row['media_id'], mediaId),
      transform: applyStatus,
      fallbackRow: cachedDetail,
    );

    if (updatedRow != null) {
      await _box.put(detailKey, updatedRow);
    }
  }

  Future<void> deleteMediaItem({
    required String userId,
    required int mediaId,
  }) async {
    await _box.delete(_mediaDetailKey(userId, mediaId));
    await _removeRowsFromLists(
      listKeyPrefix: _watchlistPrefix(userId),
      matches: (row) => _sameCacheValue(row['media_id'], mediaId),
    );
  }

  Future<void> upsertBook({
    required String userId,
    required String bookId,
    required Map<String, dynamic> row,
  }) async {
    final safeBookId = _safeBookId(bookId);
    final normalizedRow = Map<String, dynamic>.from(row);
    await _box.put(_bookDetailKey(userId, safeBookId), normalizedRow);

    final status = normalizedRow['status']?.toString();
    if (status == null || status.isEmpty) return;

    await _moveRowAcrossStatusLists(
      listKeyPrefix: _booksPrefix(userId),
      destinationStatus: status,
      matches: (row) => _sameCacheValue(row['book_id'], safeBookId),
      transform: (_) => Map<String, dynamic>.from(normalizedRow),
      fallbackRow: normalizedRow,
    );
  }

  Future<void> updateBookStatus({
    required String userId,
    required String bookId,
    required String newStatus,
    String? timestamp,
  }) async {
    final safeBookId = _safeBookId(bookId);
    final detailKey = _bookDetailKey(userId, safeBookId);
    final cachedDetail = _readRow(_box.get(detailKey));

    Map<String, dynamic> applyStatus(Map<String, dynamic> row) {
      final updatedRow = Map<String, dynamic>.from(row);
      updatedRow['status'] = newStatus;
      if (timestamp != null) {
        updatedRow['timestamp'] = timestamp;
      }
      return updatedRow;
    }

    final updatedRow = await _moveRowAcrossStatusLists(
      listKeyPrefix: _booksPrefix(userId),
      destinationStatus: newStatus,
      matches: (row) => _sameCacheValue(row['book_id'], safeBookId),
      transform: applyStatus,
      fallbackRow: cachedDetail,
    );

    if (updatedRow != null) {
      await _box.put(detailKey, updatedRow);
    }
  }

  Future<void> deleteBook({
    required String userId,
    required String bookId,
  }) async {
    final safeBookId = _safeBookId(bookId);
    await _box.delete(_bookDetailKey(userId, safeBookId));
    await _removeRowsFromLists(
      listKeyPrefix: _booksPrefix(userId),
      matches: (row) => _sameCacheValue(row['book_id'], safeBookId),
    );
  }

  Future<Map<String, dynamic>?> _moveRowAcrossStatusLists({
    required String listKeyPrefix,
    required String destinationStatus,
    required _CacheRowPredicate matches,
    required _CacheRowTransform transform,
    Map<String, dynamic>? fallbackRow,
  }) async {
    final destinationKey = '$listKeyPrefix$destinationStatus';
    final keys = _keysWithPrefix(listKeyPrefix);
    final destinationIsCached = keys.contains(destinationKey);
    Map<String, dynamic>? movedRow = fallbackRow == null
        ? null
        : transform(fallbackRow);

    for (final key in keys) {
      final rows = _readRows(_box.get(key));
      if (rows == null) continue;

      var changed = false;
      final nextRows = <Map<String, dynamic>>[];

      for (final row in rows) {
        if (matches(row)) {
          changed = true;
          movedRow = transform(row);
          if (key == destinationKey) {
            nextRows.add(Map<String, dynamic>.from(movedRow!));
          }
        } else {
          nextRows.add(row);
        }
      }

      if (changed) {
        await _box.put(key, nextRows);
      }
    }

    if (destinationIsCached && movedRow != null) {
      final destinationRows = _readRows(_box.get(destinationKey)) ?? [];
      final deduplicatedRows = destinationRows
          .where((row) => !matches(row))
          .toList();
      deduplicatedRows.insert(0, Map<String, dynamic>.from(movedRow));
      await _box.put(destinationKey, deduplicatedRows);
    }

    return movedRow;
  }

  Future<void> _removeRowsFromLists({
    required String listKeyPrefix,
    required _CacheRowPredicate matches,
  }) async {
    for (final key in _keysWithPrefix(listKeyPrefix)) {
      final rows = _readRows(_box.get(key));
      if (rows == null) continue;

      final nextRows = rows.where((row) => !matches(row)).toList();
      if (nextRows.length != rows.length) {
        await _box.put(key, nextRows);
      }
    }
  }

  List<String> _keysWithPrefix(String prefix) {
    return _box.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
  }

  Map<String, dynamic>? _readRow(Object? cached) {
    if (cached is! Map) return null;
    return Map<String, dynamic>.from(cached);
  }

  List<Map<String, dynamic>>? _readRows(Object? cached) {
    if (cached is! List) return null;
    return cached
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  bool _sameCacheValue(Object? rawValue, Object expectedValue) {
    return rawValue?.toString() == expectedValue.toString();
  }

  String _watchlistPrefix(String userId) => 'watchlist_${userId}_';

  String _booksPrefix(String userId) => 'books_${userId}_';

  String _mediaDetailKey(String userId, int mediaId) =>
      'media_${userId}_$mediaId';

  String _bookDetailKey(String userId, String bookId) =>
      'book_${userId}_$bookId';

  String _safeBookId(String bookId) => bookId.replaceAll('/', '_');
}
