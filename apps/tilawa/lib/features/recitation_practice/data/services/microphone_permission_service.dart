import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/recitation_practice/core/voice_recitation_log.dart';

/// Handles microphone permission for recitation practice.
@lazySingleton
class MicrophonePermissionService {
  MicrophonePermissionService(this._prefs);

  static const String _permissionRequestedKey =
      'microphone_permission_requested';

  final SharedPreferencesAsync _prefs;

  Future<bool> isPermissionGranted() async {
    if (!_isMobilePlatform) {
      return false;
    }
    final PermissionStatus status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    if (!_isMobilePlatform) {
      return false;
    }

    try {
      final PermissionStatus currentStatus = await Permission.microphone.status;
      if (currentStatus.isGranted) {
        await _prefs.setBool(_permissionRequestedKey, true);
        return true;
      }

      if (currentStatus.isPermanentlyDenied) {
        await _prefs.setBool(_permissionRequestedKey, true);
        return false;
      }

      final PermissionStatus status = await Permission.microphone.request();
      await _prefs.setBool(_permissionRequestedKey, true);
      VoiceRecitationLog.d('microphone permission status=$status');
      return status.isGranted;
    } catch (error) {
      VoiceRecitationLog.w('microphone permission error=$error');
      await _prefs.setBool(_permissionRequestedKey, true);
      return false;
    }
  }
}

bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;
