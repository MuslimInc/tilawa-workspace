import '../../application/cache/quran_session_cache_store.dart';

class MemoryCacheStore implements QuranSessionCacheStore {
  final Map<String, CacheEntry<dynamic>> _resolved = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  @override
  CacheEntry<T>? get<T>(String key) {
    final entry = _resolved[key];
    if (entry is CacheEntry<T>) {
      return entry;
    }
    return null;
  }

  @override
  void put<T>(String key, CacheEntry<T> entry) {
    _resolved[key] = entry;
  }

  @override
  void remove(String key) {
    _resolved.remove(key);
    _inFlight.remove(key);
  }

  @override
  Future<T>? getInFlight<T>(String key) {
    final future = _inFlight[key];
    if (future is Future<T>) {
      return future;
    }
    return null;
  }

  @override
  void putInFlight<T>(String key, Future<T> future) {
    _inFlight[key] = future;
  }

  @override
  void removeInFlight(String key) {
    _inFlight.remove(key);
  }

  @override
  void clear() {
    _resolved.clear();
    _inFlight.clear();
  }
}
