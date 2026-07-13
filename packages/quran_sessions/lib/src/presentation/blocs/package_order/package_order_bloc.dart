import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/quran_learning_package.dart';
import '../../../domain/usecases/quran_package_order_usecases.dart';
import 'package_order_event.dart';
import 'package_order_state.dart';

/// Drives the package purchase flow: load disclosure → submit order → await
/// manual payment → reflect the admin's confirm/reject decision.
///
/// A pending order maps to [PackageOrderPendingPayment] (balance stays hidden
/// until confirmation); any terminal order maps to [PackageOrderResolved].
class PackageOrderBloc extends Bloc<PackageOrderEvent, PackageOrderState> {
  PackageOrderBloc({
    required this._getPlans,
    required this._createOrder,
    required this._cancelOrder,
    required this._refreshOrder,
  }) : super(const PackageOrderInitial()) {
    on<PackagePlansRequested>(_onPlansRequested);
    on<PackageOrderSubmitted>(_onSubmitted);
    on<PackageOrderRefreshed>(_onRefreshed);
    on<PackageOrderCancelled>(_onCancelled);
  }

  final GetPurchasablePackagePlansUseCase _getPlans;
  final CreateQuranPackageOrderUseCase _createOrder;
  final CancelQuranPackageOrderUseCase _cancelOrder;
  final RefreshQuranPackageOrderUseCase _refreshOrder;

  Future<void> _onPlansRequested(
    PackagePlansRequested event,
    Emitter<PackageOrderState> emit,
  ) async {
    emit(const PackagePlansLoading());
    final result = await _getPlans(marketCode: event.marketCode);
    result.fold(
      (failure) => emit(PackageOrderFailure(failure)),
      (plans) => emit(PackagePlansLoaded(plans)),
    );
  }

  Future<void> _onSubmitted(
    PackageOrderSubmitted event,
    Emitter<PackageOrderState> emit,
  ) async {
    emit(const PackageOrderSubmitting());
    final result = await _createOrder(
      planId: event.planId,
      teacherId: event.teacherId,
      idempotencyKey: event.idempotencyKey,
      learnerId: event.learnerId,
      compatibilityMeetingId: event.compatibilityMeetingId,
    );
    result.fold(
      (failure) => emit(PackageOrderFailure(failure)),
      (order) => emit(_stateForOrder(order)),
    );
  }

  Future<void> _onRefreshed(
    PackageOrderRefreshed event,
    Emitter<PackageOrderState> emit,
  ) async {
    final result = await _refreshOrder(event.orderId);
    result.fold(
      (failure) => emit(PackageOrderFailure(failure, order: _currentOrder())),
      (order) => emit(_stateForOrder(order)),
    );
  }

  Future<void> _onCancelled(
    PackageOrderCancelled event,
    Emitter<PackageOrderState> emit,
  ) async {
    final result = await _cancelOrder(
      orderId: event.orderId,
      reason: event.reason,
      idempotencyKey: event.idempotencyKey,
    );
    result.fold(
      (failure) => emit(PackageOrderFailure(failure, order: _currentOrder())),
      (order) => emit(_stateForOrder(order)),
    );
  }

  PackageOrderState _stateForOrder(PackageOrder order) => order.isPending
      ? PackageOrderPendingPayment(order)
      : PackageOrderResolved(order);

  PackageOrder? _currentOrder() => switch (state) {
    PackageOrderPendingPayment(:final order) => order,
    PackageOrderResolved(:final order) => order,
    PackageOrderFailure(:final order) => order,
    _ => null,
  };
}
