import 'dart:async';

/// A single cache entry storing a [future] and the [timestamp] of creation.
class FirestoreCacheEntry<T> {
  FirestoreCacheEntry(this.future, this.timestamp);

  final Future<T> future;
  final DateTime timestamp;
}

/// A generic utility to cache [Future] instances of asynchronous operations.
///
/// If multiple callers call [getOrFetch] concurrently with the same [key] before the
/// operation finishes, they all share the same [Future] instead of starting new ones.
class FirestoreFutureCache<K, V> {
  FirestoreFutureCache({required this.ttl});

  final Duration ttl;
  final Map<K, FirestoreCacheEntry<V>> _cache = {};

  /// Resolves the cached future if it exists and hasn't expired.
  /// Otherwise, runs [fetcher], caches the result, and returns it.
  Future<V> getOrFetch(K key, Future<V> Function() fetcher) {
    final now = DateTime.now();
    final entry = _cache[key];
    if (entry != null && now.difference(entry.timestamp) <= ttl) {
      return entry.future;
    }

    final future = fetcher().catchError((Object e) {
      // Clean up the cache on error so a subsequent attempt will fetch fresh
      _cache.remove(key);
      throw e;
    });

    _cache[key] = FirestoreCacheEntry(future, now);
    return future;
  }

  /// Manually populates the cache with a resolved or pre-existing future.
  void set(K key, Future<V> future) {
    _cache[key] = FirestoreCacheEntry(future, DateTime.now());
  }

  /// Removes an entry from the cache.
  void invalidate(K key) {
    _cache.remove(key);
  }

  /// Clears all entries in the cache.
  void clear() {
    _cache.clear();
  }
}
