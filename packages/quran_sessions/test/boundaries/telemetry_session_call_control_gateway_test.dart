import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

class _RecordingGateway implements QuranSessionCallTelemetryGateway {
  final recorded = <QuranSessionCallTelemetryEvent>[];

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {
    recorded.add(event);
  }
}

class _InnerGateway implements SessionCallControlGateway {
  int leaveCount = 0;

  @override
  Future<void> setCameraEnabled({required bool enabled}) async {}

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async {}

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) async {}

  @override
  Future<void> switchCamera() async {}

  @override
  Future<void> leave() async {
    leaveCount += 1;
  }
}

void main() {
  test('leave records telemetry once', () async {
    final gateway = _RecordingGateway();
    final coordinator = QuranSessionCallTelemetryCoordinator(
      gateway: gateway,
    );
    coordinator.bindSession(
      sessionId: 's1',
      actorId: 'student_uid',
      actorRole: SessionParticipantRole.student,
    );
    final inner = _InnerGateway();
    final decorated = TelemetrySessionCallControlGateway(
      inner: inner,
      telemetry: coordinator,
    );

    await decorated.leave();
    await pumpEventQueue();

    check(inner.leaveCount).equals(1);
    check(
      gateway.recorded.single.type,
    ).equals(QuranSessionCallTelemetryEventType.leave);
  });

  test('mic toggle does not record telemetry', () async {
    final gateway = _RecordingGateway();
    final coordinator = QuranSessionCallTelemetryCoordinator(
      gateway: gateway,
    );
    final decorated = TelemetrySessionCallControlGateway(
      inner: _InnerGateway(),
      telemetry: coordinator,
    );

    await decorated.setMicrophoneEnabled(enabled: false);
    await decorated.setSpeakerEnabled(enabled: true);
    await pumpEventQueue();

    check(gateway.recorded).isEmpty();
  });
}
