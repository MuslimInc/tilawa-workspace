import 'package:equatable/equatable.dart';

import '../entities/session_participant_role.dart';
import 'call_participant_status.dart';
import 'participant_join_state.dart';

/// The computed, authoritative result of folding a call's event stream.
///
/// ## Trust & visibility
///
/// Every field here is **backend-calculated** from the raw event log inside a
/// Cloud Function transaction; the client mirrors the same pure calculator only
/// for display. A client must never be trusted to report these directly.
///
/// - **User-facing** (shown to teacher/student): [callStarted],
///   [actualCallStartedAt], [bothParticipantsConnectedSeconds],
///   [callEndedAt], [teacherStatus], [studentStatus], [status].
/// - **Admin-only** (operational quality signals): [teacherLate], [studentLate],
///   [teacherNoShow], [studentNoShow], [reconnectCount], [interruptionCount],
///   [waitingSeconds].
class QuranSessionCallMetrics extends Equatable {
  const QuranSessionCallMetrics({
    required this.callStarted,
    required this.actualCallStartedAt,
    required this.firstJoinRole,
    required this.firstJoinAt,
    required this.secondJoinRole,
    required this.secondJoinAt,
    required this.waitingSeconds,
    required this.bothParticipantsConnectedSeconds,
    required this.teacherLate,
    required this.studentLate,
    required this.teacherNoShow,
    required this.studentNoShow,
    required this.teacherReconnectCount,
    required this.studentReconnectCount,
    required this.interruptionCount,
    required this.callEndedAt,
    required this.teacherStatus,
    required this.studentStatus,
    required this.teacherJoinState,
    required this.studentJoinState,
    required this.status,
  });

  /// True once both participants have been connected at the same time.
  final bool callStarted;

  /// When both participants were first connected simultaneously. The single
  /// canonical "the call really began" instant. Null until the call starts.
  final DateTime? actualCallStartedAt;

  final SessionParticipantRole? firstJoinRole;
  final DateTime? firstJoinAt;
  final SessionParticipantRole? secondJoinRole;
  final DateTime? secondJoinAt;

  /// Seconds the first participant spent waiting before the call started (or
  /// before it ended, if the second participant never connected). Never counts
  /// as call duration.
  final int waitingSeconds;

  /// **Primary production metric.** Seconds during which both participants were
  /// connected at the same time, summed across interruptions. Excludes waiting.
  final int bothParticipantsConnectedSeconds;

  /// Late flags — null when the participant never connected (see no-show).
  final bool? teacherLate;
  final bool? studentLate;

  final bool teacherNoShow;
  final bool studentNoShow;

  /// Reconnects = connects after the participant's first connect.
  final int teacherReconnectCount;
  final int studentReconnectCount;

  /// Drops/rejoins that happened *after* the call had already started.
  /// A subset of total reconnects (waiting-before-start drops do not count).
  final int interruptionCount;

  final DateTime? callEndedAt;

  final CallParticipantStatus teacherStatus;
  final CallParticipantStatus studentStatus;

  /// Rich per-participant snapshots (join times, reconnects, late flag).
  final ParticipantJoinState teacherJoinState;
  final ParticipantJoinState studentJoinState;

  final QuranSessionCallStatus status;

  int get reconnectCount => teacherReconnectCount + studentReconnectCount;

  /// Convenience: the headline duration in whole minutes (floored).
  int get bothConnectedMinutes => bothParticipantsConnectedSeconds ~/ 60;

  @override
  List<Object?> get props => [
    callStarted,
    actualCallStartedAt,
    firstJoinRole,
    firstJoinAt,
    secondJoinRole,
    secondJoinAt,
    waitingSeconds,
    bothParticipantsConnectedSeconds,
    teacherLate,
    studentLate,
    teacherNoShow,
    studentNoShow,
    teacherReconnectCount,
    studentReconnectCount,
    interruptionCount,
    callEndedAt,
    teacherStatus,
    studentStatus,
    teacherJoinState,
    studentJoinState,
    status,
  ];
}
