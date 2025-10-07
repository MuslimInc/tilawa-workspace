// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'premium_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PremiumStatus _$PremiumStatusFromJson(Map<String, dynamic> json) =>
    _PremiumStatus(
      isPremium: json['isPremium'] as bool,
      subscriptionStartDate: json['subscriptionStartDate'] == null
          ? null
          : DateTime.parse(json['subscriptionStartDate'] as String),
      subscriptionEndDate: json['subscriptionEndDate'] == null
          ? null
          : DateTime.parse(json['subscriptionEndDate'] as String),
      subscriptionType: json['subscriptionType'] as String?,
      isTrialUsed: json['isTrialUsed'] as bool,
      trialStartDate: json['trialStartDate'] == null
          ? null
          : DateTime.parse(json['trialStartDate'] as String),
      trialEndDate: json['trialEndDate'] == null
          ? null
          : DateTime.parse(json['trialEndDate'] as String),
    );

Map<String, dynamic> _$PremiumStatusToJson(
  _PremiumStatus instance,
) => <String, dynamic>{
  'isPremium': instance.isPremium,
  'subscriptionStartDate': instance.subscriptionStartDate?.toIso8601String(),
  'subscriptionEndDate': instance.subscriptionEndDate?.toIso8601String(),
  'subscriptionType': instance.subscriptionType,
  'isTrialUsed': instance.isTrialUsed,
  'trialStartDate': instance.trialStartDate?.toIso8601String(),
  'trialEndDate': instance.trialEndDate?.toIso8601String(),
};
