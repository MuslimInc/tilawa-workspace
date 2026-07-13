import 'package:equatable/equatable.dart';

import '../../../domain/entities/quran_learning_package.dart';
import '../../../domain/failures/quran_package_failure.dart';

/// States for the package purchase (order → pending payment → activation) flow.
sealed class PackageOrderState extends Equatable {
  const PackageOrderState();

  @override
  List<Object?> get props => [];
}

/// Nothing loaded yet.
final class PackageOrderInitial extends PackageOrderState {
  const PackageOrderInitial();
}

/// Loading purchasable plans for disclosure.
final class PackagePlansLoading extends PackageOrderState {
  const PackagePlansLoading();
}

/// Plans available for the market; the learner can review and submit an order.
final class PackagePlansLoaded extends PackageOrderState {
  const PackagePlansLoaded(this.plans);

  final List<PackagePlan> plans;

  @override
  List<Object?> get props => [plans];
}

/// An order is being created on the server.
final class PackageOrderSubmitting extends PackageOrderState {
  const PackageOrderSubmitting();
}

/// The order was created and is awaiting off-app manual payment.
///
/// The balance is intentionally unavailable until the admin confirms payment.
final class PackageOrderPendingPayment extends PackageOrderState {
  const PackageOrderPendingPayment(this.order);

  final PackageOrder order;

  @override
  List<Object?> get props => [order];
}

/// The order reached a terminal state (confirmed/rejected/expired/cancelled).
final class PackageOrderResolved extends PackageOrderState {
  const PackageOrderResolved(this.order);

  final PackageOrder order;

  bool get isConfirmed => order.status == PackageOrderStatus.confirmed;

  @override
  List<Object?> get props => [order];
}

/// A command or load failed. [order] carries the last known order when present
/// so the UI can keep showing pending state alongside a retry affordance.
final class PackageOrderFailure extends PackageOrderState {
  const PackageOrderFailure(this.failure, {this.order});

  final QuranPackageFailure failure;
  final PackageOrder? order;

  @override
  List<Object?> get props => [failure, order];
}
