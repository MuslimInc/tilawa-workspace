import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/quran_image_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test captures performance metrics for two scenarios:
  // 1. Sequential scrolling (10 pages)
  // 2. Aggressive random jumping (stress test)
  testWidgets('performance_test', (WidgetTester tester) async {
    // Reset DI to ensure clean state for performance measurement
    await sl.reset();
    await initDependencies();

    // Ensure repository is initialized with debug mode for test predictability
    await sl<AssetVerseMarkerRepository>().init(
      forceDebugSource: true,
      preloadAllPages: true,
    );

    // Build the app
    await tester.pumpWidget(const QuranImageApp());
    await tester.pumpAndSettle();

    // SCENARIO 1: Sequential Scrolling Performance
    debugPrint('Starting sequential scrolling performance test...');
    await binding.watchPerformance(() async {
      for (int i = 0; i < 10; i++) {
        await tester.fling(find.byType(PageView), const Offset(-500, 0), 2000);
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }, reportKey: 'sequential_scrolling');

    // SCENARIO 2: Aggressive Random Jumps (Stress Test)
    debugPrint('Starting aggressive jumping stress test...');
    await binding.watchPerformance(() async {
      final PageView pageView = tester.widget(find.byType(PageView));
      final PageController controller = pageView.controller!;

      final List<int> jumpTargets = [500, 20, 400, 100, 300, 50, 450];
      for (final target in jumpTargets) {
        debugPrint('Jumping to page $target...');
        controller.jumpToPage(target);
        await tester.pumpAndSettle();
        // Wait for all images/markers to stabilize in VRAM
        await Future.delayed(const Duration(seconds: 1));
      }
    }, reportKey: 'random_jumps');

    debugPrint(
      'Performance test complete. Check results in the timeline summary.',
    );
  });
}
