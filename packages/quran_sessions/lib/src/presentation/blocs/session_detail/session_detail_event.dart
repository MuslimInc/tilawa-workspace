import 'package:equatable/equatable.dart';

import '../../../domain/entities/session_report_category.dart';

sealed class SessionDetailEvent extends Equatable {
  const SessionDetailEvent();

  @override
  List<Object?> get props => [];
}

final class SessionDetailLoadRequested extends SessionDetailEvent {
  const SessionDetailLoadRequested({required this.bookingId});

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// User taps join on session detail.
final class SessionDetailJoinRequested extends SessionDetailEvent {
  const SessionDetailJoinRequested();
}

/// Re-opens the external meeting link without re-running join validation.
final class SessionDetailOpenMeetingAgainRequested extends SessionDetailEvent {
  const SessionDetailOpenMeetingAgainRequested();
}

/// User submits a safety report from session detail.
final class SessionDetailReportSubmitted extends SessionDetailEvent {
  const SessionDetailReportSubmitted({
    required this.category,
    required this.description,
  });

  final SessionReportCategory category;
  final String description;

  @override
  List<Object?> get props => [category, description];
}

/// Clears one-shot report success UI after toast.
final class SessionDetailReportAcknowledged extends SessionDetailEvent {
  const SessionDetailReportAcknowledged();
}

/// User submits a dispute from session detail.
final class SessionDetailDisputeSubmitted extends SessionDetailEvent {
  const SessionDetailDisputeSubmitted({required this.reason});

  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// Clears one-shot dispute success UI after toast.
final class SessionDetailDisputeAcknowledged extends SessionDetailEvent {
  const SessionDetailDisputeAcknowledged();
}

/// Counterparty accepts or rejects a pending reschedule request.
final class SessionDetailRescheduleRespondSubmitted extends SessionDetailEvent {
  const SessionDetailRescheduleRespondSubmitted({required this.accept});

  final bool accept;

  @override
  List<Object?> get props => [accept];
}

/// Clears one-shot reschedule respond success UI after toast.
final class SessionDetailRescheduleRespondAcknowledged
    extends SessionDetailEvent {
  const SessionDetailRescheduleRespondAcknowledged();
}

/// Student confirms cancellation with a reason from [showCancelSessionSheet].
final class SessionDetailCancelSubmitted extends SessionDetailEvent {
  const SessionDetailCancelSubmitted({required this.reason});

  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// Clears one-shot cancellation success UI after toast.
final class SessionDetailCancelAcknowledged extends SessionDetailEvent {
  const SessionDetailCancelAcknowledged();
}
