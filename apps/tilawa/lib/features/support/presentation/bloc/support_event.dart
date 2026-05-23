import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_event.freezed.dart';

@freezed
class SupportEvent with _$SupportEvent {
  const factory SupportEvent.started() = SupportStarted;
  const factory SupportEvent.tierSelected(String productId) =
      SupportTierSelected;
  const factory SupportEvent.continuePressed() = SupportContinuePressed;
  const factory SupportEvent.purchaseConfirmed() = SupportPurchaseConfirmed;
  const factory SupportEvent.purchaseDismissed() = SupportPurchaseDismissed;
  const factory SupportEvent.restoreRequested() = SupportRestoreRequested;
  const factory SupportEvent.thankYouDismissed() = SupportThankYouDismissed;
  const factory SupportEvent.appResumed() = SupportAppResumed;
}
