import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests that validate [quran_page_index.json] and [quran_page_line_map.json]
/// against the King Fahd Quran Complex (KFGQPC) Mushaf 1439 AH layout.
///
/// These files drive the 15-line grid rendering of QCF v4 page fonts.
/// Any incorrect line assignment will cause glyphs to render on the wrong row
/// because each QCF page font positions glyphs according to their line slot.
void main() {
  late Map<String, dynamic> pageIndex;
  late Map<String, dynamic> lineMap;
  late Map<String, dynamic> qpcV4;

  setUpAll(() async {
    final base = File('assets/quran_fonts/qpc-v4.json').existsSync()
        ? 'assets/quran_fonts'
        : 'packages/quran/assets/quran_fonts';

    pageIndex = json.decode(
      File('$base/quran_page_index.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    qpcV4 = json.decode(
      File('$base/qpc-v4.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final String lineMapRaw = File(
      '$base/quran_page_line_map.json',
    ).readAsStringSync();
    lineMap = json.decode(lineMapRaw) as Map<String, dynamic>;
  });

  // ---------------------------------------------------------------------------
  // Structural integrity of quran_page_index.json
  // ---------------------------------------------------------------------------
  group('quran_page_index.json structure', () {
    test('contains all 604 pages', () {
      for (var page = 1; page <= 604; page++) {
        expect(
          pageIndex.containsKey('$page'),
          isTrue,
          reason: 'Missing page $page',
        );
      }
    });

    test('every page has exactly 15 line entries', () {
      for (var page = 1; page <= 604; page++) {
        final lines = pageIndex['$page'] as Map<String, dynamic>;
        for (var line = 1; line <= 15; line++) {
          expect(
            lines.containsKey('$line'),
            isTrue,
            reason: 'Page $page missing line $line',
          );
        }
      }
    });

    test('no line number exceeds 15 or is less than 1', () {
      for (final MapEntry<String, dynamic> pageEntry in pageIndex.entries) {
        final lines = pageEntry.value as Map<String, dynamic>;
        for (final String lineKey in lines.keys) {
          final int lineNum = int.parse(lineKey);
          expect(
            lineNum >= 1 && lineNum <= 15,
            isTrue,
            reason: 'Page ${pageEntry.key} has invalid line $lineNum',
          );
        }
      }
    });

    test('word keys in page index are valid references to qpc-v4.json', () {
      var checkedCount = 0;
      for (final MapEntry<String, dynamic> pageEntry in pageIndex.entries) {
        final lines = pageEntry.value as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> lineEntry in lines.entries) {
          final words = lineEntry.value as List<dynamic>;
          for (final dynamic wordKey in words) {
            expect(
              qpcV4.containsKey(wordKey),
              isTrue,
              reason:
                  'Page ${pageEntry.key} line ${lineEntry.key}: '
                  'word key "$wordKey" not found in qpc-v4.json',
            );
            checkedCount++;
          }
        }
      }
      expect(checkedCount, greaterThan(80000));
    });

    test('every qpc-v4 word appears exactly once in page index', () {
      final Set<String> indexedKeys = {};
      for (final MapEntry<String, dynamic> pageEntry in pageIndex.entries) {
        final lines = pageEntry.value as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> lineEntry in lines.entries) {
          final words = lineEntry.value as List<dynamic>;
          for (final dynamic wordKey in words) {
            expect(
              indexedKeys.add(wordKey as String),
              isTrue,
              reason:
                  'Duplicate word key "$wordKey" on page ${pageEntry.key} '
                  'line ${lineEntry.key}',
            );
          }
        }
      }
      final Set<String> missing = qpcV4.keys.toSet().difference(indexedKeys);
      expect(
        missing,
        isEmpty,
        reason: 'Words missing from page index: $missing',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Structural integrity of quran_page_line_map.json
  // ---------------------------------------------------------------------------
  group('quran_page_line_map.json structure', () {
    test('contains every qpc-v4 word key', () {
      for (final String key in qpcV4.keys) {
        expect(
          lineMap.containsKey(key),
          isTrue,
          reason: 'Missing line map entry for "$key"',
        );
      }
    });

    test('every entry has valid page (1-604) and line (1-15)', () {
      for (final MapEntry<String, dynamic> entry in lineMap.entries) {
        final info = entry.value as Map<String, dynamic>;
        final page = info['p'] as int;
        final line = info['l'] as int;
        expect(
          page >= 1 && page <= 604,
          isTrue,
          reason: '${entry.key}: invalid page $page',
        );
        expect(
          line >= 1 && line <= 15,
          isTrue,
          reason: '${entry.key}: invalid line $line',
        );
      }
    });

    test('line map and page index are consistent', () {
      for (final MapEntry<String, dynamic> entry in lineMap.entries) {
        final String key = entry.key;
        final info = entry.value as Map<String, dynamic>;
        final page = info['p'] as int;
        final line = info['l'] as int;

        final pageLines = pageIndex['$page'] as Map<String, dynamic>;
        final List<String> wordsOnLine = (pageLines['$line'] as List<dynamic>)
            .cast<String>();
        expect(
          wordsOnLine.contains(key),
          isTrue,
          reason:
              '"$key" is mapped to page $page line $line in line_map, '
              'but not found on that line in page_index',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Word ordering within lines
  // ---------------------------------------------------------------------------
  group('word ordering', () {
    test('words within each line are ordered by surah, ayah, position', () {
      for (final MapEntry<String, dynamic> pageEntry in pageIndex.entries) {
        final lines = pageEntry.value as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> lineEntry in lines.entries) {
          final List<String> words = (lineEntry.value as List<dynamic>)
              .cast<String>();
          if (words.length < 2) continue;

          for (var i = 0; i < words.length - 1; i++) {
            final List<int> curr = words[i].split(':').map(int.parse).toList();
            final List<int> next = words[i + 1]
                .split(':')
                .map(int.parse)
                .toList();

            final int cmp = curr[0] != next[0]
                ? curr[0].compareTo(next[0])
                : curr[1] != next[1]
                ? curr[1].compareTo(next[1])
                : curr[2].compareTo(next[2]);

            expect(
              cmp < 0,
              isTrue,
              reason:
                  'Page ${pageEntry.key} line ${lineEntry.key}: '
                  '"${words[i]}" should come before "${words[i + 1]}"',
            );
          }
        }
      }
    });

    test('words across lines on a page are in sequential order', () {
      for (final MapEntry<String, dynamic> pageEntry in pageIndex.entries) {
        final lines = pageEntry.value as Map<String, dynamic>;
        String? prevKey;
        for (var line = 1; line <= 15; line++) {
          final List<String> words = (lines['$line'] as List<dynamic>)
              .cast<String>();
          for (final wordKey in words) {
            if (prevKey != null) {
              final List<int> prev = prevKey.split(':').map(int.parse).toList();
              final List<int> curr = wordKey.split(':').map(int.parse).toList();
              final int cmp = prev[0] != curr[0]
                  ? prev[0].compareTo(curr[0])
                  : prev[1] != curr[1]
                  ? prev[1].compareTo(curr[1])
                  : prev[2].compareTo(curr[2]);
              expect(
                cmp < 0,
                isTrue,
                reason:
                    'Page ${pageEntry.key}: "$prevKey" should come before '
                    '"$wordKey" across lines',
              );
            }
            prevKey = wordKey;
          }
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Page 207 — the original bug fix page (end of At-Tawbah)
  // ---------------------------------------------------------------------------
  group('page 207 (end of At-Tawbah)', () {
    test('has 15 lines with content on all of them', () {
      final lines = pageIndex['207'] as Map<String, dynamic>;
      for (var line = 1; line <= 15; line++) {
        final words = lines['$line'] as List<dynamic>;
        expect(
          words.isNotEmpty,
          isTrue,
          reason: 'Page 207 line $line should have content',
        );
      }
    });

    test('line 1 has 7 words starting with 9:123:1', () {
      final List<String> line1 = (pageIndex['207']['1'] as List<dynamic>)
          .cast<String>();
      expect(line1.length, 7);
      expect(line1.first, '9:123:1');
      expect(line1.last, '9:123:7');
    });

    test('line 15 has 9 words ending with 9:129:16', () {
      final List<String> line15 = (pageIndex['207']['15'] as List<dynamic>)
          .cast<String>();
      expect(line15.length, 9);
      expect(line15.first, '9:129:8');
      expect(line15.last, '9:129:16');
    });

    test('total word count is 119', () {
      final lines = pageIndex['207'] as Map<String, dynamic>;
      var total = 0;
      for (final dynamic lineEntry in lines.values) {
        total += (lineEntry as List<dynamic>).length;
      }
      expect(total, 119);
    });

    test('contains only surah 9 (At-Tawbah) verses 123-129', () {
      final lines = pageIndex['207'] as Map<String, dynamic>;
      for (final dynamic lineEntry in lines.values) {
        for (final dynamic wordKey in lineEntry as List<dynamic>) {
          final List<String> parts = (wordKey as String).split(':');
          expect(parts[0], '9', reason: 'All words should be surah 9');
          final int ayah = int.parse(parts[1]);
          expect(
            ayah >= 123 && ayah <= 129,
            isTrue,
            reason: 'Ayah $ayah out of expected range 123-129',
          );
        }
      }
    });

    test('word distribution per line matches King Fahd mushaf', () {
      // Verified against The_Holy_Quran.db mushaf_id=2 (1439 AH edition).
      const expectedWordCounts = <int, int>{
        1: 7,
        2: 7,
        3: 9,
        4: 7,
        5: 6,
        6: 8,
        7: 7,
        8: 9,
        9: 9,
        10: 8,
        11: 8,
        12: 8,
        13: 7,
        14: 10,
        15: 9,
      };
      final lines = pageIndex['207'] as Map<String, dynamic>;
      for (final MapEntry<int, int> entry in expectedWordCounts.entries) {
        final words = lines['${entry.key}'] as List<dynamic>;
        expect(
          words.length,
          entry.value,
          reason:
              'Page 207 line ${entry.key}: expected ${entry.value} words, '
              'got ${words.length}',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Page 3 — first standard 15-line page
  // ---------------------------------------------------------------------------
  group('page 3 (first standard page)', () {
    test('all 15 lines have content', () {
      final lines = pageIndex['3'] as Map<String, dynamic>;
      for (var line = 1; line <= 15; line++) {
        expect(
          (lines['$line'] as List<dynamic>).isNotEmpty,
          isTrue,
          reason: 'Page 3 line $line should have content',
        );
      }
    });

    test('total word count is 138', () {
      final lines = pageIndex['3'] as Map<String, dynamic>;
      var total = 0;
      for (final dynamic lineEntry in lines.values) {
        total += (lineEntry as List<dynamic>).length;
      }
      expect(total, 138);
    });

    test('line 1 starts with 2:6:1', () {
      final List<String> line1 = (pageIndex['3']['1'] as List<dynamic>)
          .cast<String>();
      expect(line1.first, '2:6:1');
    });
  });

  // ---------------------------------------------------------------------------
  // Pages 1-2 — special Al-Fatiha / Al-Baqarah opening layout
  // ---------------------------------------------------------------------------
  group('pages 1-2 (special layout)', () {
    test('page 1: lines 1 and 9-15 are empty', () {
      final lines = pageIndex['1'] as Map<String, dynamic>;
      for (final emptyLine in [1, 9, 10, 11, 12, 13, 14, 15]) {
        expect(
          (lines['$emptyLine'] as List<dynamic>).isEmpty,
          isTrue,
          reason: 'Page 1 line $emptyLine should be empty',
        );
      }
    });

    test('page 1: lines 2-8 contain Al-Fatiha', () {
      final lines = pageIndex['1'] as Map<String, dynamic>;
      for (var line = 2; line <= 8; line++) {
        final words = lines['$line'] as List<dynamic>;
        expect(
          words.isNotEmpty,
          isTrue,
          reason: 'Page 1 line $line should have content',
        );
        for (final dynamic wordKey in words) {
          expect(
            (wordKey as String).startsWith('1:'),
            isTrue,
            reason: 'Page 1 should only contain surah 1',
          );
        }
      }
    });

    test('page 2: first content starts at line 3', () {
      final lines = pageIndex['2'] as Map<String, dynamic>;
      expect((lines['1'] as List<dynamic>).isEmpty, isTrue);
      expect((lines['2'] as List<dynamic>).isEmpty, isTrue);
      expect((lines['3'] as List<dynamic>).isNotEmpty, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Page 77 — An-Nisa starts (surah header + bismillah on lines 1-2)
  // ---------------------------------------------------------------------------
  group('page 77 (An-Nisa start)', () {
    test('lines 1-2 are empty (reserved for header and bismillah)', () {
      final lines = pageIndex['77'] as Map<String, dynamic>;
      expect(
        (lines['1'] as List<dynamic>).isEmpty,
        isTrue,
        reason: 'Line 1 should be empty (surah header)',
      );
      expect(
        (lines['2'] as List<dynamic>).isEmpty,
        isTrue,
        reason: 'Line 2 should be empty (bismillah)',
      );
    });

    test('content starts at line 3 with surah 4 (An-Nisa)', () {
      final List<String> line3 = (pageIndex['77']['3'] as List<dynamic>)
          .cast<String>();
      expect(line3.isNotEmpty, isTrue);
      expect(line3.first.startsWith('4:'), isTrue);
    });

    test('all content is surah 4', () {
      final lines = pageIndex['77'] as Map<String, dynamic>;
      for (var line = 3; line <= 15; line++) {
        final List<String> words = (lines['$line'] as List<dynamic>)
            .cast<String>();
        for (final wordKey in words) {
          expect(
            wordKey.startsWith('4:'),
            isTrue,
            reason: 'Page 77 line $line: expected surah 4, got "$wordKey"',
          );
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Page 187 — At-Tawbah starts (header only, NO bismillah)
  // ---------------------------------------------------------------------------
  group('page 187 (At-Tawbah start, no bismillah)', () {
    test('line 1 is empty (reserved for surah header)', () {
      final lines = pageIndex['187'] as Map<String, dynamic>;
      expect((lines['1'] as List<dynamic>).isEmpty, isTrue);
    });

    test('content starts at line 2 with surah 9', () {
      final List<String> line2 = (pageIndex['187']['2'] as List<dynamic>)
          .cast<String>();
      expect(line2.isNotEmpty, isTrue);
      expect(line2.first, '9:1:1');
    });
  });

  // ---------------------------------------------------------------------------
  // Page 604 — last page (Al-Ikhlas, Al-Falaq, An-Nas)
  // ---------------------------------------------------------------------------
  group('page 604 (last page)', () {
    test('contains surahs 112, 113, and 114', () {
      final lines = pageIndex['604'] as Map<String, dynamic>;
      final Set<int> surahs = {};
      for (final dynamic lineEntry in lines.values) {
        for (final dynamic wordKey in lineEntry as List<dynamic>) {
          surahs.add(int.parse((wordKey as String).split(':')[0]));
        }
      }
      expect(surahs, containsAll([112, 113, 114]));
    });

    test('total word count is 73', () {
      final lines = pageIndex['604'] as Map<String, dynamic>;
      var total = 0;
      for (final dynamic lineEntry in lines.values) {
        total += (lineEntry as List<dynamic>).length;
      }
      expect(total, 73);
    });

    test('ends with surah 114 (An-Nas)', () {
      final List<String> line15 = (pageIndex['604']['15'] as List<dynamic>)
          .cast<String>();
      expect(line15.isNotEmpty, isTrue);
      expect(line15.last.startsWith('114:'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Cross-page continuity — no gaps in the Quran text
  // ---------------------------------------------------------------------------
  group('cross-page continuity', () {
    test('all words across all pages form a continuous sequence', () {
      final List<String> allKeys = [];
      for (var page = 1; page <= 604; page++) {
        final lines = pageIndex['$page'] as Map<String, dynamic>;
        for (var line = 1; line <= 15; line++) {
          final List<String> words = (lines['$line'] as List<dynamic>)
              .cast<String>();
          allKeys.addAll(words);
        }
      }

      // Within each verse, word positions must be sequential (1, 2, 3, ...).
      final Map<String, int> lastWordPos = {};
      for (final key in allKeys) {
        final List<String> parts = key.split(':');
        final verseKey = '${parts[0]}:${parts[1]}';
        final int wordPos = int.parse(parts[2]);

        if (lastWordPos.containsKey(verseKey)) {
          expect(
            wordPos,
            lastWordPos[verseKey]! + 1,
            reason:
                'Gap in verse $verseKey: expected position '
                '${lastWordPos[verseKey]! + 1}, got $wordPos',
          );
        } else {
          expect(
            wordPos,
            1,
            reason: 'Verse $verseKey should start at position 1, got $wordPos',
          );
        }
        lastWordPos[verseKey] = wordPos;
      }
    });

    test('first word of Quran is 1:1:1 on page 1', () {
      final lines = pageIndex['1'] as Map<String, dynamic>;
      for (var line = 1; line <= 15; line++) {
        final List<String> words = (lines['$line'] as List<dynamic>)
            .cast<String>();
        if (words.isNotEmpty) {
          expect(words.first, '1:1:1');
          break;
        }
      }
    });

    test('last word of Quran is on page 604 line 15', () {
      final List<String> line15 = (pageIndex['604']['15'] as List<dynamic>)
          .cast<String>();
      expect(line15.isNotEmpty, isTrue);
      final String lastKey = line15.last;
      expect(
        lastKey.startsWith('114:6:'),
        isTrue,
        reason: 'Last word should be in surah 114, ayah 6',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Pages that previously had only 14 lines (the original bug)
  // ---------------------------------------------------------------------------
  group('previously broken pages (14-line bug)', () {
    const affectedPages = <int>[
      76,
      207,
      331,
      341,
      349,
      366,
      376,
      414,
      417,
      445,
      452,
      498,
      506,
      525,
      548,
      555,
      557,
      584,
    ];

    for (final page in affectedPages) {
      test('page $page has content on line 15', () {
        final List<String> line15 = (pageIndex['$page']['15'] as List<dynamic>)
            .cast<String>();
        expect(
          line15.isNotEmpty,
          isTrue,
          reason: 'Page $page line 15 must not be empty',
        );
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Global invariants
  // ---------------------------------------------------------------------------
  group('global invariants', () {
    test('total glyph count matches qpc-v4.json', () {
      var pageIndexTotal = 0;
      for (final MapEntry<String, dynamic> pageEntry in pageIndex.entries) {
        final lines = pageEntry.value as Map<String, dynamic>;
        for (final dynamic lineEntry in lines.values) {
          pageIndexTotal += (lineEntry as List<dynamic>).length;
        }
      }
      expect(pageIndexTotal, qpcV4.length);
    });

    test('line map entry count matches qpc-v4.json', () {
      expect(lineMap.length, qpcV4.length);
    });

    test('pages 3-604 have at least 9 lines with content', () {
      for (var page = 3; page <= 604; page++) {
        final lines = pageIndex['$page'] as Map<String, dynamic>;
        var contentLines = 0;
        for (var line = 1; line <= 15; line++) {
          if ((lines['$line'] as List<dynamic>).isNotEmpty) {
            contentLines++;
          }
        }
        expect(
          contentLines >= 9,
          isTrue,
          reason: 'Page $page has only $contentLines content lines (min 9)',
        );
      }
    });

    test('no page has more than 190 words', () {
      for (var page = 1; page <= 604; page++) {
        final lines = pageIndex['$page'] as Map<String, dynamic>;
        var total = 0;
        for (final dynamic lineEntry in lines.values) {
          total += (lineEntry as List<dynamic>).length;
        }
        expect(
          total <= 190,
          isTrue,
          reason: 'Page $page has $total words (max expected ~190)',
        );
      }
    });

    test('surah:ayah metadata in qpc-v4 matches word key', () {
      for (final MapEntry<String, dynamic> entry in qpcV4.entries) {
        final List<String> parts = entry.key.split(':');
        final data = entry.value as Map<String, dynamic>;
        expect(data['surah'], parts[0], reason: '${entry.key}: surah mismatch');
        expect(data['ayah'], parts[1], reason: '${entry.key}: ayah mismatch');
      }
    });
  });
}
