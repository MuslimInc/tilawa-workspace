import 'package:flutter/services.dart';

/// Centralized service for managing device orientation across the Tilawa app.
class AppOrientationService {
  /// Default orientations for the general app (Portrait Up only).
  static const List<DeviceOrientation> _defaultOrientations = [
    DeviceOrientation.portraitUp,
  ];

  /// Full rotation orientations for the Quran Reader.
  static const List<DeviceOrientation> _readerOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  /// Applies the default app orientations (Portrait Up only).
  static Future<void> applyDefaultOrientations() async {
    await SystemChrome.setPreferredOrientations(_defaultOrientations);
  }

  /// Allows all orientations for the Quran Reader.
  static Future<void> allowReaderOrientations() async {
    await SystemChrome.setPreferredOrientations(_readerOrientations);
  }

  /// Restores the app to default orientations.
  static Future<void> restoreDefaultOrientations() async {
    await applyDefaultOrientations();
  }

  /// Exposes the default orientations for pass-through components.
  static List<DeviceOrientation> get defaultOrientations =>
      _defaultOrientations;

  /// Exposes the reader orientations for pass-through components.
  static List<DeviceOrientation> get readerOrientations => _readerOrientations;
}
