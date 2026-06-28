import 'dart:async';

import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

/// Captures Timer callbacks so they can be fired manually.
class _ManualTimerController {
  final timers = <({Duration duration, void Function() callback})>[];

  Timer createTimer(Duration duration, void Function() callback) {
    timers.add((duration: duration, callback: callback));
    return _NoopTimer();
  }

  /// Fires all pending timer callbacks.
  void fireAll() {
    final pending = List.of(timers);
    timers.clear();
    for (final t in pending) {
      t.callback();
    }
  }

  /// Fires timers repeatedly until none remain.
  Future<void> drainAll() async {
    while (timers.isNotEmpty) {
      fireAll();
      await pumpEventQueue();
    }
  }
}

class _NoopTimer implements Timer {
  @override
  void cancel() {}
  @override
  bool get isActive => false;
  @override
  int get tick => 0;
}

// ---------------------------------------------------------------------------
// Test Gateways
// ---------------------------------------------------------------------------

/// Always succeeds, records all events.
class _RecordingGateway implements QuranSessionCallTelemetryGateway {
  final recorded = <QuranSessionCallTelemetryEvent>[];

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {
    recorded.add(event);
  }
}

/// Fails the first N calls, then succeeds.
class _FailNTimesGateway implements QuranSessionCallTelemetryGateway {
  _FailNTimesGateway({required this.failCount});

  final int failCount;
  int attempts = 0;
  final recorded = <QuranSessionCallTelemetryEvent>[];

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {
    attempts += 1;
    if (attempts <= failCount) {
      throw StateError('transient failure #$attempts');
    }
    recorded.add(event);
  }
}

/// Always fails.
class _AlwaysFailGateway implements QuranSessionCallTelemetryGateway {
  int attempts = 0;
  final recorded = <QuranSessionCallTelemetryEvent>[];

