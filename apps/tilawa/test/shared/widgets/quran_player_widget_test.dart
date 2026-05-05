import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap({
  required Widget child,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) {
  return MediaQuery(
    data: MediaQueryData(viewPadding: viewPadding),
    child: MaterialApp(
      theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
      home: child,
    ),
  );
}

void main() {
  group('QuranPlayerWidget.collapsedFootprint', () {
    testWidgets('includes fallback spacing when viewPadding.bottom is 0', (
      tester,
    ) async {
      late double footprint;
      await tester.pumpWidget(
        _wrap(
          viewPadding: EdgeInsets.zero,
          child: Builder(
            builder: (context) {
              footprint = QuranPlayerWidget.collapsedFootprint(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final tokens = TilawaDesignTokens.light();
      expect(footprint, tokens.playerCollapsedHeight + tokens.spaceExtraLarge);
    });

    testWidgets(
      'includes system safe area + buffer when viewPadding.bottom > 0',
      (tester) async {
        late double footprint;
        await tester.pumpWidget(
          _wrap(
            viewPadding: const EdgeInsets.only(bottom: 34),
            child: Builder(
              builder: (context) {
                footprint = QuranPlayerWidget.collapsedFootprint(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final tokens = TilawaDesignTokens.light();
        expect(
          footprint,
          tokens.playerCollapsedHeight + 34 + tokens.spaceSmall,
        );
      },
    );

    testWidgets('includes bottomNavBarHeight when provided', (tester) async {
      late double footprint;
      await tester.pumpWidget(
        _wrap(
          viewPadding: EdgeInsets.zero,
          child: Builder(
            builder: (context) {
              footprint = QuranPlayerWidget.collapsedFootprint(
                context,
                bottomNavBarHeight: 56,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final tokens = TilawaDesignTokens.light();
      expect(
        footprint,
        tokens.playerCollapsedHeight + 56 + tokens.spaceExtraLarge,
      );
    });
  });
}
