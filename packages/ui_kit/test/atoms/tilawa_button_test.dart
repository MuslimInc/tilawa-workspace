import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/atoms/tilawa_button.dart';

void _noop() {}

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
      'non–full-width long label in a loose max width ellipsizes when capped',
      (WidgetTester tester) async {
        const longLabel =
            'This is an intentionally long label that must ellipsize '
            'inside a narrow slot without a RenderFlex overflow';

        await tester.pumpWidget(
          _app(
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: TilawaButton(
                  text: longLabel,
                  onPressed: () {},
                  isFullWidth: true,
                ),
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
        expect(_labelParagraph(tester).didExceedMaxLines, isTrue);
      },
    );

    testWidgets(
      'non–full-width short label does not expand to parent max width',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _app(
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: TilawaButton(
                  text: 'OK',
                  onPressed: _noop,
                  isFullWidth: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final RenderBox buttonBox = tester.renderObject<RenderBox>(
          find.byType(TextButton),
        );
        expect(buttonBox.size.width, lessThan(560));
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
          findsNothing,
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
          findsNothing,
        );
        expect(_labelParagraph(tester).didExceedMaxLines, isFalse);
      },
    );

    testWidgets('shrinkWrapTapTarget skips 48×48 outer minimum constraints', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaButton(
            text: 'Link',
            variant: TilawaButtonVariant.ghost,
            shrinkWrapTapTarget: true,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is ConstrainedBox &&
              w.constraints ==
                  const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
        findsNothing,
      );
    });

    testWidgets('custom backgroundColor applies to enabled state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaButton(
            text: 'Brand',
            variant: TilawaButtonVariant.primary,
            backgroundColor: const Color(0xFFE1C17B),
            foregroundColor: const Color(0xFF0D3933),
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Text textWidget = tester.widget(
        find.descendant(
          of: find.byType(TilawaButton),
          matching: find.byType(Text),
        ),
      );
      expect(textWidget.style?.color, const Color(0xFF0D3933));
    });

    testWidgets('medium button resolves pill radius from height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaButton(
            text: 'Save',
            onPressed: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final TextButton button = tester.widget(find.byType(TextButton));
      final OutlinedBorder? shape = button.style!.shape!.resolve(const {});
      expect(shape, isA<RoundedRectangleBorder>());
      final RoundedRectangleBorder rounded = shape! as RoundedRectangleBorder;
      expect(rounded.borderRadius, BorderRadius.circular(24));
    });
  });
}
