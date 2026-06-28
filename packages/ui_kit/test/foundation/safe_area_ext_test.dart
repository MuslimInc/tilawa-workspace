import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/foundation/safe_area_ext.dart';

const _spaceSmall = 8.0;
const _spaceExtraLarge = 24.0;

Widget _wrap({
  required Widget child,
  EdgeInsets viewPadding = EdgeInsets.zero,
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return MediaQuery(
    data: MediaQueryData(
      viewPadding: viewPadding,
      padding: padding,
      viewInsets: viewInsets,
    ),
    child: Theme(
      data: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
      child: child,
    ),
  );
}

void main() {
  group('TilawaSafeAreaX — system safe area', () {
    testWidgets('systemSafeArea reflects viewPadding', (tester) async {
      const viewPadding = EdgeInsets.only(top: 44, bottom: 34);
      late EdgeInsets captured;

      await tester.pumpWidget(
        _wrap(
          viewPadding: viewPadding,
          child: Builder(
            builder: (context) {
              captured = context.systemSafeArea;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured, viewPadding);
    });

    testWidgets('systemTopSafeArea and systemBottomSafeArea', (tester) async {
      late double top;
      late double bottom;

      await tester.pumpWidget(
        _wrap(
          viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
          child: Builder(
            builder: (context) {
              top = context.systemTopSafeArea;
              bottom = context.systemBottomSafeArea;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(top, 44);
      expect(bottom, 34);
    });
  });

  group('TilawaSafeAreaX — content safe padding', () {
    testWidgets('contentSafePadding reflects padding', (tester) async {
      const padding = EdgeInsets.only(top: 20, bottom: 10);
      late EdgeInsets captured;

      await tester.pumpWidget(
        _wrap(
          padding: padding,
          child: Builder(
            builder: (context) {
              captured = context.contentSafePadding;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured, padding);
    });

    testWidgets('contentTopSafePadding and contentBottomSafePadding', (
      tester,
    ) async {
      late double top;
      late double bottom;

      await tester.pumpWidget(
        _wrap(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Builder(
            builder: (context) {
              top = context.contentTopSafePadding;
              bottom = context.contentBottomSafePadding;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(top, 20);
      expect(bottom, 10);
    });
  });

  group('TilawaSafeAreaX — keyboard insets', () {
    testWidgets('keyboardInset reflects viewInsets.bottom', (tester) async {
      late double inset;
      late bool visible;

      await tester.pumpWidget(
        _wrap(
          viewInsets: const EdgeInsets.only(bottom: 300),
          child: Builder(
            builder: (context) {
              inset = context.keyboardInset;
              visible = context.isKeyboardVisible;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(inset, 300);
      expect(visible, isTrue);
    });

    testWidgets('isKeyboardVisible is false when viewInsets is zero', (
      tester,
    ) async {
      late bool visible;

      await tester.pumpWidget(
        _wrap(
          child: Builder(
            builder: (context) {
              visible = context.isKeyboardVisible;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(visible, isFalse);
    });
  });

  group('TilawaSafeAreaX — floatingBottomPadding', () {
    testWidgets(
      'uses systemBottomSafeArea + spaceSmall buffer when safe area > 0',
      (tester) async {
        late double padding;

        await tester.pumpWidget(
          _wrap(
            viewPadding: const EdgeInsets.only(bottom: 34),
            child: Builder(
              builder: (context) {
                padding = context.floatingBottomPadding;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(padding, 34 + _spaceSmall);
      },
    );

    testWidgets(
      'falls back to spaceExtraLarge when systemBottomSafeArea is 0',
      (tester) async {
        late double padding;

        await tester.pumpWidget(
          _wrap(
            child: Builder(
              builder: (context) {
                padding = context.floatingBottomPadding;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(padding, _spaceExtraLarge);
      },
    );

    testWidgets(
      'uses view-level bottom inset when MediaQuery viewPadding is stripped',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.viewPadding = const FakeViewPadding(bottom: 34);
        addTearDown(tester.view.reset);

        late double padding;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(viewPadding: EdgeInsets.zero),
            child: Theme(
              data: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
              child: Builder(
                builder: (context) {
                  padding = context.floatingBottomPadding;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(padding, 34 + _spaceSmall);
      },
    );
  });

  group('TilawaSafeAreaX — keyboardAwareBottomPadding', () {
    testWidgets('uses keyboardInset + spaceSmall when keyboard is visible', (
      tester,
    ) async {
      late double padding;

      await tester.pumpWidget(
        _wrap(
          viewInsets: const EdgeInsets.only(bottom: 300),
          child: Builder(
            builder: (context) {
              padding = context.keyboardAwareBottomPadding;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding, 300 + _spaceSmall);
    });

    testWidgets('falls back to floatingBottomPadding when keyboard is hidden', (
      tester,
    ) async {
      late double padding;

      await tester.pumpWidget(
        _wrap(
          viewPadding: const EdgeInsets.only(bottom: 34),
          child: Builder(
            builder: (context) {
              padding = context.keyboardAwareBottomPadding;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding, 34 + _spaceSmall);
    });
  });

  group('TilawaSafeAreaX — floatingBottomPaddingWithMin', () {
    testWidgets('respects minimum spacing when it exceeds calculated value', (
      tester,
    ) async {
      late double padding;

      await tester.pumpWidget(
        _wrap(
          viewPadding: const EdgeInsets.only(bottom: 10),
          child: Builder(
            builder: (context) {
              padding = context.floatingBottomPaddingWithMin(32);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding, 32);
    });

    testWidgets('uses calculated value when it exceeds minimum', (
      tester,
    ) async {
      late double padding;

      await tester.pumpWidget(
        _wrap(
          viewPadding: const EdgeInsets.only(bottom: 34),
          child: Builder(
            builder: (context) {
              padding = context.floatingBottomPaddingWithMin(8);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding, 34 + _spaceSmall);
    });
  });

  group('TilawaSafeAreaX — keyboardAwarePadding', () {
    testWidgets('allows custom keyboard buffer', (tester) async {
      late double padding;

      await tester.pumpWidget(
        _wrap(
          viewInsets: const EdgeInsets.only(bottom: 200),
          child: Builder(
            builder: (context) {
              padding = context.keyboardAwarePadding(keyboardBuffer: 20);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding, 220);
    });

    testWidgets('allows custom fallback minimum spacing', (tester) async {
      late double padding;

      await tester.pumpWidget(
        _wrap(
          child: Builder(
            builder: (context) {
              padding = context.keyboardAwarePadding(fallbackMinSpacing: 48);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(padding, 48);
    });
  });
}
