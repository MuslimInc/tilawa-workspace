import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/currency_config.dart';
import '../../../../core/services/analytics_service.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/usecases/cancel_subscription_use_case.dart';
import '../../domain/usecases/check_feature_access_use_case.dart';
import '../../domain/usecases/get_available_plans_use_case.dart';
import '../../domain/usecases/get_premium_status_use_case.dart';
import '../../domain/usecases/purchase_subscription_use_case.dart';
import '../../domain/usecases/restore_subscription_use_case.dart';
import '../../domain/usecases/start_trial_use_case.dart';
import 'premium_event.dart';
import 'premium_state.dart';

@injectable
class PremiumBloc extends HydratedBloc<PremiumEvent, PremiumState> {
  PremiumBloc(
    this._getPremiumStatus,
    this._purchaseSubscription,
    this._cancelSubscription,
    this._restoreSubscription,
    this._startTrial,
    this._getAvailablePlans,
    this._checkFeatureAccess,
    this._analyticsService,
  ) : super(const PremiumState.initial()) {
    on<LoadPremiumStatus>(_onLoadPremiumStatus);
    on<PurchaseSubscription>(_onPurchaseSubscription);
    on<CancelSubscription>(_onCancelSubscription);
    on<RestoreSubscription>(_onRestoreSubscription);
    on<StartTrial>(_onStartTrial);
    on<LoadAvailablePlans>(_onLoadAvailablePlans);
    on<CheckFeatureAccess>(_onCheckFeatureAccess);
    on<RefreshPremiumStatus>(_onRefreshPremiumStatus);
  }
  final GetPremiumStatusUseCase _getPremiumStatus;
  final PurchaseSubscriptionUseCase _purchaseSubscription;
  final CancelSubscriptionUseCase _cancelSubscription;
  final RestoreSubscriptionUseCase _restoreSubscription;
  final StartTrialUseCase _startTrial;
  final GetAvailablePlansUseCase _getAvailablePlans;
  final CheckFeatureAccessUseCase _checkFeatureAccess;
  final AnalyticsService _analyticsService;

  Future<void> _onLoadPremiumStatus(
    LoadPremiumStatus event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumState.loading());

    try {
      final ({
        bool canDownload,
        List<SubscriptionPlan> plans,
        PremiumStatus status,
      })
      result = await _getPremiumStatus();
      emit(
        PremiumState.loaded(
          status: result.status,
          availablePlans: result.plans,
          canDownload: result.canDownload,
        ),
      );
    } catch (e) {
      emit(PremiumState.error(message: 'Failed to load premium status: $e'));
    }
  }

  Future<void> _onPurchaseSubscription(
    PurchaseSubscription event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumState.loading());

    try {
      final bool success = await _purchaseSubscription(event.planId);

      if (success) {
        // Log analytics event for successful purchase
        await _analyticsService.logPurchase(
          'subscription_${event.planId}',
          itemId: event.planId,
          currency: CurrencyConfig.currencyCode,
        );

        emit(
          const PremiumState.purchaseSuccess(
            message: 'Subscription purchased successfully!',
          ),
        );
        // Reload status after successful purchase
        add(const LoadPremiumStatus());
      } else {
        // Log analytics event for failed purchase
        await _analyticsService.logEvent(
          'purchase_failed',
          parameters: {
            'plan_id': event.planId,
            'reason': 'purchase_subscription_returned_false',
          },
        );

        emit(
          const PremiumState.purchaseFailed(
            message: 'Failed to purchase subscription. Please try again.',
          ),
        );
      }
    } catch (e) {
      // Log analytics event for purchase error
      await _analyticsService.logEvent(
        'purchase_error',
        parameters: {'plan_id': event.planId, 'error': e.toString()},
      );

      emit(PremiumState.purchaseFailed(message: 'Purchase failed: $e'));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumState.loading());

    try {
      final bool success = await _cancelSubscription();

      if (success) {
        emit(
          const PremiumState.purchaseSuccess(
            message: 'Subscription canceled successfully.',
          ),
        );
        // Reload status after cancellation
        add(const LoadPremiumStatus());
      } else {
        emit(
          const PremiumState.purchaseFailed(
            message: 'Failed to cancel subscription. Please try again.',
          ),
        );
      }
    } catch (e) {
      emit(PremiumState.purchaseFailed(message: 'Cancel failed: $e'));
    }
  }

  Future<void> _onRestoreSubscription(
    RestoreSubscription event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumState.loading());

    try {
      final bool success = await _restoreSubscription();

      if (success) {
        emit(
          const PremiumState.purchaseSuccess(
            message: 'Subscription restored successfully!',
          ),
        );
        // Reload status after restoration
        add(const LoadPremiumStatus());
      } else {
        emit(
          const PremiumState.purchaseFailed(
            message: 'No subscription found to restore.',
          ),
        );
      }
    } catch (e) {
      emit(PremiumState.purchaseFailed(message: 'Restore failed: $e'));
    }
  }

  Future<void> _onStartTrial(
    StartTrial event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumState.loading());

    try {
      final ({bool isEligible, bool success}) result = await _startTrial();

      if (!result.isEligible) {
        emit(
          const PremiumState.trialNotEligible(
            message:
                'Trial is not available. You may have already used it or have an active subscription.',
          ),
        );
        return;
      }

      if (result.success) {
        emit(
          const PremiumState.trialStarted(
            message: '7-day trial started! Enjoy premium features.',
          ),
        );
        // Reload status after trial start
        add(const LoadPremiumStatus());
      } else {
        emit(
          const PremiumState.purchaseFailed(
            message: 'Failed to start trial. Please try again.',
          ),
        );
      }
    } catch (e) {
      emit(PremiumState.purchaseFailed(message: 'Trial start failed: $e'));
    }
  }

  Future<void> _onLoadAvailablePlans(
    LoadAvailablePlans event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      final List<SubscriptionPlan> plans = await _getAvailablePlans();

      if (state is PremiumLoaded) {
        final currentState = state as PremiumLoaded;
        emit(currentState.copyWith(availablePlans: plans));
      }
    } catch (e) {
      emit(PremiumState.error(message: 'Failed to load plans: $e'));
    }
  }

  Future<void> _onCheckFeatureAccess(
    CheckFeatureAccess event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      final bool canAccess = await _checkFeatureAccess(event.featureName);

      if (!canAccess && event.featureName == 'download') {
        // Show premium upgrade prompt
        emit(
          const PremiumState.error(
            message: 'Download feature requires premium subscription.',
          ),
        );
      }
    } catch (e) {
      emit(PremiumState.error(message: 'Failed to check feature access: $e'));
    }
  }

  Future<void> _onRefreshPremiumStatus(
    RefreshPremiumStatus event,
    Emitter<PremiumState> emit,
  ) async {
    add(const LoadPremiumStatus());
  }

  @override
  PremiumState? fromJson(Map<String, dynamic> json) {
    // Premium status should be loaded from repository, so we always start with initial state
    return const PremiumState.initial();
  }

  @override
  Map<String, dynamic>? toJson(PremiumState state) {
    // Only persist if in initial state to avoid storing complex premium data
    if (state is PremiumInitial) {
      return {'state': 'initial'};
    }
    // For other states, don't persist (will reload from repository)
    return null;
  }
}
