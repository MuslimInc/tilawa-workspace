import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Restores Sentry's Android plugin context after hot restart.
///
/// [SentryFlutterPlugin] clears its static `applicationContext` in
/// `onDetachedFromEngine`, but Flutter hot restart does not re-attach plugins
/// before Dart `main()` runs again. JNI native init then fails with
/// "application context is null".
abstract final class SentryAndroidContext {
  static const MethodChannel _channel = MethodChannel(
    'com.tilawa.app/app_context',
  );

  /// Avoids `dart:io` [Platform], which throws on web.
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Best-effort restore before [SentryFlutter.init] on Android.
  static Future<void> ensurePluginContext() async {
    if (!_isAndroid) {
      return;
    }
    // coverage:ignore-start
    try {
      await _channel.invokeMethod<void>('restoreSentryApplicationContext');
    } on PlatformException {
      // Native SDK may still be unavailable; Dart-layer reporting continues.
    } on MissingPluginException {
      // Non-Android embedder or tests without a platform channel.
    }
    // coverage:ignore-end
  }

  /// Whether the Android native SDK is still active after a Flutter hot restart.
  static Future<bool> isNativeSdkInitialized() async {
    if (!_isAndroid) {
      return false;
    }
    // coverage:ignore-start
    try {
      final bool? initialized = await _channel.invokeMethod<bool>(
        'isSentryNativeSdkInitialized',
      );
      return initialized ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
    // coverage:ignore-end
  }
}
