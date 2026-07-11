import 'package:equatable/equatable.dart';

sealed class PackageOrderEvent extends Equatable {
  const PackageOrderEvent();

  @override
  List<Object?> get props => [];
}

/// Load purchasable plans for [marketCode] to present disclosure.
final class PackagePlansRequested extends PackageOrderEvent {
  const PackagePlansRequested({required this.marketCode});

  final String marketCode;

  @override
  List<Object?> get props => [marketCode];
}

/// Submit a package order. [idempotencyKey] must be stable across retries of the
/// same user intent.
final class PackageOrderSubmitted extends PackageOrderEvent {
  const PackageOrderSubmitted({
    required this.planId,
    required this.teacherId,
    required this.idempotencyKey,
    this.learnerId,
    this.compatibilityMeetingId,
  });

  final String planId;
  final String teacherId;
  final String idempotencyKey;
  final String? learnerId;
  final String? compatibilityMeetingId;

  @override
  List<Object?> get props => [
    planId,
    teacherId,
    idempotencyKey,
    learnerId,
    compatibilityMeetingId,
  ];
}

/// Re-read the current order to reflect an admin payment decision.
final class PackageOrderRefreshed extends PackageOrderEvent {
  const PackageOrderRefreshed({required this.orderId});

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

/// Owner/guardian cancels a pending order.
final class PackageOrderCancelled extends PackageOrderEvent {
  const PackageOrderCancelled({
    required this.orderId,
    required this.reason,
    required this.idempotencyKey,
  });

  final String orderId;
  final String reason;
  final String idempotencyKey;

  @override
  List<Object?> get props => [orderId, reason, idempotencyKey];
}
