import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('SessionCallControlGatewayAdapter', () {
    late _RecordingCallProvider provider;
    late SessionCallControlGateway gateway;

    setUp(() {
      provider = _RecordingCallProvider();
      gateway = SessionCallControlGatewayAdapter(
        provider: provider,
        sessionId: 'session_1',
      );
    });

    test('forwards microphone enable to provider', () async {
      await gateway.setMicrophoneEnabled(enabled: false);

      check(provider.lastMicrophoneEnabled).equals(false);
      check(provider.lastSessionId).equals('session_1');
    });

    test('forwards camera enable to provider', () async {
      await gateway.setCameraEnabled(enabled: true);

      check(provider.lastCameraEnabled).equals(true);
    });

    test('forwards switch camera to provider', () async {
      await gateway.switchCamera();

      check(provider.switchCameraCount).equals(1);
    });

    test('forwards speaker enable to provider', () async {
      await gateway.setSpeakerEnabled(enabled: true);

      check(provider.lastSpeakerEnabled).equals(true);
    });

    test('leave delegates to provider leaveSession', () async {
      await gateway.leave();

      check(provider.leaveCount).equals(1);
      check(provider.lastSessionId).equals('session_1');
    });
  });
}

class _RecordingCallProvider implements SessionCallProvider {
  String? lastSessionId;
  bool? lastMicrophoneEnabled;
  bool? lastCameraEnabled;
  bool? lastSpeakerEnabled;
  int switchCameraCount = 0;
  int leaveCount = 0;

  @override
  Future<CallRoom> join(CallJoinRequest request) async =>
      CallRoom(sessionId: request.sessionId);

  @override
  Future<void> leaveSession(String sessionId) async {
    leaveCount++;
    lastSessionId = sessionId;
  }

  @override
  Future<void> endSession(String sessionId) async {}

  @override
  Future<void> setMicrophoneMuted(
    String sessionId, {
    required bool muted,
  }) async {}

  @override
  Future<void> setMicrophoneEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    lastSessionId = sessionId;
    lastMicrophoneEnabled = enabled;
  }

  @override
  Future<void> setCameraEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    lastSessionId = sessionId;
    lastCameraEnabled = enabled;
  }

  @override
  Future<void> switchCamera(String sessionId) async {
    lastSessionId = sessionId;
    switchCameraCount++;
  }

  @override
  Future<void> setSpeakerEnabled(
    String sessionId, {
    required bool enabled,
  }) async {
    lastSessionId = sessionId;
    lastSpeakerEnabled = enabled;
  }
}
