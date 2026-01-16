import 'package:freezed_annotation/freezed_annotation.dart';

part 'premium_event.freezed.dart';

@freezed
class PremiumEvent with _$PremiumEvent {
  const factory PremiumEvent.loadPremiumStatus() = LoadPremiumStatus;
  const factory PremiumEvent.purchaseSubscription({required String planId}) =
      PurchaseSubscription;
  const factory PremiumEvent.cancelSubscription() = CancelSubscription;
  const factory PremiumEvent.restoreSubscription() = RestoreSubscription;
  const factory PremiumEvent.startTrial() = StartTrial;
  const factory PremiumEvent.loadAvailablePlans() = LoadAvailablePlans;
  const factory PremiumEvent.checkFeatureAccess({required String featureName}) =
      CheckFeatureAccess;
  const factory PremiumEvent.refreshPremiumStatus() = RefreshPremiumStatus;
}
