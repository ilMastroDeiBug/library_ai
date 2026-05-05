class CacheWrapper<T> {
  static const String dataField = 'data';
  static const String cachedAtField = 'cachedAt';

  final T data;
  final DateTime cachedAt;

  const CacheWrapper({
    required this.data,
    required this.cachedAt,
  });

  Map<String, Object?> toHiveMap() => {
    dataField: data,
    cachedAtField: cachedAt.toIso8601String(),
  };

  bool isExpired(Duration ttl, {DateTime? now}) {
    final referenceTime = now ?? DateTime.now();
    return referenceTime.difference(cachedAt) > ttl;
  }

  static CacheWrapper<R>? fromHive<R>(Object? cachedValue) {
    if (cachedValue is! Map) return null;

    final rawCachedAt = cachedValue[cachedAtField];
    final cachedAt = _parseCachedAt(rawCachedAt);
    if (cachedAt == null || !cachedValue.containsKey(dataField)) {
      return null;
    }

    try {
      return CacheWrapper<R>(
        data: cachedValue[dataField] as R,
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseCachedAt(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
