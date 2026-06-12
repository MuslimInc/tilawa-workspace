import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_semantics_ids.dart';

/// Mirrors expanded transport + action pill bands (LTR control rows).
Widget _playbackControlBand({
  required bool swapSkipSidesForArabic,
  required bool showSleepTimer,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              identifier: QuranPlayerSemanticsIds.transportShuffle,
              child: const SizedBox(width: 48, height: 48),
            ),
            Semantics(
              identifier: swapSkipSidesForArabic
                  ? QuranPlayerSemanticsIds.transportNext
                  : QuranPlayerSemanticsIds.transportPrevious,
              child: const SizedBox(width: 48, height: 48),
            ),
            Semantics(
              identifier: QuranPlayerSemanticsIds.transportPlayPause,
              child: const SizedBox(width: 56, height: 56),
            ),
            Semantics(
              identifier: swapSkipSidesForArabic
                  ? QuranPlayerSemanticsIds.transportPrevious
                  : QuranPlayerSemanticsIds.transportNext,
              child: const SizedBox(width: 48, height: 48),
            ),
            Semantics(
              identifier: QuranPlayerSemanticsIds.transportRepeat,
              child: const SizedBox(width: 48, height: 48),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              identifier: QuranPlayerSemanticsIds.actionPillSpeed,
              child: const SizedBox(width: 72, height: 40),
            ),
            const SizedBox(width: 8),
            Semantics(
              identifier: QuranPlayerSemanticsIds.actionPillVolume,
              child: const SizedBox(width: 72, height: 40),
            ),
            if (showSleepTimer) ...[
              const SizedBox(width: 8),
              Semantics(
                identifier: QuranPlayerSemanticsIds.actionPillSleepTimer,
                child: const SizedBox(width: 72, height: 40),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

double _centerX(Finder finder, WidgetTester tester) {
  final Rect rect = tester.getRect(finder);
  return rect.center.dx;
}

void main() {
  group('Expanded playback control layout (RTL app)', () {
    Future<void> pumpBand(
      WidgetTester tester, {
      required bool arabic,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: _playbackControlBand(
                  swapSkipSidesForArabic: arabic,
                  showSleepTimer: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('transport row stays LTR — shuffle on physical start edge', (
      tester,
    ) async {
      await pumpBand(tester, arabic: true);

      final double shuffleX = _centerX(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.transportShuffle),
        tester,
      );
      final double playX = _centerX(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.transportPlayPause),
        tester,
      );
      final double repeatX = _centerX(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.transportRepeat),
        tester,
      );

      expect(shuffleX, lessThan(playX));
      expect(playX, lessThan(repeatX));
    });

    testWidgets('action pills stay LTR — speed before volume before sleep', (
      tester,
    ) async {
      await pumpBand(tester, arabic: true);

      final double speedX = _centerX(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.actionPillSpeed),
        tester,
      );
      final double volumeX = _centerX(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.actionPillVolume),
        tester,
      );
      final double sleepX = _centerX(
        find.bySemanticsIdentifier(
          QuranPlayerSemanticsIds.actionPillSleepTimer,
        ),
        tester,
      );

      expect(speedX, lessThan(volumeX));
      expect(volumeX, lessThan(sleepX));
    });

    testWidgets('Arabic skip swap places next left of play in LTR band', (
      tester,
    ) async {
      await pumpBand(tester, arabic: true);

      final double playX = _centerX(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.transportPlayPause),
        tester,
      );
      final double nextX = _centerX(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.transportNext),
        tester,
      );
      final double previousX = _centerX(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.transportPrevious),
        tester,
      );

      expect(nextX, lessThan(playX));
      expect(previousX, greaterThan(playX));
    });

    testWidgets(
      'ambient RTL without LTR bands mirrors pill order (regression)',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        identifier: QuranPlayerSemanticsIds.actionPillSpeed,
                        child: const SizedBox(width: 72, height: 40),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        identifier: QuranPlayerSemanticsIds.actionPillVolume,
                        child: const SizedBox(width: 72, height: 40),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final double speedX = _centerX(
          find.bySemanticsIdentifier(QuranPlayerSemanticsIds.actionPillSpeed),
          tester,
        );
        final double volumeX = _centerX(
          find.bySemanticsIdentifier(QuranPlayerSemanticsIds.actionPillVolume),
          tester,
        );

        // Row mirrors under ambient RTL: speed moves to physical right.
        expect(speedX, greaterThan(volumeX));
      },
    );
  });
}
