import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_image_flutter/quran_image_app.dart';

import 'verse_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Full-screen immersive mode (hides status bar and navigation bar)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize with debug mode and preloading
  await verseService.init(forceDebugSource: true, preloadAllPages: true);

  runApp(const QuranImageApp());
}
