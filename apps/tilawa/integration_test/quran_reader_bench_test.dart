import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/page_navigation_bar.dart';
import 'package:tilawa/main.dart' as app;
import 'package:tilawa/router/app_router_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Quran Reader Performance Benchmark', (
    WidgetTester tester,
  ) async {
    // 0. Setup error handler restoration to prevent assertion crash
    final originalOnError = FlutterError.onError;

    print('[BENCH] Bootstrapping application...');
    await tester.runAsync(() async {
      await app.main();
    });

    // Restore the test binding's error handler
    FlutterError.onError = originalOnError;

    // 1. Handle Onboarding & Auth (Skip to Home)
    await _skipOnboardingAndAuth(tester);

    // 2. Navigate to the Quran Reader
    print('[BENCH] Navigating to Quran Reader...');
    await _navigateToReader(tester);
    print('[BENCH] Landed on Quran Reader Screen');

    // 3. Cold Jump Benchmark (Page 1 to 300)
    print('[BENCH] Starting Cold Jump Benchmark (Page 1 -> 300)...');
    final Stopwatch coldJumpStopwatch = Stopwatch()..start();

    await _jumpToPage(tester, 300);

    // We pump for enough time to see the first frame of the jump
    await tester.pump(const Duration(milliseconds: 16));
    print('[BENCH] Jump command issued. Waiting for render...');

    await tester.pumpAndSettle(const Duration(seconds: 5));
    coldJumpStopwatch.stop();
    print(
      '[BENCH] Cold Jump (Page 1 -> 300) completed in ${coldJumpStopwatch.elapsedMilliseconds}ms',
    );

    // 4. Repeated Distant Jumps (Stress test warming)
    print('[BENCH] Starting Stress Test: 3 Distant Jumps...');
    final List<int> targets = [150, 450, 10];
    for (final target in targets) {
      final sw = Stopwatch()..start();
      print('[BENCH] Jumping to page $target...');
      await _jumpToPage(tester, target);
      await tester.pumpAndSettle();
      sw.stop();
      print(
        '[BENCH] Jump to $target took ${sw.elapsedMilliseconds}ms (Warming + Navigation)',
      );
    }

    // 4. Swipe Performance Benchmark (Rapid swiping)
    print('[BENCH] Starting Swipe Performance Benchmark (5 rapid swipes)...');
    final Stopwatch swipeStopwatch = Stopwatch()..start();

    final pageViewFinder = find.byType(PageView);
    for (int i = 0; i < 5; i++) {
      print('[BENCH] Swiping to next page... (${i + 1}/5)');
      // Use fling for realistic swipe interaction
      await tester.fling(pageViewFinder, const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();
      // Small delay to allow font loaders to settle if any
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    swipeStopwatch.stop();
    print(
      '[BENCH] 5 Swipes completed in ${swipeStopwatch.elapsedMilliseconds}ms',
    );

    print('[BENCH] ALL BENCHMARKS COMPLETED SUCCESSFULLY');
  });
}

Future<void> _skipOnboardingAndAuth(WidgetTester tester) async {
  // Wait for the initial screen to load
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // If we are on Onboarding, click through
  final nextBtn = find.text('Next');
  final nextBtnAr = find.text('التالي');
  final nextFinder = nextBtn.evaluate().isNotEmpty ? nextBtn : nextBtnAr;

  if (nextFinder.evaluate().isNotEmpty) {
    print('[BENCH] Onboarding detected, clicking through...');
    for (int i = 0; i < 2; i++) {
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();
    }
    // Last page: "Start Journey" / "ابدأ الرحلة"
    final startBtn = find.byType(FilledButton).last;
    await tester.tap(startBtn);
    await tester.pumpAndSettle();
  }

  // If we are on Login, bypass directly to Home via router
  // We don't want to trigger Google Sign-in popup in a benchmark
  final loginBtn = find.text('Continue with Google');
  final loginBtnAr = find.text('الاستمرار باستخدام Google');
  if (loginBtn.evaluate().isNotEmpty || loginBtnAr.evaluate().isNotEmpty) {
    print('[BENCH] Login screen detected, bypassing to Home...');
    final context = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      const HomeRoute().go(context);
    });
    await tester.pumpAndSettle();
  }

  print('[BENCH] Reached Home screen');
}

Future<void> _navigateToReader(WidgetTester tester) async {
  // Find the Quran button in the bottom navigation bar (Icons.menu_book_rounded)
  // In the real app, it's the middle button in MainScreen
  final quranNavBtn = find.byIcon(Icons.menu_book_rounded);
  if (quranNavBtn.evaluate().isEmpty) {
    print('[BENCH] Quran icon not found, searching by text labels...');
    final quranLabel = find.text('المصحف');
    final quranLabelEn = find.text('Quran');
    final target = quranLabel.evaluate().isNotEmpty ? quranLabel : quranLabelEn;
    expect(target, findsOneWidget, reason: 'Quran navigation button not found');
    await tester.tap(target);
  } else {
    await tester.tap(quranNavBtn);
  }

  // Transition through FontLoaderScreen (wait for warming)
  await tester.pumpAndSettle(const Duration(seconds: 12));
}

Future<void> _jumpToPage(WidgetTester tester, int pageNumber) async {
  final navBarFinder = find.byType(PageNavigationBar);
  if (navBarFinder.evaluate().isEmpty) {
    print('[BENCH] PageNavigationBar not visible, tapping to reveal...');
    await tester.tapAt(const Offset(200, 400));
    await tester.pumpAndSettle();
  }

  expect(navBarFinder, findsOneWidget, reason: 'PageNavigationBar not found');

  final navBar = tester.widget<PageNavigationBar>(navBarFinder);
  await tester.runAsync(() async {
    navBar.onPageChanged(pageNumber);
  });
}
