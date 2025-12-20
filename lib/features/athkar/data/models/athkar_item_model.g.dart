// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'athkar_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AthkarItemModel _$AthkarItemModelFromJson(Map<String, dynamic> json) =>
    _AthkarItemModel(
      id: (json['id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      textAr: json['text_ar'] as String,
      textEn: json['text_en'] as String,
      count: (json['count'] as num).toInt(),
      reference: json['reference'] as String,
    );

Map<String, dynamic> _$AthkarItemModelToJson(_AthkarItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category_id': instance.categoryId,
      'text_ar': instance.textAr,
      'text_en': instance.textEn,
      'count': instance.count,
      'reference': instance.reference,
    };
