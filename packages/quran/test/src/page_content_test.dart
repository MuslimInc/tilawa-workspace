import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/page_content.dart';

void main() {
  setUpAll(() {
    // Resolve asset base relative to the package root, regardless of CWD.
    final String base = File('assets/quran_fonts/qpc-v4.json').existsSync()
        ? 'assets/quran_fonts'
        : 'packages/quran/assets/quran_fonts';
    final String qpcRaw = File('$base/qpc-v4.json').readAsStringSync();
    final String pageIndexRaw = File(
      '$base/quran_page_index.json',
    ).readAsStringSync();
    final qpc = json.decode(qpcRaw) as Map<String, dynamic>;
    final pageIndexJson = json.decode(pageIndexRaw) as Map<String, dynamic>;

    final processedIndex = <int, List<List<Map<String, dynamic>>>>{};
    for (final MapEntry<String, dynamic> pageEntry in pageIndexJson.entries) {
      final int pageNum = int.parse(pageEntry.key);
      final lineMap = pageEntry.value as Map<String, dynamic>;
      final List<List<Map<String, dynamic>>> lines = List.generate(
        15,
        (_) => <Map<String, dynamic>>[],
      );
      for (final MapEntry<String, dynamic> lineEntry in lineMap.entries) {
        final int lineIndex = (int.parse(lineEntry.key) - 1).clamp(0, 14);
        final List<String> wordKeys = (lineEntry.value as List<dynamic>)
            .cast<String>();
        for (final key in wordKeys) {
          final wordData = qpc[key] as Map<String, dynamic>?;
          if (wordData != null) lines[lineIndex].add(wordData);
        }
      }
      processedIndex[pageNum] = lines;
    }
    preloadPageContentCache(qpc, processedIndex);
  });

  tearDownAll(() {
    clearPageContentCache();
  });

  group('PageContent First Word Spacing', () {
    testWidgets('Appends thin space to the first word if missing', (
      WidgetTester tester,
    ) async {
      // Pump the PageContent widget for page 18
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 18,
              textColor: Colors.black,
              onLongPress: (surah, verse) {},
              onLongPressUp: (surah, verse) {},
              onLongPressCancel: (surah, verse) {},
              onLongPressDown: (surah, verse, details) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the RichText widget inside PageContent
      final Finder richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      // Extract the TextSpan from the reader text
      final Iterable<RichText> richTexts = tester.widgetList<RichText>(
        richTextFinder,
      );

      var foundThinSpace = false;
      var firstVerseText = '';

      for (final richText in richTexts) {
        final String plainText = richText.text.toPlainText();
        // Since we are looking for the Quran verses on page 18, which start with ﱁ
        if (plainText.contains('ﱁ')) {
          firstVerseText = plainText;
          // The first word ﱁ should be followed by a hair space \u200A
          if (plainText.contains('ﱁ\u200A')) {
            foundThinSpace = true;
          }
          break;
        }
      }

      expect(
        firstVerseText,
        isNotEmpty,
        reason: 'Should find at least one verse text span',
      );
      expect(
        foundThinSpace,
        isTrue,
        reason:
            'The first word should be followed by a hair space (\\u200A)\nFound text: "$firstVerseText"',
      );
    });

    testWidgets(
      'Does not append thin space if it already exists or standard space exists',
      (WidgetTester tester) async {
        // This is harder to test directly without injecting specific verse data,
        // but we can at least assert that no double thin spaces occur on any page (e.g., page 1)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageContent(
                pageNumber: 1,
                textColor: Colors.black,
                onLongPress: (surah, verse) {},
                onLongPressUp: (surah, verse) {},
                onLongPressCancel: (surah, verse) {},
                onLongPressDown: (surah, verse, details) {},
              ),
            ),
          ),
        );
        await tester.pump();

        final Finder richTextFinder = find.byType(RichText);
        expect(richTextFinder, findsWidgets);

        final Iterable<RichText> richTexts = tester.widgetList<RichText>(
          richTextFinder,
        );

        for (final richText in richTexts) {
          final String plainText = richText.text.toPlainText();
          expect(
            plainText.contains(' \u200A'),
            isFalse,
            reason: 'Should not have both standard space and thin space',
          );
          expect(
            plainText.contains('\u200A '),
            isFalse,
            reason: 'Should not have both standard space and thin space',
          );
          expect(
            plainText.contains('\u200A\u200A'),
            isFalse,
            reason: 'Should not have double thin space',
          );
        }
      },
    );
  });
}
