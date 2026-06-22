import 'package:equatable/equatable.dart';

import '../../../domain/entities/session_aggregate.dart';
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
  });

  final SessionAggregate aggregate;
  final List<SessionAuditEvent> timeline;

  @override
  List<Object?> get props => [aggregate, timeline];
}

final class SessionDetailFailure extends SessionDetailState {
  const SessionDetailFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
