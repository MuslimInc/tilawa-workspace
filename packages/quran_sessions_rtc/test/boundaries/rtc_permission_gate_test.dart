import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RtcPermissionGate', () {
    late _FakePermissionPlatform platform;

    setUp(() {
      platform = _FakePermissionPlatform();
      PermissionHandlerPlatform.instance = platform;
    });

    test('voice join requires microphone only', () async {
      const gate = RtcPermissionGate();

      await gate.ensureGranted(needsCamera: false);

      check(platform.requested).deepEquals([Permission.microphone]);
    });

    test('video join requires microphone and camera', () async {
      const gate = RtcPermissionGate();

      await gate.ensureGranted(needsCamera: true);

      check(
        platform.requested,
      ).deepEquals([Permission.microphone, Permission.camera]);
    });

    test('denied microphone throws RtcPermissionDeniedFailure', () async {
      platform.grantMicrophone = false;
      const gate = RtcPermissionGate();

      await expectLater(
        gate.ensureGranted(needsCamera: false),
        throwsA(
          isA<RtcPermissionDeniedFailure>().having(
            (e) => e.permission,
            'permission',
            'microphone',
          ),
        ),
      );
    });

    test('denied camera throws RtcPermissionDeniedFailure', () async {
      platform.grantCamera = false;
      const gate = RtcPermissionGate();

      await expectLater(
        gate.ensureGranted(needsCamera: true),
        throwsA(
          isA<RtcPermissionDeniedFailure>().having(
            (e) => e.permission,
            'permission',
            'camera',
          ),
        ),
      );
    });
  });
}

class _FakePermissionPlatform extends PermissionHandlerPlatform {
  final List<Permission> requested = <Permission>[];
  bool grantMicrophone = true;
  bool grantCamera = true;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    requested.addAll(permissions);
    return {
      for (final permission in permissions) permission: _statusFor(permission),
    };
  }

  PermissionStatus _statusFor(Permission permission) {
    if (permission == Permission.microphone && !grantMicrophone) {
      return PermissionStatus.denied;
    }
    if (permission == Permission.camera && !grantCamera) {
      return PermissionStatus.denied;
    }
    return PermissionStatus.granted;
  }
}
