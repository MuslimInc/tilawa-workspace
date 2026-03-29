import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart';

void main() {
  testWidgets('QcfVerse renders Quran glyphs bold and verse marker regular', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: QcfVerse(surahNumber: 1, verseNumber: 1),
      ),
    );

    final RichText richText = tester.widget<RichText>(find.byType(RichText));
    final rootSpan = richText.text as TextSpan;
    final markerSpan = rootSpan.children!.single as TextSpan;

    expect(rootSpan.text, getVerseQCF(1, 1, verseEndSymbol: false));
    expect(rootSpan.style?.color, const Color(0xFF000000));
    expect(rootSpan.style?.shadows, isNotEmpty);
    expect(markerSpan.text, getVerseNumberQCF(1, 1));
    expect(markerSpan.style?.color, const Color(0xFF000000));
    expect(markerSpan.style?.shadows, anyOf(isNull, isEmpty));
  });
}
