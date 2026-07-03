import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/component_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';

import '../../lib/src/atoms/tilawa_button.dart';

void _noop() {}

Widget _app(Widget child) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(colorScheme: colorScheme),
      ],
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

    testWidgets('dangerOutline uses the same pill radius as primary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              TilawaButton(
                text: 'Logout',
                variant: TilawaButtonVariant.primary,
                onPressed: _noop,
              ),
              TilawaButton(
                text: 'Delete account',
                variant: TilawaButtonVariant.dangerOutline,
                onPressed: _noop,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final List<TextButton> buttons = tester
          .widgetList<TextButton>(find.byType(TextButton))
          .toList();
      expect(buttons.length, 2);

      final RoundedRectangleBorder primaryShape =
          buttons[0].style!.shape!.resolve(const {})! as RoundedRectangleBorder;
      final RoundedRectangleBorder dangerShape =
          buttons[1].style!.shape!.resolve(const {})! as RoundedRectangleBorder;

      expect(dangerShape.borderRadius, primaryShape.borderRadius);
      expect(dangerShape.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('outline and secondary variants use pill radius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaButton(
            text: 'Continue',
            variant: TilawaButtonVariant.outline,
            onPressed: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final TextButton button = tester.widget(find.byType(TextButton));
      final RoundedRectangleBorder shape =
          button.style!.shape!.resolve(const {})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('small size still enforces at least 48dp height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaButton(
            text: 'Save',
            size: TilawaButtonSize.small,
            onPressed: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Size size = tester.getSize(find.byType(TilawaButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('large size matches 48dp min interactive height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaButton(
            text: 'Save and continue',
            size: TilawaButtonSize.large,
            onPressed: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final TextButton button = tester.widget(find.byType(TextButton));
      expect(
        button.style!.minimumSize!.resolve(const {})!.height,
        kMeMuslimMinInteractiveDimension,
      );
    });

    testWidgets(
      'isFullWidth below Expanded in Column stays at min interactive height',
      (WidgetTester tester) async {
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });
        await tester.binding.setSurfaceSize(const Size(360, 640));

        await tester.pumpWidget(
          _app(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Expanded(child: SizedBox.shrink()),
                TilawaButton(
                  text: 'Retry',
                  isFullWidth: true,
                  onPressed: _noop,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(
          tester.getSize(find.byType(TilawaButton)).height,
          kMeMuslimMinInteractiveDimension,
        );
      },
    );
  });

  group('TilawaButton focus visibility (WCAG 2.4.7)', () {
    testWidgets(
      'paints a focus ring of focusRingWidth on keyboard focus even for '
      'borderless variants',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _app(
            const TilawaButton(
              text: 'Continue',
              onPressed: _noop,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final ButtonStyle style = tester
            .widget<TextButton>(find.byType(TextButton))
            .style!;

        // Resting (primary, no border): no side.
        expect(style.side!.resolve(const {}), BorderSide.none);

        // Focused: a visible ring at the kit's focus width.
        final BorderSide focusedSide = style.side!.resolve(
          {WidgetState.focused},
        )!;
        expect(focusedSide, isNot(BorderSide.none));
        expect(focusedSide.width, MeMuslimDesignTokens.light().focusRingWidth);

        // Focused also gets a state-layer wash distinct from the resting state.
        expect(style.overlayColor!.resolve(const {}), isNull);
        expect(
          style.overlayColor!.resolve({WidgetState.focused}),
          isNotNull,
        );
      },
    );

    testWidgets('pressed wash takes priority over focused wash', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const TilawaButton(text: 'Continue', onPressed: _noop)),
      );
      await tester.pumpAndSettle();

      final ButtonStyle style = tester
          .widget<TextButton>(find.byType(TextButton))
          .style!;

      // When both states are active the resolver must return the pressed wash,
      // matching TilawaInteractiveSurface's pressed > hover > focus ordering.
      final Color bothStates = style.overlayColor!.resolve(
        {WidgetState.pressed, WidgetState.focused},
      )!;
      final Color pressedOnly = style.overlayColor!.resolve(
        {WidgetState.pressed},
      )!;
      final Color focusedOnly = style.overlayColor!.resolve(
        {WidgetState.focused},
      )!;
      expect(bothStates, pressedOnly);
      expect(bothStates, isNot(focusedOnly));
    });
  });
}
