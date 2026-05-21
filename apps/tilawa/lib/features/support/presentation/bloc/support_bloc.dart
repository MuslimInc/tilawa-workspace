import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../domain/usecases/get_support_products_use_case.dart';
import '../../domain/usecases/purchase_support_product_use_case.dart';
import '../../domain/usecases/restore_purchases_use_case.dart';
import 'support_event.dart';
import 'support_state.dart';

@injectable
class SupportBloc extends Bloc<SupportEvent, SupportState> {
  SupportBloc(
    this._getProducts,
    this._purchase,
    this._restore,
    this._connectivity,
    this._analytics,
  ) : super(const SupportState()) {
    on<SupportStarted>(_onStarted);
    on<SupportTierSelected>(_onTierSelected);
    on<SupportContinuePressed>(_onContinuePressed);
    on<SupportPurchaseConfirmed>(_onPurchaseConfirmed);
    on<SupportPurchaseDismissed>(_onPurchaseDismissed);
    on<SupportRestoreRequested>(_onRestoreRequested);
    on<SupportThankYouDismissed>(_onThankYouDismissed);
  }

  final GetSupportProductsUseCase _getProducts;
  final PurchaseSupportProductUseCase _purchase;
  final RestorePurchasesUseCase _restore;
  final Connectivity _connectivity;
  final AnalyticsService _analytics;

  Future<void> _onStarted(
    SupportStarted event,
    Emitter<SupportState> emit,
  ) async {
    await _analytics.logEvent(AnalyticsEvents.supportScreenViewed);
    emit(state.copyWith(status: SupportStatus.loading, errorMessage: null));

    final List<ConnectivityResult> connectivity =
        await _connectivity.checkConnectivity();
    final bool offline = connectivity.contains(ConnectivityResult.none);

    if (offline) {
      emit(
        state.copyWith(
          status: SupportStatus.error,
          isOffline: true,
          errorMessage: null,
        ),
      );
      return;
    }

    final result = await _getProducts();
    result.fold(
      (Failure failure) {
        if (failure is PurchaseFailure &&
            failure.reason == PurchaseFailureReason.userCancelled) {
          return;
        }
        emit(
          state.copyWith(
            status: SupportStatus.error,
            errorMessage: _messageForFailure(failure),
            isOffline: false,
          ),
        );
      },
      (products) {
        emit(
          state.copyWith(
            status: SupportStatus.ready,
            products: products,
            isOffline: false,
            errorMessage: null,
          ),
        );
      },
    );
  }

  void _onTierSelected(
    SupportTierSelected event,
    Emitter<SupportState> emit,
  ) {
    _analytics.logEvent(
      AnalyticsEvents.supportTierSelected,
      parameters: <String, Object>{
        AnalyticsParams.productId: event.productId,
      },
    );
    emit(state.copyWith(selectedProductId: event.productId));
  }

  void _onContinuePressed(
    SupportContinuePressed event,
    Emitter<SupportState> emit,
  ) {
    if (state.selectedProductId == null) {
      return;
    }
    emit(state.copyWith(purchasePhase: SupportPurchasePhase.confirming));
  }

  Future<void> _onPurchaseConfirmed(
    SupportPurchaseConfirmed event,
    Emitter<SupportState> emit,
  ) async {
    final String? productId = state.selectedProductId;
    if (productId == null) {
      return;
    }
    emit(
      state.copyWith(
        purchasePhase: SupportPurchasePhase.purchasing,
        errorMessage: null,
      ),
    );

    final result = await _purchase(productId);
    result.fold(
      (Failure failure) {
        if (failure is PurchaseFailure &&
            failure.reason == PurchaseFailureReason.userCancelled) {
          emit(
            state.copyWith(purchasePhase: SupportPurchasePhase.idle),
          );
          return;
        }
        _analytics.logEvent(
          AnalyticsEvents.supportPurchaseFailed,
          parameters: <String, Object>{
            AnalyticsParams.productId: productId,
            if (failure is PurchaseFailure)
              AnalyticsParams.purchaseReason: failure.reason.name,
          },
        );
        emit(
          state.copyWith(
            purchasePhase: SupportPurchasePhase.idle,
            errorMessage: _messageForFailure(failure),
          ),
        );
      },
      (outcome) {
        emit(
          state.copyWith(
            purchasePhase: SupportPurchasePhase.thanked,
            thankYouProductId: outcome.productId,
            errorMessage: null,
          ),
        );
      },
    );
  }

  void _onPurchaseDismissed(
    SupportPurchaseDismissed event,
    Emitter<SupportState> emit,
  ) {
    emit(state.copyWith(purchasePhase: SupportPurchasePhase.idle));
  }

  Future<void> _onRestoreRequested(
    SupportRestoreRequested event,
    Emitter<SupportState> emit,
  ) async {
    final result = await _restore();
    result.fold(
      (Failure failure) {
        if (failure is PurchaseFailure &&
            failure.reason == PurchaseFailureReason.userCancelled) {
          return;
        }
        emit(state.copyWith(errorMessage: _messageForFailure(failure)));
      },
      (_) => emit(state.copyWith(errorMessage: null)),
    );
  }

  void _onThankYouDismissed(
    SupportThankYouDismissed event,
    Emitter<SupportState> emit,
  ) {
    emit(
      state.copyWith(
        purchasePhase: SupportPurchasePhase.idle,
        thankYouProductId: null,
      ),
    );
  }

  String _messageForFailure(Failure failure) {
    if (failure is PurchaseFailure) {
      return switch (failure.reason) {
        PurchaseFailureReason.billingUnavailable =>
          'Purchases are not available right now.',
        PurchaseFailureReason.productNotFound =>
          'This support option is not available.',
        PurchaseFailureReason.verificationFailed =>
          'We could not confirm your support. Please try again.',
        PurchaseFailureReason.pending =>
          'Your support is still processing.',
        PurchaseFailureReason.alreadyOwned =>
          'This support was already completed.',
        PurchaseFailureReason.network =>
          'Network error. Check your connection and try again.',
        PurchaseFailureReason.userCancelled => '',
      };
    }
    return failure.message ?? 'Something went wrong.';
  }
}
