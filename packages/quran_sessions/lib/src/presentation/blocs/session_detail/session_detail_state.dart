import 'package:equatable/equatable.dart';

import '../../../domain/entities/session_aggregate.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/entities/session_audit_event.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

sealed class SessionDetailState extends Equatable {
  const SessionDetailState();

  @override
  List<Object?> get props => [];
}

final class SessionDetailInitial extends SessionDetailState {
  const SessionDetailInitial();
}

final class SessionDetailLoading extends SessionDetailState {
  const SessionDetailLoading();
}

final class SessionDetailSuccess extends SessionDetailState {
  const SessionDetailSuccess({
    required this.aggregate,
    required this.timeline,
    this.joinInProgress = false,
    this.joinFailure,
    this.reportInProgress = false,
    this.reportFailure,
    this.reportSubmitted = false,
  });

  final SessionAggregate aggregate;
  final List<SessionAuditEvent> timeline;
  final bool joinInProgress;
  final QuranSessionsFailure? joinFailure;
  final bool reportInProgress;
  final QuranSessionsFailure? reportFailure;
  final bool reportSubmitted;

  bool get canJoin =>
      aggregate.sessionId != null && aggregate.lifecycleStatus.canJoinSession;

  SessionDetailSuccess copyWith({
    SessionAggregate? aggregate,
    List<SessionAuditEvent>? timeline,
    bool? joinInProgress,
    bool clearJoinInProgress = false,
    QuranSessionsFailure? joinFailure,
    bool clearJoinFailure = false,
    bool? reportInProgress,
    bool clearReportInProgress = false,
    QuranSessionsFailure? reportFailure,
    bool clearReportFailure = false,
    bool? reportSubmitted,
    bool clearReportSubmitted = false,
  }) {
    return SessionDetailSuccess(
      aggregate: aggregate ?? this.aggregate,
      timeline: timeline ?? this.timeline,
      joinInProgress: clearJoinInProgress
          ? false
          : joinInProgress ?? this.joinInProgress,
      joinFailure: clearJoinFailure ? null : joinFailure ?? this.joinFailure,
      reportInProgress: clearReportInProgress
          ? false
          : reportInProgress ?? this.reportInProgress,
      reportFailure: clearReportFailure
          ? null
          : reportFailure ?? this.reportFailure,
      reportSubmitted: clearReportSubmitted
          ? false
          : reportSubmitted ?? this.reportSubmitted,
    );
  }

  @override
  List<Object?> get props => [
    aggregate,
    timeline,
    joinInProgress,
    joinFailure,
    reportInProgress,
    reportFailure,
    reportSubmitted,
  ];
}

final class SessionDetailFailure extends SessionDetailState {
  const SessionDetailFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
