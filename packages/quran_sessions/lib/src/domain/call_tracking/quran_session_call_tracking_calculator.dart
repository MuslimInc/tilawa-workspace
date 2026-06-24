import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_participant_role.dart';
import 'call_duration_calculator.dart';
import 'call_participant_status.dart';
import 'call_tracking_event.dart';
import 'call_tracking_failure.dart';
import 'call_tracking_policy.dart';
import 'participant_join_state.dart';
import 'quran_session_call_metrics.dart';

/// Pure business engine that folds a Quran-session call event stream into
/// [QuranSessionCallMetrics].
///
/// This is the canonical, framework-free specification of the call-tracking
/// rules. It depends on nothing but the domain (no Firebase, Agora, WebRTC,
/// Flutter, or UI). The Cloud Function reducer is the runtime authority; this
/// engine mirrors the same rules for client-side display and is the artifact
/// the rule tests exercise.
///
/// Guarantees:
/// - **Idempotent**: duplicate [CallTrackingEvent.eventId]s are ignored.
/// - **Order-independent**: events are sorted by timestamp before folding, so
///   out-of-order delivery yields the same result.
/// - **Non-negative**: durations are clamped; a corrupt stream degrades to 0,
///   never a negative metric.
/// - **Deterministic**: same inputs → identical metrics (stable on replay).
class QuranSessionCallTrackingCalculator {
  const QuranSessionCallTrackingCalculator({
    this.policy = CallTrackingPolicy.production,
  });

  final CallTrackingPolicy policy;

  /// Folds [events] for a session scheduled at [scheduledStartAt], evaluating
  /// no-show/waiting against [evaluatedAt] (call end, or "now").
  ///
  /// Returns [Right] with the metrics for any well-formed event list — the
  /// engine is total. Parse-time failures (bad role, missing timestamp) are
  /// surfaced by [CallTrackingEvent.parse] before reaching here.
  Either<CallTrackingFailure, QuranSessionCallMetrics> calculate({
    required List<CallTrackingEvent> events,
    required DateTime scheduledStartAt,
    required DateTime evaluatedAt,
  }) {
    final ordered = _dedupeAndSort(events);

    final teacher = _Tracker(SessionParticipantRole.teacher);
    final student = _Tracker(SessionParticipantRole.student);
    final duration = CallDurationCalculator();

    SessionParticipantRole? firstJoinRole;
    DateTime? firstJoinAt;
    SessionParticipantRole? secondJoinRole;
    DateTime? secondJoinAt;
    DateTime? actualCallStartedAt;
    DateTime? callEndedAt;
    var interruptionCount = 0;

    _Tracker trackerFor(SessionParticipantRole role) =>
        role == SessionParticipantRole.teacher ? teacher : student;

    for (final event in ordered) {
      final self = trackerFor(event.role);
      final other = event.role == SessionParticipantRole.teacher
          ? student
          : teacher;

      switch (event.type) {
        case CallTrackingEventType.joined:
          if (self.isConnected) {
            break; // duplicate join while connected — idempotent.
          }
          if (policy.reconnect.isReconnect(
            hasEverConnected: self.hasEverConnected,
            isConnected: false,
          )) {
            self.reconnectCount += 1;
            if (actualCallStartedAt != null) {
              interruptionCount += 1;
            }
          } else {
            // First-ever connect for this participant.
            self.firstConnectAt = event.occurredAt;
            self.late = policy.late.isLate(
              scheduledStartAt: scheduledStartAt,
              joinedAt: event.occurredAt,
            );
            if (firstJoinRole == null) {
              firstJoinRole = event.role;
              firstJoinAt = event.occurredAt;
            } else if (secondJoinRole == null && event.role != firstJoinRole) {
              secondJoinRole = event.role;
              secondJoinAt = event.occurredAt;
            }
          }
          self
            ..hasEverConnected = true
            ..isConnected = true
            ..lastConnectAt = event.occurredAt
            ..lastType = CallTrackingEventType.joined;

          if (other.isConnected) {
            duration.open(event.occurredAtMs);
            actualCallStartedAt ??= event.occurredAt;
          }

        case CallTrackingEventType.disconnected:
        case CallTrackingEventType.left:
          if (!self.isConnected) {
            break; // duplicate leave/disconnect — idempotent.
          }
          if (duration.isOpen) {
            duration.close(event.occurredAtMs);
          }
          self
            ..isConnected = false
            ..lastType = event.type;

        case CallTrackingEventType.callEnded:
          if (duration.isOpen) {
            duration.close(event.occurredAtMs);
          }
          for (final t in [teacher, student]) {
            if (t.isConnected) {
              t
                ..isConnected = false
                ..lastType = CallTrackingEventType.left;
            }
          }
          callEndedAt ??= event.occurredAt;
      }
    }

    final teacherNoShow = policy.noShow.isNoShow(
      scheduledStartAt: scheduledStartAt,
      evaluatedAt: evaluatedAt,
      everJoined: teacher.hasEverConnected,
    );
    final studentNoShow = policy.noShow.isNoShow(
      scheduledStartAt: scheduledStartAt,
      evaluatedAt: evaluatedAt,
      everJoined: student.hasEverConnected,
    );

    final waitingSeconds = _waitingSeconds(
      firstJoinAt: firstJoinAt,
      actualCallStartedAt: actualCallStartedAt,
      callEndedAt: callEndedAt,
      evaluatedAt: evaluatedAt,
    );

    final teacherStatus = _statusFor(
      teacher,
      other: student,
      noShow: teacherNoShow,
    );
    final studentStatus = _statusFor(
      student,
      other: teacher,
      noShow: studentNoShow,
    );

    return Right(
      QuranSessionCallMetrics(
        callStarted: actualCallStartedAt != null,
        actualCallStartedAt: actualCallStartedAt,
        firstJoinRole: firstJoinRole,
        firstJoinAt: firstJoinAt,
        secondJoinRole: secondJoinRole,
        secondJoinAt: secondJoinAt,
        waitingSeconds: waitingSeconds,
        bothParticipantsConnectedSeconds: duration.totalSeconds,
        teacherLate: teacher.late,
        studentLate: student.late,
        teacherNoShow: teacherNoShow,
        studentNoShow: studentNoShow,
        teacherReconnectCount: teacher.reconnectCount,
        studentReconnectCount: student.reconnectCount,
        interruptionCount: interruptionCount,
        callEndedAt: callEndedAt,
        teacherStatus: teacherStatus,
        studentStatus: studentStatus,
        teacherJoinState: teacher.snapshot(teacherStatus),
        studentJoinState: student.snapshot(studentStatus),
        status: _overallStatus(
          callEndedAt: callEndedAt,
          teacherConnected: teacher.isConnected,
          studentConnected: student.isConnected,
        ),
      ),
    );
  }

