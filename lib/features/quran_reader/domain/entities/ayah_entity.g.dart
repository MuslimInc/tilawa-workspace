// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ayah_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AyahEntity _$AyahEntityFromJson(Map<String, dynamic> json) => _AyahEntity(
  number: (json['number'] as num).toInt(),
  numberInSurah: (json['numberInSurah'] as num).toInt(),
  surahNumber: (json['surahNumber'] as num).toInt(),
  text: json['text'] as String,
  textUthmani: json['textUthmani'] as String?,
  textSimple: json['textSimple'] as String?,
  translation: json['translation'] as String?,
  transliteration: json['transliteration'] as String?,
  juz: (json['juz'] as num?)?.toInt(),
  manzil: (json['manzil'] as num?)?.toInt(),
  page: (json['page'] as num?)?.toInt(),
  ruku: (json['ruku'] as num?)?.toInt(),
  hizbQuarter: (json['hizbQuarter'] as num?)?.toInt(),
  sajda: json['sajda'] as bool?,
);

Map<String, dynamic> _$AyahEntityToJson(_AyahEntity instance) =>
    <String, dynamic>{
      'number': instance.number,
      'numberInSurah': instance.numberInSurah,
      'surahNumber': instance.surahNumber,
      'text': instance.text,
      'textUthmani': instance.textUthmani,
      'textSimple': instance.textSimple,
      'translation': instance.translation,
      'transliteration': instance.transliteration,
      'juz': instance.juz,
      'manzil': instance.manzil,
      'page': instance.page,
      'ruku': instance.ruku,
      'hizbQuarter': instance.hizbQuarter,
      'sajda': instance.sajda,
    };
