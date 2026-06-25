class CacheEntry<T> {
  const CacheEntry(this.value, this.cachedAt);

  final T value;
  final DateTime cachedAt;
}

abstract interface class QuranSessionCacheStore {
  CacheEntry<T>? get<T>(String key);
  void put<T>(String key, CacheEntry<T> entry);
  void remove(String key);

  Future<T>? getInFlight<T>(String key);
  void putInFlight<T>(String key, Future<T> future);
  void removeInFlight(String key);

  void clear();
}

extension QuranSessionCacheStoreExtensions on QuranSessionCacheStore {
  Future<T> getOrFetch<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() fetcher,
  }) async {
    final inFlight = getInFlight<T>(key);
    if (inFlight != null) {
      return inFlight;
    }

    final cached = get<T>(key);
    if (cached != null) {
      final age = DateTime.now().difference(cached.cachedAt);
      if (age <= ttl) {
        return cached.value;
      }
    }

    final future = fetcher()
        .then((value) {
          removeInFlight(key);
          put<T>(key, CacheEntry<T>(value, DateTime.now()));
          return value;
        })
        .catchError((Object e) {
          removeInFlight(key);
          throw e;
        });

    putInFlight<T>(key, future);
    return future;
  }
}
