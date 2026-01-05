// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reciter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReciterModel _$ReciterModelFromJson(Map<String, dynamic> json) =>
    _ReciterModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      letter: json['letter'] as String,
      date: json['date'] as String,
      moshaf: (json['moshaf'] as List<dynamic>)
          .map((e) => MoshafModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReciterModelToJson(_ReciterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'letter': instance.letter,
      'date': instance.date,
      'moshaf': instance.moshaf.map((e) => e.toJson()).toList(),
    };

_MoshafModel _$MoshafModelFromJson(Map<String, dynamic> json) => _MoshafModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  server: json['server'] as String,
  surahTotal: (json['surah_total'] as num).toInt(),
  moshafType: (json['moshaf_type'] as num).toInt(),
  surahList: json['surah_list'] as String,
);

Map<String, dynamic> _$MoshafModelToJson(_MoshafModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'server': instance.server,
      'surah_total': instance.surahTotal,
      'moshaf_type': instance.moshafType,
      'surah_list': instance.surahList,
    };

// **************************************************************************
// MapperGenerator
// **************************************************************************

extension ReciterModelToReciterEntityMapper on ReciterModel {
  ReciterEntity toReciterEntity() {
    return ReciterEntity(
      id: id,
      name: name,
      letter: letter,
      date: date,
      moshaf: moshaf.map((e) => e.toMoshafEntity()).toList(),
    );
  }
}

extension ReciterEntityToReciterModelMapper on ReciterEntity {
  ReciterModel toReciterModel() {
    return ReciterModel(
      id: id,
      name: name,
      letter: letter,
      date: date,
      moshaf: moshaf.map((e) => e.toMoshafModel()).toList(),
    );
  }
}

extension MoshafModelToMoshafEntityMapper on MoshafModel {
  MoshafEntity toMoshafEntity() {
    return MoshafEntity(
      id: id,
      name: name,
      server: server,
      surahTotal: surahTotal,
      moshafType: moshafType,
      surahList: surahList,
    );
  }
}

extension MoshafEntityToMoshafModelMapper on MoshafEntity {
  MoshafModel toMoshafModel() {
    return MoshafModel(
      id: id,
      name: name,
      server: server,
      surahTotal: surahTotal,
      moshafType: moshafType,
      surahList: surahList,
    );
  }
}
