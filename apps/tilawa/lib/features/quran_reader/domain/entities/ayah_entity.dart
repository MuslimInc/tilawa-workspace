import 'package:freezed_annotation/freezed_annotation.dart';

part 'ayah_entity.freezed.dart';
part 'ayah_entity.g.dart';

/// Entity representing a single ayah (verse) of the Quran
@freezed
abstract class AyahEntity with _$AyahEntity {
  const factory AyahEntity({
    required int number,
    required int numberInSurah,
    required int surahNumber,
    required String text,
    String? textUthmani,
    String? textSimple,
    String? translation,
    String? transliteration,
    int? juz,
    int? manzil,
    int? page,
    int? ruku,
    int? hizbQuarter,
    bool? sajda,
  }) = _AyahEntity;
  const AyahEntity._();

  factory AyahEntity.fromJson(Map<String, dynamic> json) =>
      _$AyahEntityFromJson(json);

  /// Get ayah number display format (Arabic numerals)
  String get arabicNumber {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return numberInSurah
        .toString()
        .split('')
        .map((d) => arabicNumerals[int.parse(d)])
        .join();
  }

  /// Get formatted ayah number with Quran number brackets
  String get formattedNumber => '﴿$arabicNumber﴾';

  /// Check if this is the first ayah of a surah (excluding Al-Fatiha and At-Tawba)
  bool get hasBasmala =>
      numberInSurah == 1 && surahNumber != 1 && surahNumber != 9;
}

/// Entity representing the Basmala
class BasmalaEntity {
  static const String text = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';
  static const String translation =
      'In the name of Allah, the Most Gracious, the Most Merciful';
}
