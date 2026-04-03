import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/services/idle_scheduler.dart';
import 'package:quran/src/services/page_snapshot_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Clean slate for each test.
    PageSnapshotService.instance.clear();
    IdleScheduler.instance.cancelAll();
  });

  group('PageSnapshotService', () {
    test('hasSnapshot returns false for uncached pages', () {
      expect(PageSnapshotService.instance.hasSnapshot(1), isFalse);
    });

    test('getSnapshot returns null for uncached pages', () {
      expect(PageSnapshotService.instance.getSnapshot(1), isNull);
    });

    test('clear() empties the cache', () {
      // clear() should not throw even on an empty cache.
      PageSnapshotService.instance.clear();
      expect(PageSnapshotService.instance.hasSnapshot(1), isFalse);
    });

    test('evict() removes a specific page', () {
      PageSnapshotService.instance.evict(42);
      // Should not throw.
      expect(PageSnapshotService.instance.hasSnapshot(42), isFalse);
    });

    test('cancelPending() is safe to call when no capture is pending', () {
      // Should be a no-op, no throw.
      PageSnapshotService.instance.cancelPending();
    });
  });

  group('PageSnapshotService.captureSnapshot', () {
    testWidgets('captures a snapshot from a live RepaintBoundary', (
      WidgetTester tester,
    ) async {
      final GlobalKey boundaryKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      final bool result = await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 1,
        boundaryKey: boundaryKey,
        pixelRatio: 1.0,
      );

      expect(result, isTrue);
      expect(PageSnapshotService.instance.hasSnapshot(1), isTrue);
      expect(PageSnapshotService.instance.getSnapshot(1), isNotNull);
    });

    testWidgets('skips capture if page already in cache', (
      WidgetTester tester,
    ) async {
      final GlobalKey boundaryKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(width: 50, height: 50),
        ),
      );

      final bool first = await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 7,
        boundaryKey: boundaryKey,
        pixelRatio: 1.0,
      );
      final bool second = await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 7,
        boundaryKey: boundaryKey,
        pixelRatio: 1.0,
      );

      expect(first, isTrue);
      // Returns true (already cached) without re-capturing.
      expect(second, isTrue);
    });

    testWidgets('fails gracefully with detached boundary key', (
      WidgetTester tester,
    ) async {
      final GlobalKey key = GlobalKey();

      final bool result = await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 1,
        boundaryKey: key,
        pixelRatio: 3.0,
      );

      expect(result, isFalse);
      expect(PageSnapshotService.instance.hasSnapshot(1), isFalse);
    });

    testWidgets('fails when key is on a non-RepaintBoundary widget', (
      WidgetTester tester,
    ) async {
      final GlobalKey key = GlobalKey();

      await tester.pumpWidget(SizedBox(key: key, width: 50, height: 50));

      final bool result = await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 2,
        boundaryKey: key,
        pixelRatio: 1.0,
      );

      expect(result, isFalse);
    });

    testWidgets('evict removes a previously captured snapshot', (
      WidgetTester tester,
    ) async {
      final GlobalKey boundaryKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(width: 50, height: 50),
        ),
      );

      await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 5,
        boundaryKey: boundaryKey,
        pixelRatio: 1.0,
      );
      expect(PageSnapshotService.instance.hasSnapshot(5), isTrue);

      PageSnapshotService.instance.evict(5);
      expect(PageSnapshotService.instance.hasSnapshot(5), isFalse);
    });

    testWidgets('clear disposes all cached snapshots', (
      WidgetTester tester,
    ) async {
      final GlobalKey key1 = GlobalKey();
      final GlobalKey key2 = GlobalKey();

      await tester.pumpWidget(
        Row(
          textDirection: TextDirection.ltr,
          children: [
            RepaintBoundary(
              key: key1,
              child: const SizedBox(width: 50, height: 50),
            ),
            RepaintBoundary(
              key: key2,
              child: const SizedBox(width: 50, height: 50),
            ),
          ],
        ),
      );

      await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 1,
        boundaryKey: key1,
        pixelRatio: 1.0,
      );
      await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 2,
        boundaryKey: key2,
        pixelRatio: 1.0,
      );

      expect(PageSnapshotService.instance.hasSnapshot(1), isTrue);
      expect(PageSnapshotService.instance.hasSnapshot(2), isTrue);

      PageSnapshotService.instance.clear();

      expect(PageSnapshotService.instance.hasSnapshot(1), isFalse);
      expect(PageSnapshotService.instance.hasSnapshot(2), isFalse);
    });

    testWidgets('LRU eviction removes oldest entry when cache is full', (
      WidgetTester tester,
    ) async {
      // _maxSnapshots is 10. Fill the cache, then add one more.
      final List<GlobalKey> keys = List.generate(11, (_) => GlobalKey());

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            children: [
              for (int i = 0; i < 11; i++)
                RepaintBoundary(
                  key: keys[i],
                  child: const SizedBox(width: 10, height: 10),
                ),
            ],
          ),
        ),
      );

      // Fill cache with pages 1–10.
      for (var i = 1; i <= 10; i++) {
        await PageSnapshotService.instance.captureSnapshot(
          pageNumber: i,
          boundaryKey: keys[i - 1],
          pixelRatio: 1.0,
        );
      }

      expect(PageSnapshotService.instance.hasSnapshot(1), isTrue);
      expect(PageSnapshotService.instance.hasSnapshot(10), isTrue);

      // Add page 11 — should evict page 1 (oldest).
      await PageSnapshotService.instance.captureSnapshot(
        pageNumber: 11,
        boundaryKey: keys[10],
        pixelRatio: 1.0,
      );

      expect(PageSnapshotService.instance.hasSnapshot(1), isFalse);
      expect(PageSnapshotService.instance.hasSnapshot(11), isTrue);
      // Pages 2–10 should still be cached.
      for (var i = 2; i <= 10; i++) {
        expect(PageSnapshotService.instance.hasSnapshot(i), isTrue);
      }
    });
  });

  group('PageSnapshotService.scheduleCaptureWhenIdle', () {
    testWidgets('returns a cancellable IdleTask', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();

      final IdleTask task = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 99,
            boundaryKey: key,
            pixelRatio: 3.0,
            centerPage: 99,
          );

      expect(task.isCancelled, isFalse);

      task.cancel();

      expect(task.isCancelled, isTrue);
    });

    testWidgets('defers capture to idle frames via IdleScheduler', (
      WidgetTester tester,
    ) async {
      final GlobalKey boundaryKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(width: 50, height: 50),
        ),
      );

      // Schedule — should NOT capture immediately.
      final IdleTask task = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 42,
            boundaryKey: boundaryKey,
            pixelRatio: 1.0,
          );

      // Not yet captured — still in the IdleScheduler queue.
      expect(PageSnapshotService.instance.hasSnapshot(42), isFalse);

      // Pump frames to let IdleScheduler execute.
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
      await task.future;

      expect(PageSnapshotService.instance.hasSnapshot(42), isTrue);
    });

    testWidgets('cancelled task never captures', (WidgetTester tester) async {
      final GlobalKey boundaryKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: const SizedBox(width: 50, height: 50),
        ),
      );

      final IdleTask task = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 55,
            boundaryKey: boundaryKey,
            pixelRatio: 1.0,
          );

      task.cancel();

      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(PageSnapshotService.instance.hasSnapshot(55), isFalse);
    });

    testWidgets('off-center pages use reduced pixel ratio (smaller image)', (
      WidgetTester tester,
    ) async {
      final GlobalKey offCenterKey = GlobalKey();
      final GlobalKey centerKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  key: offCenterKey,
                  child: const ColoredBox(color: Color(0xFFFF0000)),
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  key: centerKey,
                  child: const ColoredBox(color: Color(0xFF0000FF)),
                ),
              ),
            ],
          ),
        ),
      );

      // Off-center capture: centerPage=11, pageNumber=10
      final IdleTask offCenterTask = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 10,
            boundaryKey: offCenterKey,
            pixelRatio: 2.0,
            centerPage: 11,
          );

      // Center capture: centerPage=20, pageNumber=20
      final IdleTask centerTask = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 20,
            boundaryKey: centerKey,
            pixelRatio: 2.0,
            centerPage: 20,
          );

      for (var i = 0; i < 8; i++) {
        await tester.pump();
      }
      await offCenterTask.future;
      await centerTask.future;

      final ui.Image offCenterImage = PageSnapshotService.instance.getSnapshot(
        10,
      )!;
      final ui.Image centerImage = PageSnapshotService.instance.getSnapshot(
        20,
      )!;

      // Both boundaries are 100×100. Center uses pixelRatio=2.0,
      // off-center uses 2.0*0.75=1.5. So off-center image should be
      // 75% of center image dimensions.
      expect(offCenterImage.width, (centerImage.width * 0.75).round());
      expect(offCenterImage.height, (centerImage.height * 0.75).round());
    });

    testWidgets('center page captures at full pixel ratio', (
      WidgetTester tester,
    ) async {
      final GlobalKey centerKey = GlobalKey();
      final GlobalKey baseKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  key: centerKey,
                  child: const ColoredBox(color: Color(0xFFFF0000)),
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  key: baseKey,
                  child: const ColoredBox(color: Color(0xFF00FF00)),
                ),
              ),
            ],
          ),
        ),
      );

      // Center page: pixelRatio=2.0, centerPage == pageNumber
      final IdleTask centerTask = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 10,
            boundaryKey: centerKey,
            pixelRatio: 2.0,
            centerPage: 10,
          );

      // Baseline: pixelRatio=1.0 to determine raw boundary size
      final IdleTask baseTask = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 20,
            boundaryKey: baseKey,
            pixelRatio: 1.0,
            centerPage: 20,
          );

      for (var i = 0; i < 8; i++) {
        await tester.pump();
      }
      await centerTask.future;
      await baseTask.future;

      final ui.Image centerImage = PageSnapshotService.instance.getSnapshot(
        10,
      )!;
      final ui.Image baseImage = PageSnapshotService.instance.getSnapshot(20)!;

      // Center image at 2x should be exactly double the 1x baseline.
      expect(centerImage.width, baseImage.width * 2);
      expect(centerImage.height, baseImage.height * 2);
    });

    testWidgets('null centerPage captures at full pixel ratio', (
      WidgetTester tester,
    ) async {
      final GlobalKey nullKey = GlobalKey();
      final GlobalKey explicitKey = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  key: nullKey,
                  child: const ColoredBox(color: Color(0xFFFF0000)),
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: RepaintBoundary(
                  key: explicitKey,
                  child: const ColoredBox(color: Color(0xFF0000FF)),
                ),
              ),
            ],
          ),
        ),
      );

      // null centerPage → full ratio
      final IdleTask nullTask = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 10,
            boundaryKey: nullKey,
            pixelRatio: 2.0,
          );

      // Explicit centerPage == pageNumber → also full ratio
      final IdleTask explicitTask = PageSnapshotService.instance
          .scheduleCaptureWhenIdle(
            pageNumber: 20,
            boundaryKey: explicitKey,
            pixelRatio: 2.0,
            centerPage: 20,
          );

      for (var i = 0; i < 8; i++) {
        await tester.pump();
      }
      await nullTask.future;
      await explicitTask.future;

      final ui.Image nullImage = PageSnapshotService.instance.getSnapshot(10)!;
      final ui.Image explicitImage = PageSnapshotService.instance.getSnapshot(
        20,
      )!;

      // Both should produce identical dimensions — null centerPage
      // means no off-center scaling.
      expect(nullImage.width, explicitImage.width);
      expect(nullImage.height, explicitImage.height);
    });

    testWidgets(
      'multiple captures are serialized (no concurrent toImage calls)',
      (WidgetTester tester) async {
        final List<GlobalKey> keys = List.generate(3, (_) => GlobalKey());

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                for (int i = 0; i < 3; i++)
                  RepaintBoundary(
                    key: keys[i],
                    child: const SizedBox(width: 20, height: 20),
                  ),
              ],
            ),
          ),
        );

        final List<IdleTask> tasks = [];
        for (var i = 0; i < 3; i++) {
          tasks.add(
            PageSnapshotService.instance.scheduleCaptureWhenIdle(
              pageNumber: i + 1,
              boundaryKey: keys[i],
              pixelRatio: 1.0,
            ),
          );
        }

        // None should be captured immediately.
        for (var i = 1; i <= 3; i++) {
          expect(PageSnapshotService.instance.hasSnapshot(i), isFalse);
        }

        // Pump enough frames to complete all serial tasks.
        for (var i = 0; i < 10; i++) {
          await tester.pump();
        }
        for (final task in tasks) {
          await task.future;
        }

        // All three should now be captured.
        for (var i = 1; i <= 3; i++) {
          expect(PageSnapshotService.instance.hasSnapshot(i), isTrue);
        }
      },
    );
  });
}
