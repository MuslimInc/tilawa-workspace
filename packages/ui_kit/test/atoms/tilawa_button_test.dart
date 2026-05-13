import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/atoms/tilawa_button.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    ),
    home: Scaffold(body: child),
  );
}

RenderParagraph _labelParagraph(WidgetTester tester) {
  return tester.renderObject<RenderParagraph>(
    find
        .descendant(
          of: find.byType(TilawaButton),
          matching: find.byType(RichText),
        )
        .first,
  );
}

void main() {
  group('TilawaButton label layout', () {
    testWidgets(
      'non–full-width long label in tight width ellipsizes on one line '
      'without overflow',
      (WidgetTester tester) async {
        const longLabel =
            'This is an intentionally long label that must ellipsize '
            'inside a narrow slot without a RenderFlex overflow';

        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 120,
              child: TilawaButton(
                text: longLabel,
                onPressed: () {},
                isFullWidth: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(
          find.descendant(
            of: find.byType(TilawaButton),
            matching: find.byType(Flexible),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(TilawaButton),
            matching: find.byType(Expanded),
          ),
          findsNothing,
        );

        final textWidget = tester.widget<Text>(
          find.descendant(
            of: find.byType(TilawaButton),
            matching: find.byType(Text),
          ),
        );
        expect(textWidget.maxLines, 1);
        expect(textWidget.overflow, TextOverflow.ellipsis);
        expect(textWidget.softWrap, isFalse);
        expect(_labelParagraph(tester).didExceedMaxLines, isTrue);
      },
    );

    testWidgets(
      'non–full-width short label in tight width shows full text without '
      'ellipsis',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 120,
              child: TilawaButton(
                text: 'OK',
                onPressed: () {},
                isFullWidth: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(
          find.descendant(
            of: find.byType(TilawaButton),
            matching: find.byType(Flexible),
          ),
          findsOneWidget,
        );
        expect(_labelParagraph(tester).didExceedMaxLines, isFalse);
      },
    );

    testWidgets(
      'isFullWidth long label in tight width uses Expanded, ellipsizes, '
      'no overflow',
      (WidgetTester tester) async {
        const longLabel =
            'This is an intentionally long label that must ellipsize '
            'inside a narrow slot when the button is full width';

        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 120,
              child: TilawaButton(
                text: longLabel,
                onPressed: () {},
                isFullWidth: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(
          find.descendant(
            of: find.byType(TilawaButton),
            matching: find.byType(Expanded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(TilawaButton),
            matching: find.byType(Flexible),
          ),
          findsNothing,
        );
        expect(_labelParagraph(tester).didExceedMaxLines, isTrue);
      },
    );

    testWidgets(
      'non–full-width long label in a wide loose parent shows full line '
      'without ellipsis',
      (WidgetTester tester) async {
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });
        await tester.binding.setSurfaceSize(const Size(900, 600));

        const longButFits =
            'Continue with email and profile settings for your account';

        await tester.pumpWidget(
          _app(
            Center(
              child: TilawaButton(
                text: longButFits,
                onPressed: () {},
                isFullWidth: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(
          find.descendant(
            of: find.byType(TilawaButton),
            matching: find.byType(Flexible),
          ),
          findsOneWidget,
        );
        expect(_labelParagraph(tester).didExceedMaxLines, isFalse);
      },
    );
  });
}
