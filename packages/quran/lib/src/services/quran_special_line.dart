import 'package:flutter/foundation.dart';

enum QuranSpecialLineType { surahHeader, bismillah }

@immutable
class QuranSpecialLine {
  const QuranSpecialLine({required this.type, required this.surahNumber});

  const QuranSpecialLine.bismillah(int surahNumber)
    : this(type: QuranSpecialLineType.bismillah, surahNumber: surahNumber);

  const QuranSpecialLine.surahHeader(int surahNumber)
    : this(type: QuranSpecialLineType.surahHeader, surahNumber: surahNumber);

  final QuranSpecialLineType type;
  final int surahNumber;

  bool get isBismillah => type == QuranSpecialLineType.bismillah;
  bool get isSurahHeader => type == QuranSpecialLineType.surahHeader;
}

@immutable
class QuranSpecialLineCounts {
  const QuranSpecialLineCounts({
    required this.headers,
    required this.bismillahs,
  });

  final int headers;
  final int bismillahs;

  bool get hasSurahHeader => headers > 0;

  Map<String, int> toLegacyMap() {
    return <String, int>{'headers': headers, 'bismillahs': bismillahs};
  }
}
