import 'dart:async';

import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

class _FlakyGateway implements QuranSessionCallTelemetryGateway {
  _FlakyGateway();

  int attempts = 0;
  final recorded = <QuranSessionCallTelemetryEvent>[];

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {
    attempts += 1;
    if (attempts == 1) {
      throw StateError('transient');
    }
    recorded.add(event);
  }
}

class _RecordingGateway implements QuranSessionCallTelemetryGateway {
  final recorded = <QuranSessionCallTelemetryEvent>[];

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {
    recorded.add(event);
  }
}

void main() {
  group('QuranSessionCallTelemetryCoordinator', () {
    late _RecordingGateway gateway;
    late SessionCallProviderEventHub hub;
    late QuranSessionCallTelemetryCoordinator coordinator;

    setUp(() {
      gateway = _RecordingGateway();
      hub = SessionCallProviderEventHub();
      coordinator = QuranSessionCallTelemetryCoordinator(
        gateway: gateway,
        eventHub: hub,
        clock: () => DateTime.utc(2026, 6, 24, 12),
      );
    });

    tearDown(() {
      coordinator.dispose();
      hub.dispose();
    });

    test('dedupes join events per actor', () {
      coordinator.recordJoinRequested(
        sessionId: 's1',
        actorId: 'teacher',
        actorRole: SessionParticipantRole.teacher,
      );
      coordinator.recordJoinRequested(
        sessionId: 's1',
        actorId: 'teacher',
        actorRole: SessionParticipantRole.teacher,
      );

      check(gateway.recorded.length).equals(1);
      check(
        gateway.recorded.single.type,
      ).equals(QuranSessionCallTelemetryEventType.joinRequested);
    });

    test('teacher first join then student second join', () async {
      coordinator.recordJoinSucceeded(
        sessionId: 's1',
        actorId: 'teacher_uid',
        actorRole: SessionParticipantRole.teacher,
      );
      coordinator.recordJoinSucceeded(
        sessionId: 's1',
        actorId: 'student_uid',
        actorRole: SessionParticipantRole.student,
      );

      await pumpEventQueue();

      check(gateway.recorded.length).equals(2);
      check(
        gateway.recorded.first.actorRole,
      ).equals(SessionParticipantRole.teacher);
      check(
        gateway.recorded.last.actorRole,
      ).equals(SessionParticipantRole.student);
    });

    test('maps provider participant connected to telemetry', () async {
      coordinator.bindSession(
        sessionId: 's1',
        actorId: 'student_uid',
        actorRole: SessionParticipantRole.student,
      );
      hub.emit(
        const SessionCallParticipantConnected(
          sessionId: 's1',
          remoteParticipantId: '42',
        ),
      );

      await pumpEventQueue();

      check(gateway.recorded.single.type).equals(
        QuranSessionCallTelemetryEventType.participantConnected,
      );
    });

    test('throttles network telemetry', () async {
      var now = DateTime.utc(2026, 6, 24, 12);
      coordinator = QuranSessionCallTelemetryCoordinator(
        gateway: gateway,
        eventHub: hub,
        clock: () => now,
        networkThrottle: const Duration(seconds: 60),
      );
      coordinator.bindSession(
        sessionId: 's1',
        actorId: 'student_uid',
        actorRole: SessionParticipantRole.student,
      );

      hub.emit(
        const SessionCallNetworkQualityChanged(
          sessionId: 's1',
          level: SessionCallNetworkQualityLevel.good,
        ),
      );
      now = now.add(const Duration(seconds: 10));
      hub.emit(
        const SessionCallNetworkQualityChanged(
          sessionId: 's1',
          level: SessionCallNetworkQualityLevel.poor,
        ),
      );

      await pumpEventQueue();

      check(gateway.recorded.length).equals(1);
    });

    test('reconnect events are idempotent per sequence', () async {
      coordinator.bindSession(
        sessionId: 's1',
        actorId: 'student_uid',
        actorRole: SessionParticipantRole.student,
      );
      hub.emit(const SessionCallReconnecting(sessionId: 's1'));
      hub.emit(const SessionCallReconnecting(sessionId: 's1'));

      await pumpEventQueue();

      check(gateway.recorded.length).equals(2);
      check(
        gateway.recorded.first.eventId == gateway.recorded.last.eventId,
      ).isFalse();
    });

    test('gateway failure does not throw from record APIs', () async {
      final flaky = _FlakyGateway();
      coordinator = QuranSessionCallTelemetryCoordinator(
        gateway: flaky,
        eventHub: hub,
      );

      expect(
        () => coordinator.recordJoinRequested(
          sessionId: 's1',
          actorId: 'student_uid',
          actorRole: SessionParticipantRole.student,
        ),
        returnsNormally,
      );

      await pumpEventQueue(times: 5);
      check(flaky.attempts > 0).isTrue();
    });

    test('recordLeaveForBoundSession uses bind context', () async {
      coordinator.bindSession(
        sessionId: 's1',
        actorId: 'teacher_uid',
        actorRole: SessionParticipantRole.teacher,
      );
      coordinator.recordLeaveForBoundSession();

      await pumpEventQueue();

      check(
        gateway.recorded.single.type,
      ).equals(QuranSessionCallTelemetryEventType.leave);
    });
  });
}
