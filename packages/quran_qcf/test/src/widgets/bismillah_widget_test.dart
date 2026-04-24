import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/presentation/widgets/bismillah_widget.dart';

void main() {
  group('BismillahStyleConfig', () {
    test('forPage returns Page 1/2 style for page 1', () {
      final BismillahStyleConfig config = BismillahStyleConfig.forPage(1);
      expect(config.text, '\uFC41\u200A\uFC42\uFC43\uFC44');
      expect(config.fontFamily, 'QCF_P001');
      expect(config.package, isNull);
      expect(config.fontScale, 1.0);
    });

    test('forPage returns Page 1/2 style for page 2', () {
      final BismillahStyleConfig config = BismillahStyleConfig.forPage(2);
      expect(config.text, '\uFC41\u200A\uFC42\uFC43\uFC44');
      expect(config.fontFamily, 'QCF_P001');
      expect(config.package, isNull);
      expect(config.fontScale, 1.0);
    });

    test('forPage returns standard style for page 3', () {
      final BismillahStyleConfig config = BismillahStyleConfig.forPage(3);
      expect(config.text, '齃𧻓𥳐龎');
      expect(config.fontFamily, 'QCF_BSML');
      expect(config.package, 'quran_qcf');
      // We expect the original 0.8 internal scale factor
      expect(config.fontScale, 0.8);
    });
  });

  group('BismillahWidget', () {
    Widget buildSubject({required int pageNumber}) {
      return MaterialApp(
        home: Scaffold(
          body: BismillahWidget(
            fontSize: 20.0,
            pageNumber: pageNumber,
            color: Colors.red,
          ),
        ),
      );
    }

    testWidgets('renders exactly 4-word inline structure for Page 1/2', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(pageNumber: 2));

      final Finder textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.data, '\uFC41\u200A\uFC42\uFC43\uFC44');

      final TextStyle style = textWidget.style!;
      expect(style.fontFamily, 'QCF_P001');
      expect(style.fontSize, 20.0);
      expect(style.color, Colors.red);
    });

    testWidgets('renders standard calligraphic block for Page 3+', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(pageNumber: 3));

      final Finder textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.data, '齃𧻓𥳐龎');

      final TextStyle style = textWidget.style!;
      expect(style.fontFamily, 'packages/quran_qcf/QCF_BSML');
      expect(style.fontSize, 16.0); // 20.0 * 0.8
      expect(style.color, Colors.red);
    });
  });
}
