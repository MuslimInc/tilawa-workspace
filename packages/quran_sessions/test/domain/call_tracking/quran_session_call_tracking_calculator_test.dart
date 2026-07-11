import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

/// Deterministic scheduled start. No reliance on the wall clock anywhere.
final DateTime scheduled = DateTime.utc(2026, 6, 24, 12);

DateTime at(Duration offset) => scheduled.add(offset);

CallTrackingEvent ev(
  SessionParticipantRole role,
  CallTrackingEventType type,
  Duration offset, {
  String? id,
}) {
  return CallTrackingEvent(
    eventId: id ?? '${role.name}_${type.name}_${offset.inMilliseconds}',
    role: role,
    type: type,
    occurredAt: at(offset),
  );
}

const SessionParticipantRole teacher = SessionParticipantRole.teacher;
const SessionParticipantRole student = SessionParticipantRole.student;

const calculator = QuranSessionCallTrackingCalculator();

QuranSessionCallMetrics compute(
  List<CallTrackingEvent> events, {
  DateTime? evaluatedAt,
  QuranSessionCallTrackingCalculator engine = calculator,
}) {
  final result = engine.calculate(
    events: events,
    scheduledStartAt: scheduled,
    evaluatedAt: evaluatedAt ?? at(const Duration(hours: 1)),
  );
  return result.getOrElse(() => throw StateError('expected Right'));
}

