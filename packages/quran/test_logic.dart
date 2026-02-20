import 'package:quran/src/services/functions/page_functions.dart';
import 'package:quran/src/services/functions/verse_functions.dart';

void main() {
  final List<Map<String, int>> ranges = getPageData(18);
  print('Ranges for page 18: $ranges');
  if (ranges.isNotEmpty) {
    final int surah = ranges[0]['surah']!;
    final int v = ranges[0]['start']!;
    String verseText = getVerseQCF(surah, v, verseEndSymbol: false);
    print('Original verseText: "$verseText" (length: ${verseText.length})');

    if (verseText.isNotEmpty) {
      if (verseText.length > 1 &&
          verseText[1] != ' ' &&
          verseText[1] != '\u2009') {
        verseText = '${verseText[0]}\u2009${verseText.substring(1)}';
        print('Inserted thin space at index 1');
      } else if (verseText.length == 1 &&
          verseText != ' ' &&
          verseText != '\u2009') {
        verseText = '$verseText\u2009';
        print('Appended thin space at end');
      } else {
        print(
          'No thin space inserted. Details: char[1] is "${verseText[1]}" (code: ${verseText.codeUnitAt(1)})',
        );
      }
      print('Modified verseText: "$verseText" (length: ${verseText.length})');
    }
  }
}
