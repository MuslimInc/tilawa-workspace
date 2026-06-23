import '../../../boundaries/payment/payment_provider.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

/// Maps a [PaymentFailure] from the payment boundary to the corresponding
/// [QuranSessionsFailure] domain subtype. Called at the BLoC boundary so
/// states always carry domain-typed failures only.
QuranSessionsFailure mapPaymentFailure(PaymentFailure f) => switch (f) {
  ChargeDeclinedFailure() => const PaymentDeclinedFailure(),
  ChargeCancelledFailure() => const PaymentCancelledFailure(),
  GatewayFailure() => const PaymentProviderFailure(),
};
