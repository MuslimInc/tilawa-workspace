import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_image_flutter/quran_image_app.dart';

import 'core/di/dependency_injection.dart';
import 'data/repositories/asset_verse_marker_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Full-screen immersive mode (hides status bar and navigation bar)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize dependency injection container
  await initDependencies();

  // Initialize with debug mode and preloading
  await sl<AssetVerseMarkerRepository>().init(
    forceDebugSource: true,
    preloadAllPages: true,
  );

  runApp(const QuranImageApp());
}
