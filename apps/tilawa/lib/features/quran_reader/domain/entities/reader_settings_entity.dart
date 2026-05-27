import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_settings_entity.freezed.dart';
part 'reader_settings_entity.g.dart';

/// Font type for Quran text display
enum QuranFontType { uthmani, indopak, simple }

/// Reading mode
enum ReadingMode { surah, page, juz }

/// Entity representing reader settings
@freezed
abstract class ReaderSettingsEntity with _$ReaderSettingsEntity {
  const factory ReaderSettingsEntity({
    @Default(24.0) double fontSize,
    @Default(1.8) double lineHeight,
    @Default(QuranFontType.uthmani) QuranFontType fontType,
    @Default(ReadingMode.surah) ReadingMode readingMode,
    @Default(true) bool showTranslation,
    @Default('en') String translationLanguage,
    @Default(false) bool showTransliteration,
    @Default(true) bool showAyahNumbers,
    @Default(false) bool nightMode,
    @Default(1.0) double translationFontSize,
    @Default(null) int? lastReadSurah,
    @Default(null) int? lastReadAyah,
    @Default(null) int? lastReadPage,
  }) = _ReaderSettingsEntity;
  const ReaderSettingsEntity._();

  factory ReaderSettingsEntity.fromJson(Map<String, dynamic> json) =>
      _$ReaderSettingsEntityFromJson(json);

  /// Get font family based on font type, or null to use the theme default.
  String? get fontFamily {
    switch (fontType) {
      case QuranFontType.uthmani:
        return 'KFGQPC Uthmanic Script HAFS';
      case QuranFontType.indopak:
        return 'Noto Nastaliq Urdu';
      case QuranFontType.simple:
        return null;
    }
  }
}

/// Extension for QuranFontType display names
extension QuranFontTypeExtension on QuranFontType {
  String get displayName {
    switch (this) {
      case QuranFontType.uthmani:
        return 'Uthmani';
      case QuranFontType.indopak:
        return 'IndoPak';
      case QuranFontType.simple:
        return 'Simple';
    }
  }

  String get displayNameAr {
    switch (this) {
      case QuranFontType.uthmani:
        return 'عثماني';
      case QuranFontType.indopak:
        return 'إندوباكي';
      case QuranFontType.simple:
        return 'بسيط';
    }
  }
}

/// Extension for ReadingMode display names
extension ReadingModeExtension on ReadingMode {
  String get displayName {
    switch (this) {
      case ReadingMode.surah:
        return 'Surah';
      case ReadingMode.page:
        return 'Page';
      case ReadingMode.juz:
        return 'Juz';
    }
  }

  String get displayNameAr {
    switch (this) {
      case ReadingMode.surah:
        return 'سورة';
      case ReadingMode.page:
        return 'صفحة';
      case ReadingMode.juz:
        return 'جزء';
    }
  }
}
