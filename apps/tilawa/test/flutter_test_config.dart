import 'dart:async';

import 'package:visibility_detector/visibility_detector.dart';

/// Global test bootstrap for the Tilawa app test suite.
///
/// Forces [VisibilityDetector] to report synchronously after layout so its
/// debounce timer never stays pending when a widget test that renders a
/// visibility-tracked widget completes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  await testMain();
}
