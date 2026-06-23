import 'package:equatable/equatable.dart';

import '../value_objects/actor_role.dart';

/// Pending reschedule request awaiting counterparty confirmation.
class PendingRescheduleRequest extends Equatable {
  const PendingRescheduleRequest({
    required this.requestId,
    required this.bookingId,
    required this.requestedByUserId,
    required this.requestedByRole,
    required this.reason,
    required this.newStartsAt,
    required this.status,
  });

  final String requestId;
  final String bookingId;
  final String requestedByUserId;
  final ActorRole requestedByRole;
  final String reason;
  final DateTime newStartsAt;
  final String status;

  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
    requestId,
    bookingId,
    requestedByUserId,
    requestedByRole,
    reason,
    newStartsAt,
    status,
  ];
}
