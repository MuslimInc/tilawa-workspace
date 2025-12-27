// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reciter_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReciterEntity _$ReciterEntityFromJson(Map<String, dynamic> json) =>
    _ReciterEntity(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      letter: json['letter'] as String,
      date: json['date'] as String,
      moshaf: (json['moshaf'] as List<dynamic>)
          .map((e) => MoshafEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReciterEntityToJson(_ReciterEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'letter': instance.letter,
      'date': instance.date,
      'moshaf': instance.moshaf.map((e) => e.toJson()).toList(),
    };
