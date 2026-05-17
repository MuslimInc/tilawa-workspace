import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/organisms/tilawa_media_player_bar.dart';
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

    test('is true at 360dp with sleep timer (phone-width)', () {
      final tokens = TilawaMediaPlayerBarTokens.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.green),
      );
      expect(
        tilawaMediaPlayerBarNeedsCompactControls(
          maxWidth: 360,
          tokens: tokens,
          showSleepTimer: true,
        ),
        isTrue,
      );
    });
  });

  group('TilawaMediaPlayerBar layout', () {
    testWidgets('hides prev/next on narrow widths', (tester) async {
      await tester.pumpWidget(
        _themed(
          const SizedBox(
            width: 360,
            child: TilawaMediaPlayerBar(
              layoutWidth: 360,
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
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('shows full transport cluster on wide widths', (tester) async {
      await tester.pumpWidget(
        _themed(
          const SizedBox(
            width: 420,
            child: TilawaMediaPlayerBar(
              layoutWidth: 420,
              title: 'Surah Al-Fatiha',
              subtitle: 'Mohammad Kamal',
              progress: 0.2,
              isPlaying: false,
              canGoPrevious: true,
              canGoNext: true,
              isSleepTimerEnabled: true,
            ),
          ),
        ),
      );

      expect(find.byTooltip('Previous track'), findsOneWidget);
      expect(find.byTooltip('Next track'), findsOneWidget);
      expect(find.byTooltip('Sleep timer'), findsOneWidget);
    });
  });
}
