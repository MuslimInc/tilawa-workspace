import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';
import 'package:tilawa_core/utils/surah_names.dart';

part 'surah_entity.freezed.dart';
part 'surah_entity.g.dart';

@freezed
abstract class SurahEntity with _$SurahEntity {
  const factory SurahEntity({
    required AudioEntity audio,
    @Default(false) bool isDownloaded,
    @Default(false) bool isDownloading,
    @Default(0.0) double downloadProgress, // 0.0 to 1.0
    String? downloadId,
  }) = _SurahEntity;

  const SurahEntity._();

  factory SurahEntity.fromJson(Map<String, dynamic> json) =>
      _$SurahEntityFromJson(json);

  /// Audio URL used as the download key and playback identity.
  String get id => audio.id;

  /// Locale-aware surah title from the audio metadata (player display).
  String get name => audio.title;

  /// English transliteration when [surahNumber] is known.
  String get nameEn {
    final int? number = surahNumber;
    if (number != null) {
      return SurahNames.getEnglishSurahName(number);
    }
    return audio.title;
  }

  /// Arabic surah title when [surahNumber] is known.
  String get nameAr {
    final int? number = surahNumber;
    if (number != null) {
      return SurahNames.getArabicSurahName(number);
    }
    final String? stored = audio.extras.getString(AudioExtrasKeys.nameAr);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return '';
  }

  /// Reciter display name — sourced from [AudioEntity.artist] for downloads.
  String get reciterName => audio.artist ?? '';

  /// Padded surah index derived from the audio id (e.g. `001`).
  String get formattedId {
    try {
      final String basename = id.split('/').last.split('.').first;
      final int? num = int.tryParse(basename);
      if (num != null) {
        return basename.padLeft(3, '0');
      }
    } catch (_) {}
    return '';
  }

  /// Surah number from [AudioEntity.extras] or a numeric audio id basename.
  int? get surahNumber {
    final int? storedSurahNumber = audio.extras.getInt(
      AudioExtrasKeys.surahId,
    );
    if (storedSurahNumber != null) {
      return storedSurahNumber;
    }
    final String padded = formattedId;
    if (padded.isEmpty) {
      return null;
    }
    return int.tryParse(padded);
  }
}
