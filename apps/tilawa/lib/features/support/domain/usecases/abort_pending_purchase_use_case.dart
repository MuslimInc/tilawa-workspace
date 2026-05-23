import 'package:injectable/injectable.dart';

import '../repositories/support_repository.dart';

/// Aborts a stuck in-flight Play purchase by failing the underlying waiter
/// with [PurchaseFailureReason.billingUnavailable].
///
/// Used to recover from Play closing its sheet without emitting a stream
/// event (e.g. the "not configured for billing" dialog) so the spinner does
/// not hang until the 5-minute waiter timeout.
@lazySingleton
class AbortPendingPurchaseUseCase {
  const AbortPendingPurchaseUseCase(this._repository);

  final SupportRepository _repository;

  /// Returns `true` if a pending waiter was aborted.
  bool call(String productId) =>
      _repository.abortPendingPurchaseAsUnavailable(productId);
}
