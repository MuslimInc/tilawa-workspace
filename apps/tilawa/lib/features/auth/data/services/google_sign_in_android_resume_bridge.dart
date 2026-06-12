import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../debug/tilawa_gsignin_debug_log.dart';

/// Notifies Dart when [MainActivity.onResume] fires (Transsion sign-in recovery).
class GoogleSignInAndroidResumeBridge {
  GoogleSignInAndroidResumeBridge._();

  static final GoogleSignInAndroidResumeBridge instance =
      GoogleSignInAndroidResumeBridge._();

  static const MethodChannel _channel = MethodChannel(
    'com.tilawa.app/google_sign_in',
  );

  final StreamController<void> _controller = StreamController<void>.broadcast();
  final StreamController<void> _dismissedController =
      StreamController<void>.broadcast();

  Stream<void> get onMainActivityResumed => _controller.stream;

  /// Fires when Credential Manager [HiddenActivity] stops or is destroyed.
  Stream<void> get onCredentialUiDismissed => _dismissedController.stream;

  bool _initialized = false;

  void ensureInitialized() {
    if (_initialized || !Platform.isAndroid) {
      return;
    }
    _initialized = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onMainActivityResumed') {
        // #region agent log
        tilawaGSignInDebug(
          'native onResume received in Dart',
          hypothesisId: 'H1',
        );
        // #endregion
        _controller.add(null);
      } else if (call.method == 'onCredentialUiDismissed') {
        // #region agent log
        tilawaGSignInDebug(
          'native credential UI dismissed',
          hypothesisId: 'H6',
        );
        // #endregion
        _dismissedController.add(null);
      }
    });
  }
}