  int _waitingSeconds({
    required DateTime? firstJoinAt,
    required DateTime? actualCallStartedAt,
    required DateTime? callEndedAt,
    required DateTime evaluatedAt,
  }) {
    if (firstJoinAt == null) {
      return 0;
    }
    final end = actualCallStartedAt ?? callEndedAt ?? evaluatedAt;
    final seconds = end.difference(firstJoinAt).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  CallParticipantStatus _statusFor(
    _Tracker tracker, {
    required _Tracker other,
    required bool noShow,
  }) {
    if (!tracker.hasEverConnected) {
      return noShow
          ? CallParticipantStatus.noShow
          : CallParticipantStatus.notJoined;
    }
    if (tracker.isConnected) {
      return other.isConnected
          ? CallParticipantStatus.connected
          : CallParticipantStatus.waiting;
    }
    return tracker.lastType == CallTrackingEventType.left
        ? CallParticipantStatus.left
        : CallParticipantStatus.disconnected;
  }

  QuranSessionCallStatus _overallStatus({
    required DateTime? callEndedAt,
    required bool teacherConnected,
    required bool studentConnected,
  }) {
    if (callEndedAt != null) {
      return QuranSessionCallStatus.ended;
    }
    if (teacherConnected && studentConnected) {
      return QuranSessionCallStatus.inProgress;
    }
    if (teacherConnected || studentConnected) {
      return QuranSessionCallStatus.waitingForParticipant;
    }
    return QuranSessionCallStatus.notStarted;
  }

  List<CallTrackingEvent> _dedupeAndSort(List<CallTrackingEvent> events) {
    final seen = <String>{};
    final deduped = <CallTrackingEvent>[];
    for (final event in events) {
      if (seen.add(event.eventId)) {
        deduped.add(event);
      }
    }
    // Stable sort by timestamp, tie-broken by original order.
    final indexed =
        [
          for (var i = 0; i < deduped.length; i++) (i, deduped[i]),
        ]..sort((a, b) {
          final byTime = a.$2.occurredAtMs.compareTo(b.$2.occurredAtMs);
          return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
        });
    return [for (final entry in indexed) entry.$2];
  }
}

class _Tracker {
  _Tracker(this.role);

  final SessionParticipantRole role;
  bool hasEverConnected = false;
  bool isConnected = false;
  DateTime? firstConnectAt;
  DateTime? lastConnectAt;
  int reconnectCount = 0;
  bool? late;
  CallTrackingEventType? lastType;

  ParticipantJoinState snapshot(CallParticipantStatus status) {
    return ParticipantJoinState(
      role: role,
      hasEverConnected: hasEverConnected,
      isConnected: isConnected,
      firstConnectAt: firstConnectAt,
      lastConnectAt: lastConnectAt,
      reconnectCount: reconnectCount,
      late: late,
      status: status,
    );
  }
}
