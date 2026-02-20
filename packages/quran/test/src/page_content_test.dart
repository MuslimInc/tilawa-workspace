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
        final String plainText = richText.text.toPlainText();
        // Since we are looking for the Quran verses on page 18, which start with ﱁ
        if (plainText.contains('ﱁ')) {
          firstVerseText = plainText;
          // The first word ﱁ should be followed by a thin space \u2009
          if (plainText.contains('ﱁ\u2009')) {
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
          final String plainText = richText.text.toPlainText();
          expect(
            plainText.contains(' \u2009'),
            isFalse,
            reason: 'Should not have both standard space and thin space',
          );
          expect(
            plainText.contains('\u2009 '),
            isFalse,
            reason: 'Should not have both standard space and thin space',
          );
          expect(
            plainText.contains('\u2009\u2009'),
            isFalse,
            reason: 'Should not have double thin space',
          );
        }
      },
    );
  });
}
