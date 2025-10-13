// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    _SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      type: $enumDecode(_$SubscriptionTypeEnumMap, json['type']),
      durationInDays: (json['durationInDays'] as num).toInt(),
      features: (json['features'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isPopular: json['isPopular'] as bool,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SubscriptionPlanToJson(_SubscriptionPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'currency': instance.currency,
      'type': _$SubscriptionTypeEnumMap[instance.type]!,
      'durationInDays': instance.durationInDays,
      'features': instance.features,
      'isPopular': instance.isPopular,
      'discountPercentage': instance.discountPercentage,
      'order': instance.order,
    };

const _$SubscriptionTypeEnumMap = {
  SubscriptionType.monthly: 'monthly',
  SubscriptionType.yearly: 'yearly',
  SubscriptionType.lifetime: 'lifetime',
};
