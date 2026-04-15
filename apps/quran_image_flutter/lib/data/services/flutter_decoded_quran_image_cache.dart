import 'dart:collection';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:quran_image_flutter/domain/services/decoded_quran_image_cache.dart';

class FlutterDecodedQuranImageCache implements DecodedQuranImageCache {
  static const int _maxProviderEntries = 512;
  static const int _maxWarmEntries = 768;

  final LinkedHashMap<String, ImageProvider<Object>> _providerCache =
      LinkedHashMap<String, ImageProvider<Object>>();
  final LinkedHashSet<String> _pendingKeys = LinkedHashSet<String>();
  final LinkedHashSet<String> _warmKeys = LinkedHashSet<String>();

  @override
  void prewarmLineImage({required String imagePath, required int cacheWidth}) {
    final key = _lineKey(imagePath, cacheWidth);
    if (!_shouldPrewarm(key)) return;

    _resolve(_lineProvider(imagePath, cacheWidth), cacheKey: key);
  }

  @override
  void prewarmFileImage(String imagePath) {
    final key = 'file:$imagePath';
    if (!_shouldPrewarm(key)) return;

    _resolve(_fileProvider(imagePath), cacheKey: key);
  }

  @override
  Future<bool> isLineImageCached({
    required String imagePath,
    required int cacheWidth,
  }) async {
    final key = _lineKey(imagePath, cacheWidth);
    if (_warmKeys.remove(key)) {
      _warmKeys.add(key);
      return true;
    }

    final provider = _lineProvider(imagePath, cacheWidth);
    // Must use obtainCacheStatus() — NOT imageCache.statusForKey(provider).
    // statusForKey takes the resolved cache key (e.g. _SizeAwareCacheKey),
    // not the ImageProvider itself. Passing the provider always returns
    // untracked because the provider instance is never the map key.
    // obtainCacheStatus resolves the key via obtainKey() first, then checks
    // the cache correctly.
    //
    // keepAlive: fully decoded and stored in the LRU cache — ready to paint.
    // live: held by at least one live ImageStream — also fully decoded.
    // pending is intentionally excluded: decode is in-flight but not complete.
    // Jumping when images are pending causes visible blank lines for seconds
    // while the codec finishes. We must wait for keepAlive/live.
    final status = await provider.obtainCacheStatus(
      configuration: ImageConfiguration.empty,
    );
    final isReady = status != null && (status.keepAlive || status.live);
    if (isReady) {
      _rememberWarmKey(key);
    }
    return isReady;
  }

  bool _shouldPrewarm(String key) {
    if (_warmKeys.remove(key)) {
      _warmKeys.add(key);
      return false;
    }
    return _pendingKeys.add(key);
  }

  ImageProvider<Object> _lineProvider(String imagePath, int cacheWidth) {
    final key = _lineKey(imagePath, cacheWidth);
    final cached = _providerCache.remove(key);
    if (cached != null) {
      _providerCache[key] = cached;
      return cached;
    }

    final provider = ResizeImage.resizeIfNeeded(
      cacheWidth,
      null,
      FileImage(File(imagePath)),
    );
    _providerCache[key] = provider;
    _trimMap(_providerCache, _maxProviderEntries);
    return provider;
  }

  ImageProvider<Object> _fileProvider(String imagePath) {
    final key = 'file:$imagePath';
    final cached = _providerCache.remove(key);
    if (cached != null) {
      _providerCache[key] = cached;
      return cached;
    }

    final provider = FileImage(File(imagePath));
    _providerCache[key] = provider;
    _trimMap(_providerCache, _maxProviderEntries);
    return provider;
  }

  void _rememberWarmKey(String key) {
    _pendingKeys.remove(key);
    _warmKeys.remove(key);
    _warmKeys.add(key);
    _trimSet(_warmKeys, _maxWarmEntries);
  }

  void _resolve(ImageProvider<Object> provider, {required String cacheKey}) {
    try {
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (image, _) {
          // Release our local handle immediately. The image stays alive in
          // Flutter's imageCache as keepAlive — no post-frame deferral needed.
          // Deferring to addPostFrameCallback added one callback per decoded
          // image per frame, creating event-loop pressure during rapid swiping.
          image.dispose();
          stream.removeListener(listener);
          _rememberWarmKey(cacheKey);
        },
        onError: (_, _) {
          stream.removeListener(listener);
          _pendingKeys.remove(cacheKey);
        },
      );
      stream.addListener(listener);
    } catch (_) {
      _pendingKeys.remove(cacheKey);
      // Image prewarming is opportunistic; visible widgets still handle errors.
    }
  }

  static String _lineKey(String imagePath, int cacheWidth) =>
      '$cacheWidth:$imagePath';

  static void _trimMap<K, V>(LinkedHashMap<K, V> map, int maxEntries) {
    while (map.length > maxEntries) {
      map.remove(map.keys.first);
    }
  }

  static void _trimSet<K>(LinkedHashSet<K> set, int maxEntries) {
    while (set.length > maxEntries) {
      set.remove(set.first);
    }
  }
}
