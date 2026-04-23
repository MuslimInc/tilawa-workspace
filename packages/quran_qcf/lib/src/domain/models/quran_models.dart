import 'package:equatable/equatable.dart';

/// Represents a single word in the Quran Mushaf with its associated metadata.
class WordData extends Equatable {
  const WordData({
    required this.text,
    required this.surah,
    required this.ayah,
    required this.wordIndex,
    required this.page,
    required this.line,
    this.audio,
    this.charType,
  });

  factory WordData.fromMap(Map<String, dynamic> map) {
    return WordData(
      text: map['text'] as String,
      surah: int.tryParse(map['surah'].toString()) ?? 0,
      ayah: int.tryParse(map['ayah'].toString()) ?? 0,
      wordIndex: int.tryParse(map['word'].toString()) ?? 0,
      page: int.tryParse(map['page'].toString()) ?? 0,
      line: int.tryParse(map['line'].toString()) ?? 0,
      audio: map['audio']?.toString(),
      charType: map['char_type']?.toString(),
    );
  }

  /// The raw QCF character(s) representing this word.
  final String text;

  /// The surah number (1-114).
  final int surah;

  /// The ayah (verse) number within the surah.
  final int ayah;

  /// The index of the word within the ayah.
  final int wordIndex;

  /// The page number in the Mushaf (1-604).
  final int page;

  /// The line number on the page (1-15).
  final int line;

  /// Optional audio identifier for this word.
  final String? audio;

  /// Optional character type (e.g., word, end of verse).
  final String? charType;

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'surah': surah,
      'ayah': ayah,
      'word': wordIndex,
      'page': page,
      'line': line,
      'audio': audio,
      'char_type': charType,
    };
  }

  @override
  List<Object?> get props => [
    text,
    surah,
    ayah,
    wordIndex,
    page,
    line,
    audio,
    charType,
  ];
}

/// Metadata for a Quran page.
class PageMetadata extends Equatable {
  const PageMetadata({
    required this.surahNumbers,
    required this.hizb,
    required this.juz,
  });

  final List<int> surahNumbers;
  final int hizb;
  final int juz;

  @override
  List<Object?> get props => [surahNumbers, hizb, juz];
}

/// Represents a range of verses for a specific surah on a page.
class PageSurahEntry extends Equatable {
  const PageSurahEntry({
    required this.surah,
    required this.start,
    required this.end,
  });

  final int surah;
  final int start;
  final int end;

  @override
  List<Object?> get props => [surah, start, end];
}
