import 'package:freezed_annotation/freezed_annotation.dart';

import 'ayah_entity.dart';

part 'surah_content_entity.freezed.dart';
part 'surah_content_entity.g.dart';

/// Entity representing a complete surah with all its ayahs
@freezed
abstract class SurahContentEntity with _$SurahContentEntity {
  const factory SurahContentEntity({
    required int number,
    required String name,
    required String nameEnglish,
    required String nameTranslation,
    required String revelationType,
    required int numberOfAyahs,
    required List<AyahEntity> ayahs,
    int? startPage,
    int? endPage,
  }) = _SurahContentEntity;
  const SurahContentEntity._();

  factory SurahContentEntity.fromJson(Map<String, dynamic> json) =>
      _$SurahContentEntityFromJson(json);

  /// Check if this is a Meccan surah
  bool get isMeccan => revelationType.toLowerCase() == 'meccan';

  /// Check if this is a Medinan surah
  bool get isMedinan => revelationType.toLowerCase() == 'medinan';

  /// Get ayah by number in surah
  AyahEntity? getAyahByNumber(int numberInSurah) {
    try {
      return ayahs.firstWhere((a) => a.numberInSurah == numberInSurah);
    } catch (e) {
      return null;
    }
  }
}

/// Entity representing a Quran page
@freezed
abstract class QuranPageEntity with _$QuranPageEntity {
  const factory QuranPageEntity({
    required int pageNumber,
    required List<PageAyahInfo> ayahs,
    required int juz,
    required int hizb,
  }) = _QuranPageEntity;
  const QuranPageEntity._();

  factory QuranPageEntity.fromJson(Map<String, dynamic> json) =>
      _$QuranPageEntityFromJson(json);
}

/// Information about an ayah on a page
@freezed
abstract class PageAyahInfo with _$PageAyahInfo {
  const factory PageAyahInfo({
    required int surahNumber,
    required String surahName,
    required String surahNameEnglish,
    required int ayahNumber,
    required String text,
    List<QuranWord>? words,
  }) = _PageAyahInfo;

  factory PageAyahInfo.fromJson(Map<String, dynamic> json) =>
      _$PageAyahInfoFromJson(json);
}

/// Entity representing a single word in an ayah
@freezed
abstract class QuranWord with _$QuranWord {
  const factory QuranWord({
    required int id,
    required int position,
    required String text,
    @JsonKey(name: 'text_uthmani') String? textUthmani,
    @JsonKey(name: 'audio_url') String? audioUrl,
    @JsonKey(name: 'code_v1') String? codeV1,
    @JsonKey(name: 'char_type_name') String? charTypeName,
    @JsonKey(name: 'translation') WordTranslation? translation,
    @JsonKey(name: 'transliteration') WordTransliteration? transliteration,
  }) = _QuranWord;

  factory QuranWord.fromJson(Map<String, dynamic> json) =>
      _$QuranWordFromJson(json);
}

@freezed
abstract class WordTranslation with _$WordTranslation {
  const factory WordTranslation({
    required String text,
    @JsonKey(name: 'language_name') String? languageName,
  }) = _WordTranslation;

  factory WordTranslation.fromJson(Map<String, dynamic> json) =>
      _$WordTranslationFromJson(json);
}

@freezed
abstract class WordTransliteration with _$WordTransliteration {
  const factory WordTransliteration({
    required String? text,
    @JsonKey(name: 'language_name') String? languageName,
  }) = _WordTransliteration;

  factory WordTransliteration.fromJson(Map<String, dynamic> json) =>
      _$WordTransliterationFromJson(json);
}
