import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stable per-install device identity (Firebase Installations ID).
abstract class DeviceIdentityService {
  Future<String> getDeviceId();

  String get platform;
}

@LazySingleton(as: DeviceIdentityService)
class DeviceIdentityServiceImpl implements DeviceIdentityService {
  DeviceIdentityServiceImpl(this._prefs);

  /// Persists a generated id when [firebase_app_installations] is unavailable.
  ///
  /// After adding `firebase_app_installations`, stop the app and run a full
  /// native rebuild (`flutter run` / Xcode / Gradle) — hot restart is not
  /// enough to register the platform channel.
  static const String _localDeviceIdPrefsKey = 'tilawa_local_device_id';

  static const MethodChannel _installationsChannel = MethodChannel(
    'plugins.flutter.io/firebase_app_installations',
  );

  final SharedPreferencesAsync _prefs;
  String? _cachedDeviceId;

  @override
  Future<String> getDeviceId() async {
    final cached = _cachedDeviceId;
    if (cached != null) {
      return cached;
    }

    final firebaseId = await _tryGetFirebaseInstallationId();
    if (firebaseId != null && firebaseId.isNotEmpty) {
      _cachedDeviceId = firebaseId;
      return firebaseId;
    }

    final localId = await _getOrCreateLocalDeviceId();
    _cachedDeviceId = localId;
    return localId;
  }

  Future<String?> _tryGetFirebaseInstallationId() async {
    try {
      final appName = _firebaseAppName();
      return await _installationsChannel.invokeMethod<String>(
        'FirebaseInstallations#getId',
        <String, Object?>{'appName': appName},
      );
    } on MissingPluginException catch (error, stackTrace) {
      developer.log(
        'Firebase Installations unavailable; using local device id fallback. '
        'Run a full rebuild after adding firebase_app_installations.',
        name: 'DeviceIdentityService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } on PlatformException catch (error, stackTrace) {
      developer.log(
        'Firebase Installations getId failed; using local device id fallback.',
        name: 'DeviceIdentityService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _firebaseAppName() {
    try {
      return Firebase.app().name;
    } catch (_) {
      return '[DEFAULT]';
    }
  }

  Future<String> _getOrCreateLocalDeviceId() async {
    final existing = await _prefs.getString(_localDeviceIdPrefsKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateLocalDeviceId();
    await _prefs.setString(_localDeviceIdPrefsKey, generated);
    return generated;
  }

  static String _generateLocalDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'local_$hex';
  }

  @override
  String get platform {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'android';
  }
}
