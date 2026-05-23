import 'package:equatable/equatable.dart';

/// Result of a completed and verified support purchase.
class PurchaseOutcome extends Equatable {
  const PurchaseOutcome({
    required this.productId,
    required this.orderId,
  });

  final String productId;
  final String orderId;

  @override
  List<Object?> get props => <Object?>[productId, orderId];
}
