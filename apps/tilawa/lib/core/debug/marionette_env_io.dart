import 'dart:io' show Platform;

/// True when running under `flutter test` (host VM sets `FLUTTER_TEST`).
bool get isFlutterTestEnv => Platform.environment.containsKey('FLUTTER_TEST');
