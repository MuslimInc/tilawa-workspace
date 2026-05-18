import 'package:flutter/painting.dart';
import 'package:get_it/get_it.dart';
import 'package:quran_image/core/di/dependency_injection.dart'
    as quran_image_di;
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

/// Initialises the `quran_image` package dependencies within the
/// Tilawa app's shared [GetIt] container.
///
/// The `quran_image` package registers its own repositories, use cases,
/// and services via [quran_image_di.initDependencies]. Because both
/// packages share [`GetIt.instance`], the package DI handles its own
/// duplicate registration checks for [SharedPreferencesAsync].
///
/// Call this **after** Tilawa's own `configureDependencies()` completes
/// so that the Tilawa-side registrations take precedence.
class QuranImageDependenciesModule {
  const QuranImageDependenciesModule._();

  /// Registers all `quran_image` dependencies.
  ///
  /// Safe to call multiple times — skips if the container already
  /// has the required registrations.
  static Future<void> initialize() async {
    final GetIt container = GetIt.instance;

    // SharedPreferencesAsync is already registered by Tilawa.
    // Unregister quran_image's duplicate before it registers, or
    // skip the quran_image registration if already present.
    final bool alreadyHasPrefs = container
        .isRegistered<SharedPreferencesAsync>();

    if (alreadyHasPrefs) {
      logger.d(
        '[QuranImagesPerformance] source=QuranImageDI SharedPreferencesAsync already registered — '
        'package will skip its own registration',
      );
    }

    await quran_image_di.initDependencies();

    if (alreadyHasPrefs) {
      logger.d(
        '[QuranImagesPerformance] source=QuranImageDI SharedPreferencesAsync reuse successful',
      );
    }

    _configureImageCache();

    logger.d(
      '[QuranImagesPerformance] source=QuranImageDI quran_image dependencies initialized',
    );
  }

  /// Configures the Flutter image cache for the Quran image reader.
  ///
  /// The reader keeps nearby pages warm around the current page and
  /// may also hold recently previewed slider targets. This is still
  /// a bounded LRU cache, not a decoded cache of all 9,060 Quran
  /// line images.
  static void _configureImageCache() {
    const int bytesPerMb = 1024 * 1024;
    final ImageCache imageCache = PaintingBinding.instance.imageCache;

    // Match the image cache settings from quran_image's main.dart
    imageCache.maximumSizeBytes = 180 * bytesPerMb;
    imageCache.maximumSize = 300;

    logger.d(
      '[QuranImagesPerformance] source=QuranImageDI image cache configured: '
      'maxBytes=${imageCache.maximumSizeBytes ~/ bytesPerMb}MB '
      'maxEntries=${imageCache.maximumSize}',
    );
  }
}
