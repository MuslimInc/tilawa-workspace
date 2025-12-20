// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'athkar_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AthkarCategoryModel _$AthkarCategoryModelFromJson(Map<String, dynamic> json) =>
    _AthkarCategoryModel(
      id: (json['id'] as num).toInt(),
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      icon: json['icon'] as String,
    );

Map<String, dynamic> _$AthkarCategoryModelToJson(
  _AthkarCategoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name_ar': instance.nameAr,
  'name_en': instance.nameEn,
  'icon': instance.icon,
};
