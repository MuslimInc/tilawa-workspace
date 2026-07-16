import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_image/domain/services/decoded_quran_image_cache.dart';
import 'package:tilawa/core/logging/app_logger.dart';

/// Responds to **severe** Android memory callbacks (LOW_MEMORY /
/// TRIM_MEMORY_RUNNING_* / MODERATE / COMPLETE) so LMK is less likely to kill
/// the process and force a cold-start ANR (Sentry FLUTTER-9 class).
///
/// Mild OEM noise (e.g. OPPO lock → `TRIM_MEMORY_UI_HIDDEN` / Flutter
/// [WidgetsBindingObserver.didHaveMemoryPressure] while invisible) stays
/// handled in `quran_image` — this bridge is only invoked for severe levels
/// from native [SevereMemoryPressureBridge].
abstract final class AppMemoryPressureHandler {
  static const String channelName = 'com.tilawa.app/memory_pressure';

  /// After a severe trim, keep a smaller Flutter image-cache ceiling until
  /// the next process start (180MB default is restored from DI on cold start).
  static const int severeMaximumSizeBytes = 48 * 1024 * 1024;
  static const int severeMaximumSize = 80;

  static bool _attached = false;
  static MethodChannel? _channel;

  @visibleForTesting
  static bool? debugIsAndroidOverride;

  @visibleForTesting
  static int releaseCallCount = 0;

  /// Idempotent: safe from BootGate and [TilawaApp].
  static void attach({MethodChannel? channel}) {
    if (_attached) {
      return;
    }
    final bool isAndroid =
        debugIsAndroidOverride ?? (!kIsWeb && Platform.isAndroid);
    if (!isAndroid) {
      return;
    }
    _attached = true;
    _channel = channel ?? const MethodChannel(channelName);
    _channel!.setMethodCallHandler(_onMethodCall);
    logger.d(
      '[AppMemoryPressure] attached channel=$channelName',
    );
  }

  static Future<void> _onMethodCall(MethodCall call) async {
    if (call.method != 'severe') {
      return;
    }
    final Object? rawLevel = call.arguments is Map
        ? (call.arguments as Map)['level']
        : call.arguments;
    final int? level = rawLevel is int
        ? rawLevel
        : int.tryParse(rawLevel?.toString() ?? '');
    releaseSevereCaches(level: level);
  }

  /// Clears decoded Quran providers + shrinks Flutter [ImageCache].
  static void releaseSevereCaches({int? level}) {
    releaseCallCount++;
    final ImageCache imageCache = PaintingBinding.instance.imageCache;
    final int beforeBytes = imageCache.currentSizeBytes;
    final int beforeCount = imageCache.currentSize;
    imageCache.clear();
    imageCache.clearLiveImages();
    imageCache.maximumSizeBytes = severeMaximumSizeBytes;
    imageCache.maximumSize = severeMaximumSize;

    bool decodedReleased = false;
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<DecodedQuranImageCache>()) {
      getIt<DecodedQuranImageCache>().handleMemoryPressure();
      decodedReleased = true;
    }

    logger.d(
      '[AppMemoryPressure] severe release '
      'level=$level '
      'imageCacheBeforeBytes=$beforeBytes '
      'imageCacheBeforeCount=$beforeCount '
      'decodedReleased=$decodedReleased '
      'ceilingBytes=$severeMaximumSizeBytes '
      'ceilingEntries=$severeMaximumSize',
    );
  }

  @visibleForTesting
  static void resetForTest() {
    if (_channel != null) {
      _channel!.setMethodCallHandler(null);
    }
    _channel = null;
    _attached = false;
    debugIsAndroidOverride = null;
    releaseCallCount = 0;
  }
}
