import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_image_flutter/quran_image_app.dart';

import 'core/di/dependency_injection.dart';
import 'core/perf_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImageCache();
  PerfLogger.startFrameWatcher();

  // Full-screen immersive mode (hides status bar and navigation bar)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize dependency injection container
  await initDependencies();

  runApp(const QuranImageApp());
}

void _configureImageCache() {
  const bytesPerMb = 1024 * 1024;
  final imageCache = PaintingBinding.instance.imageCache;

  // The reader keeps several page-line images warm ahead of the current page.
  // The default 100 MB cache is too small for that working set at ~3x DPR,
  // which causes evictions and repeated texture uploads during swipes.
  imageCache.maximumSizeBytes = 192 * bytesPerMb;
  imageCache.maximumSize = 200;
}
