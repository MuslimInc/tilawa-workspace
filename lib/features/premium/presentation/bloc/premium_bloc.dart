import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';
import 'package:muzakri/features/premium/presentation/bloc/premium_event.dart';
import 'package:muzakri/features/premium/presentation/bloc/premium_state.dart';

class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final PremiumRepository _premiumRepository;

  PremiumBloc({required PremiumRepository premiumRepository})
    : _premiumRepository = premiumRepository,
      super(const PremiumState.initial()) {
    on<LoadPremiumStatus>(_onLoadPremiumStatus);
    on<PurchaseSubscription>(_onPurchaseSubscription);
    on<CancelSubscription>(_onCancelSubscription);
    on<RestoreSubscription>(_onRestoreSubscription);
    on<StartTrial>(_onStartTrial);
    on<LoadAvailablePlans>(_onLoadAvailablePlans);
    on<CheckFeatureAccess>(_onCheckFeatureAccess);
    on<RefreshPremiumStatus>(_onRefreshPremiumStatus);
  }

  Future<void> _onLoadPremiumStatus(
    LoadPremiumStatus event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumState.loading());

    try {
      final status = await _premiumRepository.getPremiumStatus();
      final plans = await _premiumRepository.getAvailablePlans();
      final canDownload = await _premiumRepository.canDownload();

      emit(
        PremiumState.loaded(
          status: status,
          availablePlans: plans,
          canDownload: canDownload,
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
      final success = await _premiumRepository.purchaseSubscription(
        event.planId,
      );

      if (success) {
        emit(
          PremiumState.purchaseSuccess(
            message: 'Subscription purchased successfully!',
          ),
        );
        // Reload status after successful purchase
        add(const LoadPremiumStatus());
      } else {
        emit(
          const PremiumState.purchaseFailed(
            message: 'Failed to purchase subscription. Please try again.',
          ),
        );
      }
    } catch (e) {
      emit(PremiumState.purchaseFailed(message: 'Purchase failed: $e'));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumState.loading());

    try {
      final success = await _premiumRepository.cancelSubscription();

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
      final success = await _premiumRepository.restoreSubscription();

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
      final isEligible = await _premiumRepository.isTrialEligible();

      if (!isEligible) {
        emit(
          const PremiumState.trialNotEligible(
            message:
                'Trial is not available. You may have already used it or have an active subscription.',
          ),
        );
        return;
      }

      final success = await _premiumRepository.startTrial();

      if (success) {
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
      final plans = await _premiumRepository.getAvailablePlans();

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
      final canAccess = await _premiumRepository.canAccessFeature(
        event.featureName,
      );

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
}
