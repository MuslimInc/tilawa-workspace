import 'package:freezed_annotation/freezed_annotation.dart';

part 'premium_status.freezed.dart';
part 'premium_status.g.dart';

@freezed
abstract class PremiumStatus with _$PremiumStatus {
  const factory PremiumStatus({
    required bool isPremium,
    required DateTime? subscriptionStartDate,
    required DateTime? subscriptionEndDate,
    required String? subscriptionType,
    required bool isTrialUsed,
    required DateTime? trialStartDate,
    required DateTime? trialEndDate,
  }) = _PremiumStatus;

  factory PremiumStatus.fromJson(Map<String, dynamic> json) =>
      _$PremiumStatusFromJson(json);

  const PremiumStatus._();

  bool get isSubscriptionActive {
    if (!isPremium) return false;
    if (subscriptionEndDate == null) return true;
    return DateTime.now().isBefore(subscriptionEndDate!);
  }

  bool get isTrialActive {
    if (isTrialUsed || trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  bool get canDownload {
    return isSubscriptionActive || isTrialActive;
  }

  int get daysRemaining {
    if (isSubscriptionActive && subscriptionEndDate != null) {
      return subscriptionEndDate!.difference(DateTime.now()).inDays;
    }
    if (isTrialActive && trialEndDate != null) {
      return trialEndDate!.difference(DateTime.now()).inDays;
    }
    return 0;
  }

  String get statusText {
    if (isSubscriptionActive) {
      return 'Premium Active';
    }
    if (isTrialActive) {
      return 'Trial Active';
    }
    return 'Free User';
  }
}
