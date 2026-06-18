import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _themed(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('tilawaMediaPlayerBarNeedsCompactControls', () {
    test('is false when metadata has enough room at 420dp', () {
      final tokens = TilawaMediaPlayerBarTokens.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.green),
      );
      expect(
        tilawaMediaPlayerBarNeedsCompactControls(
          maxWidth: 420,
          tokens: tokens,
          showSleepTimer: true,
        ),
        isFalse,
      );
    });

    test('is false at 360dp with play and sleep timer only', () {
      final tokens = TilawaMediaPlayerBarTokens.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.green),
      );
      expect(
        tilawaMediaPlayerBarNeedsCompactControls(
          maxWidth: 360,
          tokens: tokens,
          showSleepTimer: true,
        ),
        isFalse,
      );
    });
  });

  group('resolveTilawaMediaPlayerCollapsedBands', () {
    test('bands sum to maxHeight exactly', () {
      final bands = resolveTilawaMediaPlayerCollapsedBands(
        maxHeight: 56,
        rowHeight: 48,
      );
      expect(bands.topBand, 4);
      expect(bands.bottomBand, 4);
      expect(bands.topBand + 48 + bands.bottomBand, 56);
    });

    test('fits 56.5dp slot with 48dp row', () {
      final bands = resolveTilawaMediaPlayerCollapsedBands(
        maxHeight: 56.5,
        rowHeight: 48,
      );
      expect(bands.topBand, 4);
      expect(bands.bottomBand, 4.5);
      expect(bands.topBand + 48 + bands.bottomBand, 56.5);
    });
  });

  group('TilawaMediaPlayerBar layout', () {
    testWidgets('shows play/pause and sleep timer only', (tester) async {
      await tester.pumpWidget(
        _themed(
          const SizedBox(
            width: 420,
            child: TilawaMediaPlayerBar(
              layoutWidth: 420,
              title: 'Surah Al-Fatiha',
              subtitle: 'Mohammad Kamal',
              progress: 0.2,
              isPlaying: true,
              canGoPrevious: true,
              canGoNext: true,
              isSleepTimerEnabled: true,
            ),
          ),
        ),
      );

      expect(find.byTooltip('Previous track'), findsNothing);
      expect(find.byTooltip('Next track'), findsNothing);
      expect(find.byTooltip('Sleep timer'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('shell pill layout fits 56dp inner height', (tester) async {
      await tester.pumpWidget(
        _themed(
          const SizedBox(
            height: 56,
            width: 360,
            child: TilawaMediaPlayerBar(
              layoutWidth: 328,
              title: 'Surah Al-Baqarah',
              subtitle: 'Al-Minshawi',
              progress: 0.35,
              isPlaying: true,
              canGoPrevious: true,
              canGoNext: true,
              isSleepTimerEnabled: false,
              shellPillLayout: true,
              pillBorderRadius: 28,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('shell pill layout fits 56dp collapsed height', (tester) async {
      final tokens = TilawaDesignTokens.light();
      await tester.pumpWidget(
        _themed(
          SizedBox(
            height: tokens.playerCollapsedHeight,
            width: 360,
            child: TilawaMediaPlayerBar(
              layoutWidth: 328,
              title: 'Surah Al-Baqarah',
              subtitle: 'Al-Minshawi',
              progress: 0.35,
              isPlaying: true,
              canGoPrevious: true,
              canGoNext: true,
              isSleepTimerEnabled: false,
              shellPillLayout: true,
              pillBorderRadius: tokens.radiusPill(tokens.playerCollapsedHeight),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TilawaMediaPlayerBar)),
        Size(360, tokens.playerCollapsedHeight),
      );
      expect(find.textContaining(' · '), findsOneWidget);
    });

    testWidgets('tight non-shell layout fits fractional collapsed height',
        (tester) async {
      await tester.pumpWidget(
        _themed(
          const SizedBox(
            height: 56.5,
            width: 360,
            child: TilawaMediaPlayerBar(
              layoutWidth: 328,
              title: 'Surah Al-Baqarah',
              subtitle: 'Al-Minshawi',
              progress: 0.35,
              isPlaying: true,
              canGoPrevious: true,
              canGoNext: true,
              isSleepTimerEnabled: false,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('transport tap does not fire bar onTap', (tester) async {
      var barTapped = false;
      var playTapped = false;

      await tester.pumpWidget(
        _themed(
          SizedBox(
            width: 420,
            child: TilawaMediaPlayerBar(
              layoutWidth: 420,
              title: 'Surah Al-Fatiha',
              subtitle: 'Mohammad Kamal',
              progress: 0.2,
              isPlaying: false,
              canGoPrevious: true,
              canGoNext: true,
              onTap: () => barTapped = true,
              onPlayPause: () => playTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Play'));
      await tester.pumpAndSettle();

      expect(playTapped, isTrue);
      expect(barTapped, isFalse);
    });

    testWidgets('metadata tap fires bar onTap', (tester) async {
      var barTapped = false;

      await tester.pumpWidget(
        _themed(
          SizedBox(
            width: 420,
            child: TilawaMediaPlayerBar(
              layoutWidth: 420,
              title: 'Surah Al-Fatiha',
              subtitle: 'Mohammad Kamal',
              progress: 0.2,
              isPlaying: false,
              canGoPrevious: true,
              canGoNext: true,
              onTap: () => barTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Surah Al-Fatiha'));
      await tester.pumpAndSettle();

      expect(barTapped, isTrue);
    });
  });
}
