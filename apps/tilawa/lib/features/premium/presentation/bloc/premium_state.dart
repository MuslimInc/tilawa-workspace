import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/entities/subscription_plan.dart';

part 'premium_state.freezed.dart';

@freezed
class PremiumState with _$PremiumState {
  const factory PremiumState.initial() = PremiumInitial;
  const factory PremiumState.loading() = PremiumLoading;
  const factory PremiumState.loaded({
    required PremiumStatus status,
    required List<SubscriptionPlan> availablePlans,
    required bool canDownload,
  }) = PremiumLoaded;
  const factory PremiumState.error({required String message}) = PremiumError;
  const factory PremiumState.purchaseSuccess({required String message}) =
      PremiumPurchaseSuccess;
  const factory PremiumState.purchaseFailed({required String message}) =
      PremiumPurchaseFailed;
  const factory PremiumState.trialStarted({required String message}) =
      PremiumTrialStarted;
  const factory PremiumState.trialNotEligible({required String message}) =
      PremiumTrialNotEligible;
}
