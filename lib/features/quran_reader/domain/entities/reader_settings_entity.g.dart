// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_settings_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReaderSettingsEntity _$ReaderSettingsEntityFromJson(
  Map<String, dynamic> json,
) => _ReaderSettingsEntity(
  fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
  lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.8,
  fontType:
      $enumDecodeNullable(_$QuranFontTypeEnumMap, json['fontType']) ??
      QuranFontType.uthmani,
  readingMode:
      $enumDecodeNullable(_$ReadingModeEnumMap, json['readingMode']) ??
      ReadingMode.surah,
  showTranslation: json['showTranslation'] as bool? ?? true,
  translationLanguage: json['translationLanguage'] as String? ?? 'en',
  showTransliteration: json['showTransliteration'] as bool? ?? false,
  showAyahNumbers: json['showAyahNumbers'] as bool? ?? true,
  nightMode: json['nightMode'] as bool? ?? false,
  translationFontSize: (json['translationFontSize'] as num?)?.toDouble() ?? 1.0,
  lastReadSurah: (json['lastReadSurah'] as num?)?.toInt() ?? null,
  lastReadAyah: (json['lastReadAyah'] as num?)?.toInt() ?? null,
  lastReadPage: (json['lastReadPage'] as num?)?.toInt() ?? null,
);

Map<String, dynamic> _$ReaderSettingsEntityToJson(
  _ReaderSettingsEntity instance,
) => <String, dynamic>{
  'fontSize': instance.fontSize,
  'lineHeight': instance.lineHeight,
  'fontType': _$QuranFontTypeEnumMap[instance.fontType]!,
  'readingMode': _$ReadingModeEnumMap[instance.readingMode]!,
  'showTranslation': instance.showTranslation,
  'translationLanguage': instance.translationLanguage,
  'showTransliteration': instance.showTransliteration,
  'showAyahNumbers': instance.showAyahNumbers,
  'nightMode': instance.nightMode,
  'translationFontSize': instance.translationFontSize,
  'lastReadSurah': instance.lastReadSurah,
  'lastReadAyah': instance.lastReadAyah,
  'lastReadPage': instance.lastReadPage,
};

const _$QuranFontTypeEnumMap = {
  QuranFontType.uthmani: 'uthmani',
  QuranFontType.indopak: 'indopak',
  QuranFontType.simple: 'simple',
};

const _$ReadingModeEnumMap = {
  ReadingMode.surah: 'surah',
  ReadingMode.page: 'page',
  ReadingMode.juz: 'juz',
};
