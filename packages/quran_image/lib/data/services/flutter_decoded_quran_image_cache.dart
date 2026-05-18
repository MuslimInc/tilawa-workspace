import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/domain/services/decoded_quran_image_cache.dart';

class FlutterDecodedQuranImageCache implements DecodedQuranImageCache {
  static const int _lineCountPerPage = 15;
  // Keep a wider provider window to reduce trim churn after long jumps
  // followed by rapid swipes.
  static const int _maxWarmPages = 10;
  static const int _maxFileEntries = 8;
  static const int _maxProviderEntries =
      (_maxWarmPages * _lineCountPerPage) + _maxFileEntries;
  static const int _maxWarmEntries = _maxProviderEntries;
  static const int _evictionsPerBatch = 2;
  static const Duration _trimPaceDelay = Duration(milliseconds: 16);

  final LinkedHashMap<String, ImageProvider<Object>> _providerCache =
      LinkedHashMap<String, ImageProvider<Object>>();
  final LinkedHashSet<String> _warmKeys = LinkedHashSet<String>();
  final LinkedHashMap<String, Future<void>> _pendingWarmups =
      LinkedHashMap<String, Future<void>>();
  int _generation = 0;
  bool _trimFrameScheduled = false;
  Timer? _trimPaceTimer;

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) => _ensureWarm(
    cacheKey: _lineKey(imagePath, cacheWidth),
    provider: _lineProvider(imagePath, cacheWidth),
  );

  @override
  Future<void> prewarmFileImage(String imagePath) => _ensureWarm(
    cacheKey: 'file:$imagePath',
    provider: _fileProvider(imagePath),
  );

  @override
  void handleMemoryPressure() {
    _generation++;
    _trimPaceTimer?.cancel();
    _trimPaceTimer = null;
    _trimFrameScheduled = false;
    final providerCount = _providerCache.length;
    final warmCount = _warmKeys.length;
    for (final provider in _providerCache.values) {
      unawaited(provider.evict());
    }
    _providerCache.clear();
    _warmKeys.clear();
    // Do NOT call PaintingBinding.instance.imageCache.clear() here.
    // Flutter's imageCache already responds to memory pressure via its own
    // MemoryAllocations listener. Clearing it manually evicts images that
    // other widgets may be actively displaying, causing a re-decode burst on
    // the next frame — the exact opposite of what memory pressure handling
    // should achieve. Our per-provider evict() calls above are sufficient.
    PerfLogger.log(
      widgetName: 'FlutterDecodedQuranImageCache',
      message:
          'memory pressure handled '
          'evictedProviders=$providerCount '
          'evictedWarmEntries=$warmCount',
    );
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
    _trimProviderCache();
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
    _trimProviderCache();
    return provider;
  }

  void _rememberWarmKey(String key) {
    _warmKeys.remove(key);
    _warmKeys.add(key);
    _trimWarmKeys();
  }

  Future<void> _ensureWarm({
    required String cacheKey,
    required ImageProvider<Object> provider,
  }) {
    if (_warmKeys.remove(cacheKey)) {
      _warmKeys.add(cacheKey);
      PerfLogger.log(
        widgetName: 'FlutterDecodedQuranImageCache',
        message: 'warm cache hit key=$cacheKey',
      );
      return SynchronousFuture<void>(null);
    }

    final pending = _pendingWarmups.remove(cacheKey);
    if (pending != null) {
      _pendingWarmups[cacheKey] = pending;
      PerfLogger.log(
        widgetName: 'FlutterDecodedQuranImageCache',
        message: 'warm await pending key=$cacheKey',
      );
      return pending;
    }

    final future = _resolve(provider, cacheKey: cacheKey);
    _pendingWarmups[cacheKey] = future;
    return future;
  }

  Future<void> _resolve(
    ImageProvider<Object> provider, {
    required String cacheKey,
  }) {
    final completer = Completer<void>();
    final generation = _generation;
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
          _pendingWarmups.remove(cacheKey);
          if (generation == _generation) {
            _rememberWarmKey(cacheKey);
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (error, stackTrace) {
          stream.removeListener(listener);
          _pendingWarmups.remove(cacheKey);
          PerfLogger.log(
            widgetName: 'FlutterDecodedQuranImageCache',
            message: 'warm failed key=$cacheKey error=$error',
          );
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace ?? StackTrace.empty);
          }
        },
      );
      stream.addListener(listener);
    } catch (error, stackTrace) {
      _pendingWarmups.remove(cacheKey);
      PerfLogger.log(
        widgetName: 'FlutterDecodedQuranImageCache',
        message: 'resolve failed key=$cacheKey error=$error',
      );
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      // Image prewarming is opportunistic; visible widgets still handle errors.
    }
    return completer.future;
  }

  static String _lineKey(String imagePath, int cacheWidth) =>
      '$cacheWidth:$imagePath';

  void _trimProviderCache() {
    if (_providerCache.length <= _maxProviderEntries) {
      return;
    }

    // Guard against bursty call-sites (multiple provider insertions in the
    // same window). Once a paced trim is scheduled, we let that timer own
    // further eviction work for this window.
    if (_trimFrameScheduled) {
      return;
    }

    int evicted = 0;
    while (_providerCache.length > _maxProviderEntries &&
        evicted < _evictionsPerBatch) {
      final eldestKey = _providerCache.keys.first;
      final provider = _providerCache.remove(eldestKey);
      _warmKeys.remove(eldestKey);
      if (provider != null) {
        unawaited(provider.evict());
      }
      PerfLogger.log(
        widgetName: 'FlutterDecodedQuranImageCache',
        message: 'provider evicted key=$eldestKey reason=provider-cache-trim',
      );
      evicted++;
    }

    if (_providerCache.length > _maxProviderEntries && !_trimFrameScheduled) {
      _trimFrameScheduled = true;
      _trimPaceTimer?.cancel();
      _trimPaceTimer = Timer(_trimPaceDelay, () {
        _trimFrameScheduled = false;
        _trimPaceTimer = null;
        _trimProviderCache();
      });
      PerfLogger.log(
        widgetName: 'FlutterDecodedQuranImageCache',
        message:
            'provider cache trim pacing scheduled '
            'evictedInBatch=$evicted '
            'delayMs=${_trimPaceDelay.inMilliseconds} '
            'remaining=${_providerCache.length}',
      );
    }
  }

  void _trimWarmKeys() {
    while (_warmKeys.length > _maxWarmEntries) {
      final eldestKey = _warmKeys.first;
      _warmKeys.remove(eldestKey);
      final provider = _providerCache.remove(eldestKey);
      if (provider != null) {
        unawaited(provider.evict());
      }
      PerfLogger.log(
        widgetName: 'FlutterDecodedQuranImageCache',
        message: 'provider evicted key=$eldestKey reason=warm-cache-trim',
      );
    }
  }
}
