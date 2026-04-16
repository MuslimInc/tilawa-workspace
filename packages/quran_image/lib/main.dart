import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_image/quran_image_app.dart';

import 'core/di/dependency_injection.dart';
import 'core/perf_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImageCache();
  PerfLogger.startFrameWatcher();

  // Initialize dependency injection container
  await initDependencies();

  runApp(const QuranImageApp());

  // Apply immersive mode after runApp so it does not block the first usable
  // frame. Reader behavior is unchanged; the system UI still transitions away
  // immediately after startup.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
}

void _configureImageCache() {
  const bytesPerMb = 1024 * 1024;
  final imageCache = PaintingBinding.instance.imageCache;

  // The reader keeps nearby pages warm around the current page and may also
  // hold recently previewed slider targets. This is still a bounded LRU cache,
  // not a decoded cache of all 9,060 Quran line images.
  imageCache.maximumSizeBytes = 180 * bytesPerMb;
  imageCache.maximumSize = 300;
}
