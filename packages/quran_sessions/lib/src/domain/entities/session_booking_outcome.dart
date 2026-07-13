import 'session_lifecycle_status.dart';
import 'session_aggregate.dart';

/// Server booking creation result including optional sandbox checkout token.
final class SessionBookingOutcome {
  const SessionBookingOutcome({
    required this.aggregate,
    this.clientConfirmToken,
    this.paymentReference,
  });

  final SessionAggregate aggregate;
  final String? clientConfirmToken;
  final String? paymentReference;

  bool get requiresPaymentConfirmation =>
      aggregate.lifecycleStatus == SessionLifecycleStatus.pendingPayment &&
      clientConfirmToken != null &&
      clientConfirmToken!.isNotEmpty;
}