void main() {
  group('Call start rule', () {
    test('1. teacher joins first — recorded as first join', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 1)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 2)),
      ]);
      check(m.firstJoinRole).equals(teacher);
      check(m.secondJoinRole).equals(student);
    });

    test('2. student joins first — recorded as first join', () {
      final m = compute([
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 1)),
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 2)),
      ]);
      check(m.firstJoinRole).equals(student);
      check(m.secondJoinRole).equals(teacher);
    });

    test('3. only teacher joins — call does not start', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 1)),
      ]);
      check(m.callStarted).isFalse();
      check(m.actualCallStartedAt).isNull();
      check(m.status).equals(QuranSessionCallStatus.waitingForParticipant);
      check(m.teacherStatus).equals(CallParticipantStatus.waiting);
    });

    test('4. only student joins — call does not start', () {
      final m = compute([
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 1)),
      ]);
      check(m.callStarted).isFalse();
      check(m.bothParticipantsConnectedSeconds).equals(0);
    });

    test('5. student joins after teacher — call starts on student join', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 3)),
      ]);
      check(m.callStarted).isTrue();
      check(m.actualCallStartedAt).equals(at(const Duration(minutes: 3)));
    });

    test('6. teacher joins after student — call starts on teacher join', () {
      final m = compute([
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 4)),
      ]);
      check(m.callStarted).isTrue();
      check(m.actualCallStartedAt).equals(at(const Duration(minutes: 4)));
    });
  });

  group('Duration rule', () {
    test('7. waiting time is excluded from call duration', () {
      // Teacher waits 2 min, both connected for 10 min.
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 2)),
        ev(teacher, CallTrackingEventType.left, const Duration(minutes: 12)),
      ]);
      check(m.bothParticipantsConnectedSeconds).equals(10 * 60);
      check(m.waitingSeconds).equals(2 * 60);
    });

    test('8. both-connected time computed across an interruption', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 0)),
        // both connected 0..5
        ev(
          teacher,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 5),
        ),
        // teacher gone 5..7
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 7)),
        // both connected again 7..15
        ev(teacher, CallTrackingEventType.left, const Duration(minutes: 15)),
      ]);
      check(m.bothParticipantsConnectedSeconds).equals((5 + 8) * 60);
    });
  });

  group('Late rule', () {
    test('9. teacher late after grace period', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 6)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 6)),
      ]);
      check(m.teacherLate).equals(true);
    });

    test('10. student late after grace period', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 1)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 10)),
      ]);
      check(m.studentLate).equals(true);
      check(m.teacherLate).equals(false);
    });

    test('11. both on time (within grace)', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 4)),
        ev(
          student,
          CallTrackingEventType.joined,
          const Duration(minutes: 4, seconds: 30),
        ),
      ]);
      check(m.teacherLate).equals(false);
      check(m.studentLate).equals(false);
    });

    test('12. both late', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 7)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 8)),
      ]);
      check(m.teacherLate).equals(true);
      check(m.studentLate).equals(true);
    });
  });

  group('No-show rule', () {
    test('13. teacher no-show (never joins, window expired)', () {
      final m = compute(
        [ev(student, CallTrackingEventType.joined, const Duration(minutes: 1))],
        evaluatedAt: at(const Duration(minutes: 20)),
      );
      check(m.teacherNoShow).isTrue();
      check(m.studentNoShow).isFalse();
      check(m.teacherStatus).equals(CallParticipantStatus.noShow);
    });

    test('14. student no-show', () {
      final m = compute(
        [ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 1))],
        evaluatedAt: at(const Duration(minutes: 20)),
      );
      check(m.studentNoShow).isTrue();
    });

    test('15. both no-show', () {
      final m = compute(
        const <CallTrackingEvent>[],
        evaluatedAt: at(const Duration(minutes: 20)),
      );
      check(m.teacherNoShow).isTrue();
      check(m.studentNoShow).isTrue();
    });

    test('no-show is pending (false) before the window expires', () {
      final m = compute(
        const <CallTrackingEvent>[],
        evaluatedAt: at(const Duration(minutes: 5)),
      );
      check(m.teacherNoShow).isFalse();
      check(m.studentNoShow).isFalse();
    });
  });

  group('Reconnect rule', () {
    test('16. first join is not a reconnect', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 1)),
      ]);
      check(m.teacherReconnectCount).equals(0);
    });

    test('17. leave then join again counts as a reconnect', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 1)),
        ev(
          teacher,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 2),
        ),
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 3)),
      ]);
      check(m.teacherReconnectCount).equals(1);
    });

    test('18. multiple reconnects are counted', () {
      final m = compute([
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 1)),
        ev(
          student,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 2),
        ),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 3)),
        ev(
          student,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 4),
        ),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 5)),
      ]);
      check(m.studentReconnectCount).equals(2);
      check(m.reconnectCount).equals(2);
    });
  });

  group('Interruption rule', () {
    test('19. interruption counted only after both were connected', () {
      // Teacher drops/rejoins while alone (before student) -> reconnect, no interruption.
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(
          teacher,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 1),
        ),
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 2)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 3)),
      ]);
      check(m.teacherReconnectCount).equals(1);
      check(m.interruptionCount).equals(0);
    });

    test('interruption is counted after the call started', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(
          teacher,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 5),
        ),
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 6)),
      ]);
      check(m.interruptionCount).equals(1);
      check(m.teacherReconnectCount).equals(1);
    });
  });

  group('Idempotency rule', () {
    test('20. duplicate join event is idempotent', () {
      final dup = ev(
        teacher,
        CallTrackingEventType.joined,
        const Duration(minutes: 1),
        id: 'fixed',
      );
      final m = compute([
        dup,
        dup,
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 1)),
        ev(teacher, CallTrackingEventType.left, const Duration(minutes: 11)),
      ]);
      check(m.teacherReconnectCount).equals(0);
      check(m.bothParticipantsConnectedSeconds).equals(10 * 60);
    });

    test('21. duplicate leave event is idempotent', () {
      final dupLeave = ev(
        teacher,
        CallTrackingEventType.disconnected,
        const Duration(minutes: 5),
        id: 'leave',
      );
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 0)),
        dupLeave,
        dupLeave,
      ]);
      check(m.bothParticipantsConnectedSeconds).equals(5 * 60);
    });

    test('22. out-of-order events are handled safely (sorted by time)', () {
      final inOrder = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 2)),
        ev(teacher, CallTrackingEventType.left, const Duration(minutes: 12)),
      ]);
      final shuffled = compute([
        ev(teacher, CallTrackingEventType.left, const Duration(minutes: 12)),
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 2)),
      ]);
      check(shuffled).equals(inOrder);
    });
  });

  group('Robustness', () {
    test('23. negative duration is impossible (clamped to zero)', () {
      // Leave recorded *before* the join (corrupt order) -> never negative.
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 5)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 5)),
        ev(
          teacher,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 4),
        ),
      ]);
      check(m.bothParticipantsConnectedSeconds).isGreaterOrEqual(0);
      check(m.waitingSeconds).isGreaterOrEqual(0);
    });

    test('24. missing timestamp returns a typed failure', () {
      final result = CallTrackingEvent.parse(
        eventId: 'e',
        role: 'teacher',
        type: 'joined',
        timestampMs: null,
      );
      check(result.isLeft()).isTrue();
      result.fold(
        (f) => check(f).isA<MissingTimestampFailure>(),
        (_) => throw StateError('expected Left'),
      );
    });

    test('25. invalid participant role returns a typed failure', () {
      final result = CallTrackingEvent.parse(
        eventId: 'e',
        role: 'observer',
        type: 'joined',
        timestampMs: scheduled.millisecondsSinceEpoch,
      );
      check(result.isLeft()).isTrue();
      result.fold(
        (f) => check(f).isA<InvalidParticipantRoleFailure>(),
        (_) => throw StateError('expected Left'),
      );
    });

    test('invalid event type returns a typed failure', () {
      final result = CallTrackingEvent.parse(
        eventId: 'e',
        role: 'teacher',
        type: 'exploded',
        timestampMs: scheduled.millisecondsSinceEpoch,
      );
      result.fold(
        (f) => check(f).isA<InvalidEventTypeFailure>(),
        (_) => throw StateError('expected Left'),
      );
    });

    test('parse succeeds and derives a fallback id when blank', () {
      final result = CallTrackingEvent.parse(
        eventId: '  ',
        role: 'student',
        type: 'joined',
        timestampMs: scheduled.millisecondsSinceEpoch,
      );
      final event = result.getOrElse(() => throw StateError('expected Right'));
      check(event.role).equals(student);
      check(event.type).equals(CallTrackingEventType.joined);
      check(event.eventId).isNotEmpty();
    });

    test('26. final metrics are stable after repeated calculation', () {
      final events = [
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 1)),
        ev(
          teacher,
          CallTrackingEventType.callEnded,
          const Duration(minutes: 11),
        ),
      ];
      final first = compute(events);
      final second = compute(events);
      check(first).equals(second);
    });
  });

  group('Configurable policies', () {
    test('27. grace-period policy can be changed', () {
      const strict = QuranSessionCallTrackingCalculator(
        policy: CallTrackingPolicy(
          late: CallLatePolicy(gracePeriod: Duration(minutes: 1)),
        ),
      );
      final m = compute(
        [ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 2))],
        engine: strict,
      );
      check(m.teacherLate).equals(true); // would be on-time under default 5 min
    });

    test('28. no-show policy can be changed', () {
      const tight = QuranSessionCallTrackingCalculator(
        policy: CallTrackingPolicy(
          noShow: CallNoShowPolicy(noShowWindow: Duration(minutes: 5)),
        ),
      );
      final m = compute(
        const <CallTrackingEvent>[],
        evaluatedAt: at(const Duration(minutes: 6)),
        engine: tight,
      );
      check(m.teacherNoShow).isTrue(); // default 15-min window would be pending
    });
  });

  group('Call end', () {
    test('29. call ended before both connected is handled', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 1)),
        ev(
          teacher,
          CallTrackingEventType.callEnded,
          const Duration(minutes: 8),
        ),
      ]);
      check(m.callStarted).isFalse();
      check(m.bothParticipantsConnectedSeconds).equals(0);
      check(m.status).equals(QuranSessionCallStatus.ended);
      check(m.callEndedAt).equals(at(const Duration(minutes: 8)));
      // Teacher was alone -> waiting time runs until the call ended.
      check(m.waitingSeconds).equals(7 * 60);
    });

    test('30. call ended after both connected computes final duration', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(
          teacher,
          CallTrackingEventType.callEnded,
          const Duration(minutes: 30),
        ),
      ]);
      check(m.bothParticipantsConnectedSeconds).equals(30 * 60);
      check(m.status).equals(QuranSessionCallStatus.ended);
      check(m.teacherStatus).equals(CallParticipantStatus.left);
      check(m.studentStatus).equals(CallParticipantStatus.left);
    });
  });

  group('Status snapshots & join state', () {
    test('inProgress while both connected', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 0)),
      ], evaluatedAt: at(const Duration(minutes: 3)));
      check(m.status).equals(QuranSessionCallStatus.inProgress);
      check(m.teacherStatus).equals(CallParticipantStatus.connected);
    });

    test('notStarted when nobody joined and window open', () {
      final m = compute(
        const <CallTrackingEvent>[],
        evaluatedAt: at(const Duration(minutes: 2)),
      );
      check(m.status).equals(QuranSessionCallStatus.notStarted);
    });

    test('disconnected status after an involuntary drop', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 0)),
        ev(
          student,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 5),
        ),
      ]);
      check(m.studentStatus).equals(CallParticipantStatus.disconnected);
      check(m.status).equals(QuranSessionCallStatus.waitingForParticipant);
    });

    test('join-state snapshot carries reconnect + late detail', () {
      final m = compute([
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 7)),
        ev(student, CallTrackingEventType.joined, const Duration(minutes: 7)),
        ev(
          teacher,
          CallTrackingEventType.disconnected,
          const Duration(minutes: 9),
        ),
        ev(teacher, CallTrackingEventType.joined, const Duration(minutes: 10)),
      ]);
      check(m.teacherJoinState.late).equals(true);
      check(m.teacherJoinState.reconnectCount).equals(1);
      check(
        m.teacherJoinState.firstConnectAt,
      ).equals(at(const Duration(minutes: 7)));
      check(m.bothConnectedMinutes).isGreaterOrEqual(0);
    });
  });

  group('Pure value objects', () {
    test('ParticipantJoinState.initial is not-joined', () {
      final s = ParticipantJoinState.initial(teacher);
      check(s.status).equals(CallParticipantStatus.notJoined);
      check(s.hasEverConnected).isFalse();
    });

    test('CallDurationCalculator clamps and ignores double-open', () {
      final calc = CallDurationCalculator()
        ..open(1000)
        ..open(5000) // ignored — already open
        ..close(4000); // 3 seconds
      check(calc.totalSeconds).equals(3);
      check(calc.isOpen).isFalse();
      calc.close(9999); // closing when not open is a no-op
      check(calc.totalSeconds).equals(3);
    });

    test('CallReconnectPolicy ignores duplicate-while-connected', () {
      const policy = CallReconnectPolicy();
      check(
        policy.isReconnect(hasEverConnected: true, isConnected: true),
      ).isFalse();
      check(
        policy.isReconnect(hasEverConnected: true, isConnected: false),
      ).isTrue();
      check(
        policy.isReconnect(hasEverConnected: false, isConnected: false),
      ).isFalse();
    });

    test('CallTrackingPolicy.copyWith swaps each policy independently', () {
      const base = CallTrackingPolicy();
      final lateSwap = base.copyWith(
        late: const CallLatePolicy(gracePeriod: Duration(minutes: 2)),
      );
      check(lateSwap.late.gracePeriod).equals(const Duration(minutes: 2));
      check(lateSwap.noShow).equals(base.noShow);

      final noShowSwap = base.copyWith(
        noShow: const CallNoShowPolicy(noShowWindow: Duration(minutes: 9)),
      );
      check(noShowSwap.noShow.noShowWindow).equals(const Duration(minutes: 9));

      final reconnectSwap = base.copyWith(
        reconnect: const CallReconnectPolicy(),
      );
      check(reconnectSwap).equals(base);
    });

    test(
      'policies have value equality (props evaluated on distinct instances)',
      () {
        check(const CallTrackingPolicy()).equals(CallTrackingPolicy.production);
        check(
          const CallLatePolicy(gracePeriod: Duration(minutes: 1)),
        ).not((it) => it.equals(const CallLatePolicy()));
        check(
          const CallNoShowPolicy(noShowWindow: Duration(minutes: 1)),
        ).not((it) => it.equals(const CallNoShowPolicy()));
      },
    );
  });

  group('Value semantics & failures', () {
    test('events are value-equal and dedupe by identity', () {
      final a = ev(
        teacher,
        CallTrackingEventType.joined,
        const Duration(minutes: 1),
        id: 'x',
      );
      final b = ev(
        teacher,
        CallTrackingEventType.joined,
        const Duration(minutes: 1),
        id: 'x',
      );
      check(a).equals(b);
      check(
        a.occurredAtMs,
      ).equals(at(const Duration(minutes: 1)).millisecondsSinceEpoch);
    });

    test('typed failures expose a message, toString and value equality', () {
      // Distinct messages force base `props`/`toString` to be evaluated.
      check(
        const MissingTimestampFailure('a'),
      ).not((it) => it.equals(const MissingTimestampFailure('b')));
      check(const MissingTimestampFailure().message).isNotEmpty();
      check(
        const MissingTimestampFailure().toString(),
      ).contains('MissingTimestampFailure');

      const role = InvalidParticipantRoleFailure('ghost');
      check(role.rawRole).equals('ghost');
      check(role.toString()).contains('ghost');
      check(
        role,
      ).not((it) => it.equals(const InvalidParticipantRoleFailure('other')));

      const type = InvalidEventTypeFailure('boom');
      check(type.rawType).equals('boom');
      check(type).not((it) => it.equals(const InvalidEventTypeFailure('bang')));
    });
  });
}
