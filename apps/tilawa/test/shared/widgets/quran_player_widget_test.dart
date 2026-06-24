import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Mirrors [_CompactNowPlayingBar] bounded-height band layout.
Widget _compactNowPlayingBarBandLayoutHarness({
  required double height,
}) {
  return Builder(
    builder: (BuildContext context) {
      final TilawaDesignTokens tokens = Theme.of(context).tokens;
      final TilawaMediaPlayerBarTokens barTokens = Theme.of(
        context,
      ).componentTokens.mediaPlayerBar;
      final double rowHeight = barTokens.playPauseButtonSize;
      final ({double topBand, double bottomBand}) bands =
          resolveTilawaMediaPlayerCollapsedBands(
            maxHeight: height,
            rowHeight: rowHeight,
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: bands.topBand,
            child: LinearProgressIndicator(
              value: 0.35,
              minHeight: bands.topBand,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.spaceSmall,
              end: tokens.spaceSmall,
              bottom: bands.bottomBand,
            ),
            child: SizedBox(
              height: rowHeight,
              child: Row(
                children: <Widget>[
                  IconButton(
                    constraints: BoxConstraints(
                      minWidth: rowHeight,
                      minHeight: rowHeight,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    icon: const Icon(Icons.expand_more),
                  ),
                  const SizedBox(
                    width: kTilawaMediaPlayerBarCompactArtworkSize,
                    height: kTilawaMediaPlayerBarCompactArtworkSize,
                  ),
                  const Expanded(child: Text('Al-Fatiha')),
                  IconButton(
                    constraints: BoxConstraints(
                      minWidth: rowHeight,
                      minHeight: rowHeight,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      );
    },
  );
}

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
          extensions: <ThemeExtension<dynamic>>[
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
      'shell with bottom nav uses player height only for footprint',
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
                expect(
                  QuranPlayerLayoutInsets.phoneMiniPlayerNavGap(context),
                  0,
                );
                expect(
                  QuranPlayerLayoutInsets.phoneMiniPlayerTopPadding(context),
                  0,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pump();

        final tokens = TilawaDesignTokens.light();
        expect(footprint, tokens.playerCollapsedHeight);
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

  group('Compact now playing bar layout', () {
    testWidgets('band layout fits sub-pixel collapsed slot', (tester) async {
      const double slotHeight = 56.6;
      const double slotWidth = 353.9;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[
              TilawaDesignTokens.light(),
              TilawaComponentTokens.light(),
            ],
          ),
          home: Scaffold(
            body: SizedBox(
              width: slotWidth,
              height: slotHeight,
              child: _compactNowPlayingBarBandLayoutHarness(
                height: slotHeight,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('shell dock mini bar fits sub-pixel collapsed slot', (
      tester,
    ) async {
      const double slotHeight = 56.6;
      const double slotWidth = 353.9;
      final TilawaDesignTokens tokens = TilawaDesignTokens.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[
              tokens,
              TilawaComponentTokens.light(),
            ],
          ),
          home: Scaffold(
            body: SizedBox(
              width: slotWidth,
              height: slotHeight,
              child: TilawaMediaPlayerBar(
                layoutWidth: slotWidth,
                title: 'Surah Al-Baqarah',
                subtitle: 'Al-Minshawi',
                progress: 0.35,
                isPlaying: true,
                canGoPrevious: true,
                canGoNext: true,
                isSleepTimerEnabled: false,
                shellDockLayout: true,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TilawaMediaPlayerBar)),
        Size(slotWidth, slotHeight),
      );
    });
  });
}
