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
  });

  final SessionAggregate aggregate;
  final List<SessionAuditEvent> timeline;
  final bool joinInProgress;
  final QuranSessionsFailure? joinFailure;

  bool get canJoin =>
      aggregate.sessionId != null && aggregate.lifecycleStatus.canJoinSession;

  SessionDetailSuccess copyWith({
    SessionAggregate? aggregate,
    List<SessionAuditEvent>? timeline,
    bool? joinInProgress,
    bool clearJoinInProgress = false,
    QuranSessionsFailure? joinFailure,
    bool clearJoinFailure = false,
  }) {
    return SessionDetailSuccess(
      aggregate: aggregate ?? this.aggregate,
      timeline: timeline ?? this.timeline,
      joinInProgress: clearJoinInProgress
          ? false
          : joinInProgress ?? this.joinInProgress,
      joinFailure: clearJoinFailure ? null : joinFailure ?? this.joinFailure,
    );
  }

  @override
  List<Object?> get props => [
    aggregate,
    timeline,
    joinInProgress,
    joinFailure,
  ];
}

final class SessionDetailFailure extends SessionDetailState {
  const SessionDetailFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
