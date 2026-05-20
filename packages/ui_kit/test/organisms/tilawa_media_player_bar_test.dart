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
