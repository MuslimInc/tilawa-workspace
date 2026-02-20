import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/page_content.dart';

void main() {
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
        final textSpan = richText.text as TextSpan;
        if (textSpan.children != null) {
          for (final InlineSpan child in textSpan.children!) {
            if (child is TextSpan && child.text != null) {
              final String text = child.text!;
              print('Found span text: "$text"');
              // The first verse on page 18 should be surah 2, verse 113.
              // In qcf format, this is what we are looking for.
              if (text.trim().isNotEmpty && firstVerseText.isEmpty) {
                firstVerseText = text;
                // Check if the thin space \u2009 is present right after the first character
                if (text.length > 1 && text[1] == '\u2009') {
                  foundThinSpace = true;
                }
                break; // We only care about the very first TextSpan with text
              }
            }
          }
        }
        if (firstVerseText.isNotEmpty) break;
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
            'The first word should be followed by a thin space (\\u2009)\nFound text: "$firstVerseText"',
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

        final Finder richTextFinder = find.byType(RichText);
        expect(richTextFinder, findsWidgets);

        final Iterable<RichText> richTexts = tester.widgetList<RichText>(
          richTextFinder,
        );

        for (final richText in richTexts) {
          final textSpan = richText.text as TextSpan;
          if (textSpan.children != null) {
            for (final InlineSpan child in textSpan.children!) {
              if (child is TextSpan && child.text != null) {
                final String text = child.text!;
                expect(
                  text.contains(' \u2009'),
                  isFalse,
                  reason: 'Should not have both standard space and thin space',
                );
                expect(
                  text.contains('\u2009 '),
                  isFalse,
                  reason: 'Should not have both standard space and thin space',
                );
                expect(
                  text.contains('\u2009\u2009'),
                  isFalse,
                  reason: 'Should not have double thin space',
                );
              }
            }
          }
        }
      },
    );
  });
}
