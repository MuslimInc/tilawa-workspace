import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:muzakri/core/config/currency_config.dart';

part 'subscription_plan.freezed.dart';
part 'subscription_plan.g.dart';

enum SubscriptionType { monthly, yearly, lifetime }

@freezed
abstract class SubscriptionPlan with _$SubscriptionPlan {
  const factory SubscriptionPlan({
    required String id,
    required String name,
    required String description,
    required double price,
    required String currency,
    required SubscriptionType type,
    required int durationInDays,
    required List<String> features,
    required bool isPopular,
    required double? discountPercentage,
    @Default(0) int order,
  }) = _SubscriptionPlan;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);
}

extension SubscriptionPlanExtension on SubscriptionPlan {
  String get formattedPrice {
    return CurrencyConfig.getCurrencyDisplay(price);
  }

  String get durationText {
    switch (type) {
      case SubscriptionType.monthly:
        return '1 Month';
      case SubscriptionType.yearly:
        return '1 Year';
      case SubscriptionType.lifetime:
        return 'Lifetime';
    }
  }

  String get discountText {
    if (discountPercentage != null && discountPercentage! > 0) {
      return '${discountPercentage!.toInt()}% OFF';
    }
    return '';
  }
}
