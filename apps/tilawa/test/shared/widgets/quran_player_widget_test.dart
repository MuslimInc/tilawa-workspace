import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap({
  required Widget child,
  EdgeInsets viewPadding = EdgeInsets.zero,
  String initialLocation = '/downloads',
  Size viewportSize = const Size(390, 844),
}) {
  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => child,
      ),
    ],
  );

  return MediaQuery(
    data: MediaQueryData(
      viewPadding: viewPadding,
      size: viewportSize,
    ),
    child: ChangeNotifierProvider(
      create: (_) => QuranPlayerChromeNotifier(),
      child: MaterialApp.router(
        theme: ThemeData(
          extensions: [
            TilawaDesignTokens.light(),
            TilawaComponentTokens.light(),
          ],
        ),
        routerConfig: router,
      ),
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

    testWidgets(
      'shell with bottom nav uses player height and mini-nav gap for footprint',
      (tester) async {
        late double footprint;

        await tester.pumpWidget(
          _wrap(
            initialLocation: '/',
            viewportSize: const Size(900, 1200),
            viewPadding: const EdgeInsets.only(bottom: 34),
            child: Builder(
              builder: (context) {
                context.read<QuranPlayerChromeNotifier>().updateShellChrome(
                  const QuranPlayerShellChrome(
                    bottomNavBarHeight: 72,
                    isKeyboardOpen: false,
                    isAudioBindingDeferred: false,
                    hostAbsorbsBottomSafeArea: true,
                  ),
                );
                footprint = QuranPlayerWidget.collapsedFootprint(context);
                final shellTokens = Theme.of(
                  context,
                ).componentTokens.adaptiveShell;
                expect(
                  QuranPlayerLayoutInsets.phoneMiniPlayerNavGap(context),
                  shellTokens.bottomNavVerticalMargin,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pump();

        final tokens = TilawaDesignTokens.light();
        final shellTokens = TilawaComponentTokens.light().adaptiveShell;
        expect(
          footprint,
          tokens.playerCollapsedHeight +
              shellTokens.bottomNavInternalPadding +
              shellTokens.bottomNavVerticalMargin,
        );
      },
    );

    testWidgets(
      'wide shell footer spacing is flush when safe area is zero',
      (tester) async {
        late double spacing;
        await tester.pumpWidget(
          _wrap(
            viewportSize: const Size(900, 1200),
            child: Builder(
              builder: (context) {
                spacing = QuranPlayerLayoutInsets.phoneFooterBottomSpacing(
                  context,
                  hostAbsorbsBottomSafeArea: false,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(spacing, 0);
      },
    );
  });
}
