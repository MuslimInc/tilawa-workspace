// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah_content_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SurahContentEntity _$SurahContentEntityFromJson(Map<String, dynamic> json) =>
    _SurahContentEntity(
      number: (json['number'] as num).toInt(),
      name: json['name'] as String,
      nameEnglish: json['nameEnglish'] as String,
      nameTranslation: json['nameTranslation'] as String,
      revelationType: json['revelationType'] as String,
      numberOfAyahs: (json['numberOfAyahs'] as num).toInt(),
      ayahs: (json['ayahs'] as List<dynamic>)
          .map((e) => AyahEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      startPage: (json['startPage'] as num?)?.toInt(),
      endPage: (json['endPage'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SurahContentEntityToJson(_SurahContentEntity instance) =>
    <String, dynamic>{
      'number': instance.number,
      'name': instance.name,
      'nameEnglish': instance.nameEnglish,
      'nameTranslation': instance.nameTranslation,
      'revelationType': instance.revelationType,
      'numberOfAyahs': instance.numberOfAyahs,
      'ayahs': instance.ayahs.map((e) => e.toJson()).toList(),
      'startPage': instance.startPage,
      'endPage': instance.endPage,
    };

_QuranPageEntity _$QuranPageEntityFromJson(Map<String, dynamic> json) =>
    _QuranPageEntity(
      pageNumber: (json['pageNumber'] as num).toInt(),
      ayahs: (json['ayahs'] as List<dynamic>)
          .map((e) => PageAyahInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      juz: (json['juz'] as num).toInt(),
      hizb: (json['hizb'] as num).toInt(),
    );

Map<String, dynamic> _$QuranPageEntityToJson(_QuranPageEntity instance) =>
    <String, dynamic>{
      'pageNumber': instance.pageNumber,
      'ayahs': instance.ayahs.map((e) => e.toJson()).toList(),
      'juz': instance.juz,
      'hizb': instance.hizb,
    };

_PageAyahInfo _$PageAyahInfoFromJson(Map<String, dynamic> json) =>
    _PageAyahInfo(
      surahNumber: (json['surahNumber'] as num).toInt(),
      surahName: json['surahName'] as String,
      surahNameEnglish: json['surahNameEnglish'] as String,
      ayahNumber: (json['ayahNumber'] as num).toInt(),
      text: json['text'] as String,
      words: (json['words'] as List<dynamic>?)
          ?.map((e) => QuranWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PageAyahInfoToJson(_PageAyahInfo instance) =>
    <String, dynamic>{
      'surahNumber': instance.surahNumber,
      'surahName': instance.surahName,
      'surahNameEnglish': instance.surahNameEnglish,
      'ayahNumber': instance.ayahNumber,
      'text': instance.text,
      'words': instance.words?.map((e) => e.toJson()).toList(),
    };

_QuranWord _$QuranWordFromJson(Map<String, dynamic> json) => _QuranWord(
  id: (json['id'] as num).toInt(),
  position: (json['position'] as num).toInt(),
  text: json['text'] as String,
  textUthmani: json['text_uthmani'] as String?,
  audioUrl: json['audio_url'] as String?,
  codeV1: json['code_v1'] as String?,
  charTypeName: json['char_type_name'] as String?,
  translation: json['translation'] == null
      ? null
      : WordTranslation.fromJson(json['translation'] as Map<String, dynamic>),
  transliteration: json['transliteration'] == null
      ? null
      : WordTransliteration.fromJson(
          json['transliteration'] as Map<String, dynamic>,
        ),
  renderedText: json['renderedText'] as String?,
  fontFamily: json['fontFamily'] as String?,
  lineHeight: (json['lineHeight'] as num?)?.toDouble(),
);

Map<String, dynamic> _$QuranWordToJson(_QuranWord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'position': instance.position,
      'text': instance.text,
      'text_uthmani': instance.textUthmani,
      'audio_url': instance.audioUrl,
      'code_v1': instance.codeV1,
      'char_type_name': instance.charTypeName,
      'translation': instance.translation?.toJson(),
      'transliteration': instance.transliteration?.toJson(),
      'renderedText': instance.renderedText,
      'fontFamily': instance.fontFamily,
      'lineHeight': instance.lineHeight,
    };

_WordTranslation _$WordTranslationFromJson(Map<String, dynamic> json) =>
    _WordTranslation(
      text: json['text'] as String,
      languageName: json['language_name'] as String?,
    );

Map<String, dynamic> _$WordTranslationToJson(_WordTranslation instance) =>
    <String, dynamic>{
      'text': instance.text,
      'language_name': instance.languageName,
    };

_WordTransliteration _$WordTransliterationFromJson(Map<String, dynamic> json) =>
    _WordTransliteration(
      text: json['text'] as String?,
      languageName: json['language_name'] as String?,
    );

Map<String, dynamic> _$WordTransliterationToJson(
  _WordTransliteration instance,
) => <String, dynamic>{
  'text': instance.text,
  'language_name': instance.languageName,
};
