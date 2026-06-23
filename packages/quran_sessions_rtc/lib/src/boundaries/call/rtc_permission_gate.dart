import 'package:permission_handler/permission_handler.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Requests mic (and optional camera) before joining an RTC channel.
class RtcPermissionGate {
  const RtcPermissionGate();

  Future<void> ensureGranted({required bool needsCamera}) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw const RtcPermissionDeniedFailure(permission: 'microphone');
    }
    if (!needsCamera) {
      return;
    }
    final camera = await Permission.camera.request();
    if (!camera.isGranted) {
      throw const RtcPermissionDeniedFailure(permission: 'camera');
    }
  }
}
