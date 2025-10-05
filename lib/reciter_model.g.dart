// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reciter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Mosahf _$MosahfFromJson(Map<String, dynamic> json) => _Mosahf(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  server: json['server'] as String,
  surahTotal: (json['surah_total'] as num).toInt(),
  moshafType: (json['moshaf_type'] as num).toInt(),
  surahList: json['surah_list'] as String,
);

Map<String, dynamic> _$MosahfToJson(_Mosahf instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'server': instance.server,
  'surah_total': instance.surahTotal,
  'moshaf_type': instance.moshafType,
  'surah_list': instance.surahList,
};

_Reciter _$ReciterFromJson(Map<String, dynamic> json) => _Reciter(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  letter: json['letter'] as String,
  date: json['date'] as String,
  moshaf: (json['moshaf'] as List<dynamic>)
      .map((e) => Mosahf.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReciterToJson(_Reciter instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'letter': instance.letter,
  'date': instance.date,
  'moshaf': instance.moshaf.map((e) => e.toJson()).toList(),
};

_RecitersModel _$RecitersModelFromJson(Map<String, dynamic> json) =>
    _RecitersModel(
      reciters: (json['reciters'] as List<dynamic>)
          .map((e) => Reciter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecitersModelToJson(_RecitersModel instance) =>
    <String, dynamic>{
      'reciters': instance.reciters.map((e) => e.toJson()).toList(),
    };