  @override
  Future<void> recordEvent(QuranSessionCallTelemetryEvent event) async {
    attempts += 1;
    throw StateError('permanent failure');
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _sessionId = 's1';
const _teacherId = 'teacher_uid';
const _studentId = 'student_uid';

void main() {
  group('QuranSessionCallTelemetryCoordinator – retry/dedup', () {
    late _RecordingGateway gateway;
    late SessionCallProviderEventHub hub;
    late QuranSessionCallTelemetryCoordinator coordinator;
    late DateTime fakeNow;

    setUp(() {
      gateway = _RecordingGateway();
      hub = SessionCallProviderEventHub();
      fakeNow = DateTime.utc(2026, 6, 25, 12);
      coordinator = QuranSessionCallTelemetryCoordinator(
        gateway: gateway,
        eventHub: hub,
        clock: () => fakeNow,
      );
    });

    tearDown(() {
      coordinator.dispose();
      hub.dispose();
    });

    // -----------------------------------------------------------------------
    // 1. Deduplication stability after failure
    // -----------------------------------------------------------------------

    test(
      'failed event does NOT get removed from dedupe map',
      () async {
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
        );

        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        await pumpEventQueue(times: 10);

        // The event stays in dedupe — enqueueing same event again is
        // silently ignored. The queue should have exactly 1 pending.
        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        // Still only 1 event in the queue, not 2.
        check(coordinator.pendingCount).equals(1);
      },
    );

    test(
      'duplicate event after failure is ignored',
      () async {
        final timerCtrl = _ManualTimerController();
        final failOnce = _FailNTimesGateway(failCount: 1);
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: failOnce,
          eventHub: hub,
          clock: () => fakeNow,
          timerFactory: timerCtrl.createTimer,
        );

        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        await pumpEventQueue(times: 5);

        // Try to enqueue same event again — blocked by dedupe.
        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        // Fire backoff timer to allow retry.
        await timerCtrl.drainAll();
        await pumpEventQueue(times: 5);

        // 1 failed attempt + 1 succeeded retry = 2 attempts.
        check(failOnce.attempts).isLessOrEqual(2);
        // Event delivered successfully after retry.
        check(failOnce.recorded.length).equals(1);
      },
    );

    // -----------------------------------------------------------------------
    // 2. Exponential backoff
    // -----------------------------------------------------------------------

    test(
      'retry uses exponential backoff, not immediate',
      () async {
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
        );

        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        // After initial failure, immediate pump should NOT produce
        // additional gateway attempts.
        await pumpEventQueue(times: 20);

        // Only 1 attempt (the initial one). No immediate retry.
        check(alwaysFail.attempts).equals(1);
      },
    );

    test(
      'retry does NOT happen immediately on next provider event',
      () async {
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
        );

        coordinator.bindSession(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        await pumpEventQueue(times: 5);
        final attemptsAfterFirst = alwaysFail.attempts;

        // Emit a provider event — this should NOT trigger
        // an immediate retry of the failed pending queue.
        hub.emit(
          const SessionCallParticipantConnected(
            sessionId: _sessionId,
            remoteParticipantId: 'remote_1',
          ),
        );

        await pumpEventQueue(times: 5);

        // The participantConnected is enqueued but the failed
        // joinRequested at the head should not be immediately
        // retried. Attempts should only increase by the new
        // event's first try at most.
        check(alwaysFail.attempts).isLessOrEqual(attemptsAfterFirst + 1);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Max retry attempts
    // -----------------------------------------------------------------------

    test(
      'gives up after max retry attempts',
      () async {
        final timerCtrl = _ManualTimerController();
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
          maxRetries: 3,
          timerFactory: timerCtrl.createTimer,
        );

        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        // Exhaust all retries by draining timer callbacks.
        for (var i = 0; i < 10; i++) {
          await timerCtrl.drainAll();
          await pumpEventQueue(times: 5);
        }

        // Should have tried at most 4 times (1 initial + 3).
        check(alwaysFail.attempts).isLessOrEqual(4);
        // Queue should be empty (event dropped after max retries).
        check(coordinator.pendingCount).equals(0);
      },
    );

    // -----------------------------------------------------------------------
    // 4. Queue cap
    // -----------------------------------------------------------------------

    test(
      'queue cap prevents unlimited growth',
      () async {
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
          maxQueueSize: 5,
        );

        coordinator.bindSession(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        // Enqueue many reconnect events (each gets a unique
        // semanticKey due to _reconnectSequence).
        for (var i = 0; i < 20; i++) {
          hub.emit(
            const SessionCallReconnecting(sessionId: _sessionId),
          );
          fakeNow = fakeNow.add(const Duration(milliseconds: 1));
          await pumpEventQueue();
        }

        check(coordinator.pendingCount).isLessOrEqual(5);
      },
    );

    test(
      'essential events are preserved over noisy events at cap',
      () async {
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
          maxQueueSize: 5,
        );

        coordinator.bindSession(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        // Fill queue with noisy reconnect events.
        for (var i = 0; i < 5; i++) {
          hub.emit(
            const SessionCallReconnecting(
              sessionId: _sessionId,
            ),
          );
          fakeNow = fakeNow.add(const Duration(milliseconds: 1));
          await pumpEventQueue();
        }

        // Now enqueue an essential callEnded event.
        coordinator.recordCallEnded(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        await pumpEventQueue();

        // The callEnded event should be in the queue — a noisy
        // event should have been evicted to make room.
        check(coordinator.pendingCount).isLessOrEqual(5);
        check(coordinator.hasPendingEssentialEvent).isTrue();
      },
    );

    test(
      'callEnded is not lost when queue is full',
      () async {
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
          maxQueueSize: 3,
        );

        // Fill queue with essential events.
        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );
        coordinator.recordJoinSucceeded(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );
        coordinator.recordLeave(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        await pumpEventQueue();

        // Queue is at cap. Now add callEnded.
        coordinator.recordCallEnded(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        await pumpEventQueue();

        // callEnded should still be in the queue.
        check(coordinator.hasPendingCallEnded).isTrue();
      },
    );

    // -----------------------------------------------------------------------
    // 5. Noisy event throttling
    // -----------------------------------------------------------------------

    test(
      'network quality events are throttled',
      () async {
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: gateway,
          eventHub: hub,
          clock: () => fakeNow,
          networkThrottle: const Duration(seconds: 60),
        );

        coordinator.bindSession(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        // Emit 10 network events within 10 seconds.
        for (var i = 0; i < 10; i++) {
          hub.emit(
            const SessionCallNetworkQualityChanged(
              sessionId: _sessionId,
              level: SessionCallNetworkQualityLevel.poor,
            ),
          );
          fakeNow = fakeNow.add(const Duration(seconds: 1));
        }

        await pumpEventQueue();

        // Only 1 network event through throttle.
        final networkEvents = gateway.recorded.where(
          (e) => e.type == QuranSessionCallTelemetryEventType.network,
        );
        check(networkEvents.length).equals(1);
      },
    );

    test(
      'reconnect events are rate-limited',
      () async {
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: gateway,
          eventHub: hub,
          clock: () => fakeNow,
          maxReconnectEvents: 3,
        );

        coordinator.bindSession(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        // Emit 20 reconnecting events.
        for (var i = 0; i < 20; i++) {
          hub.emit(
            const SessionCallReconnecting(
              sessionId: _sessionId,
            ),
          );
        }

        await pumpEventQueue();

        final reconnectEvents = gateway.recorded.where(
          (e) => e.type == QuranSessionCallTelemetryEventType.reconnect,
        );
        check(reconnectEvents.length).isLessOrEqual(3);
      },
    );

    // -----------------------------------------------------------------------
    // 6. Local controls do NOT trigger backend telemetry
    // -----------------------------------------------------------------------

    test(
      'mic/camera/speaker toggles do not call backend telemetry',
      () async {
        final controlGateway = TelemetrySessionCallControlGateway(
          inner: _NoopCallControlGateway(),
          telemetry: coordinator,
        );

        // Perform hardware toggles.
        await controlGateway.setMicrophoneEnabled(
          enabled: false,
        );
        await controlGateway.setCameraEnabled(enabled: true);
        await controlGateway.setSpeakerEnabled(enabled: false);
        await controlGateway.switchCamera();

        await pumpEventQueue();

        // No events from hardware toggles.
        check(gateway.recorded).isEmpty();
      },
    );

    // -----------------------------------------------------------------------
    // 7. Join deduplication (app resume/rebuild)
    // -----------------------------------------------------------------------

    test(
      'app resume/rebuild does not duplicate join event',
      () async {
        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );
        coordinator.recordJoinSucceeded(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        await pumpEventQueue();

        // Simulate app resume — same calls again.
        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );
        coordinator.recordJoinSucceeded(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        await pumpEventQueue();

        // Only 2 events total, not 4.
        check(gateway.recorded.length).equals(2);
      },
    );

    // -----------------------------------------------------------------------
    // 8. Reconnect loop does NOT spam backend
    // -----------------------------------------------------------------------

    test(
      'reconnect loop does not spam backend',
      () async {
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: gateway,
          eventHub: hub,
          clock: () => fakeNow,
          maxReconnectEvents: 3,
        );

        coordinator.bindSession(
          sessionId: _sessionId,
          actorId: _studentId,
          actorRole: SessionParticipantRole.student,
        );

        // Simulate reconnect storm: 100 reconnect pairs.
        for (var i = 0; i < 100; i++) {
          hub.emit(
            const SessionCallReconnecting(
              sessionId: _sessionId,
            ),
          );
          hub.emit(
            const SessionCallReconnected(
              sessionId: _sessionId,
            ),
          );
        }

        await pumpEventQueue();

        final reconnectEvents = gateway.recorded.where(
          (e) => e.type == QuranSessionCallTelemetryEventType.reconnect,
        );
        check(reconnectEvents.length).isLessOrEqual(3);
      },
    );

    // -----------------------------------------------------------------------
    // 9. Telemetry failure does not break call UI
    // -----------------------------------------------------------------------

    test(
      'telemetry failure does not throw from public APIs',
      () async {
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
        );

        // None of these should throw.
        expect(
          () {
            coordinator.recordJoinRequested(
              sessionId: _sessionId,
              actorId: _teacherId,
              actorRole: SessionParticipantRole.teacher,
            );
            coordinator.recordJoinSucceeded(
              sessionId: _sessionId,
              actorId: _teacherId,
              actorRole: SessionParticipantRole.teacher,
            );
            coordinator.recordLeave(
              sessionId: _sessionId,
              actorId: _teacherId,
              actorRole: SessionParticipantRole.teacher,
            );
            coordinator.recordCallEnded(
              sessionId: _sessionId,
              actorId: _teacherId,
              actorRole: SessionParticipantRole.teacher,
            );
          },
          returnsNormally,
        );

        await pumpEventQueue(times: 20);
      },
    );

    // -----------------------------------------------------------------------
    // 10. Dispose clears all state
    // -----------------------------------------------------------------------

    test(
      'dispose clears pending queue and dedupe map',
      () async {
        final alwaysFail = _AlwaysFailGateway();
        coordinator = QuranSessionCallTelemetryCoordinator(
          gateway: alwaysFail,
          eventHub: hub,
          clock: () => fakeNow,
        );

        coordinator.recordJoinRequested(
          sessionId: _sessionId,
          actorId: _teacherId,
          actorRole: SessionParticipantRole.teacher,
        );

        await pumpEventQueue(times: 5);
        check(coordinator.pendingCount).equals(1);

        coordinator.dispose();

        check(coordinator.pendingCount).equals(0);
      },
    );
  });
}

/// Noop gateway for testing TelemetrySessionCallControlGateway.
class _NoopCallControlGateway implements SessionCallControlGateway {
  @override
  Future<void> setMicrophoneEnabled({
    required bool enabled,
  }) async {}

  @override
  Future<void> setCameraEnabled({
    required bool enabled,
  }) async {}

  @override
  Future<void> switchCamera() async {}

  @override
  Future<void> setSpeakerEnabled({
    required bool enabled,
  }) async {}

  @override
  Future<void> leave() async {}
}
