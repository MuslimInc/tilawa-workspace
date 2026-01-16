// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moshaf_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoshafEntity _$MoshafEntityFromJson(Map<String, dynamic> json) => MoshafEntity(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  server: json['server'] as String,
  surahTotal: (json['surahTotal'] as num).toInt(),
  moshafType: (json['moshafType'] as num).toInt(),
  surahList: json['surahList'] as String,
);

Map<String, dynamic> _$MoshafEntityToJson(MoshafEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'server': instance.server,
      'surahTotal': instance.surahTotal,
      'moshafType': instance.moshafType,
      'surahList': instance.surahList,
    };
