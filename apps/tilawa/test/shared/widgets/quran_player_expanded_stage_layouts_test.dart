import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_expanded_stage_layouts.dart';

void main() {
  group('quranPlayerExpandedStageVerticalDragEndDetails', () {
    test('strips horizontal velocity for DragEndDetails assertion', () {
      final DragEndDetails details =
          quranPlayerExpandedStageVerticalDragEndDetails(
            const Velocity(pixelsPerSecond: Offset(120, -80)),
          );

      expect(details.primaryVelocity, -80);
      expect(details.velocity.pixelsPerSecond.dx, 0);
      expect(details.velocity.pixelsPerSecond.dy, -80);
    });

    test('non-finite vertical velocity returns safe zero end details', () {
      final DragEndDetails details =
          quranPlayerExpandedStageVerticalDragEndDetails(
            const Velocity(pixelsPerSecond: Offset(0, double.nan)),
          );

      expect(details.primaryVelocity, 0);
      expect(() => details.velocity, returnsNormally);
    });
  });

  group('QuranPlayerExpandedStageScrollDragLogic', () {
    test('locks scroll at top for downward and upward drags', () {
      expect(
        QuranPlayerExpandedStageScrollDragLogic.shouldLockScrollForCollapse(
          scrollOffset: 0,
          deltaY: 4,
        ),
        isTrue,
      );
      expect(
        QuranPlayerExpandedStageScrollDragLogic.shouldLockScrollForCollapse(
          scrollOffset: 12,
          deltaY: 4,
        ),
        isFalse,
      );
      expect(
        QuranPlayerExpandedStageScrollDragLogic.shouldLockScrollForQueueResize(
          scrollOffset: 0,
          deltaY: -3,
        ),
        isTrue,
      );
    });
  });

  group('QuranPlayerExpandedStageCollapsibleScrollRegion', () {
    testWidgets('downward drag at scroll top invokes vertical drag lifecycle', (
      tester,
    ) async {
      var started = false;
      var updated = 0;
      var ended = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 349,
            child: QuranPlayerExpandedStageCollapsibleScrollRegion(
              onVerticalDragStart: (_) => started = true,
              onVerticalDragUpdate: (_) => updated++,
              onVerticalDragEnd: (_) => ended = true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 48, child: Text('title')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byType(QuranPlayerExpandedStageCollapsibleScrollRegion),
        const Offset(0, 80),
      );

      expect(started, isTrue);
      expect(updated, greaterThan(0));
      expect(ended, isTrue);
    });

    testWidgets('does not arm collapse drag when content is scrolled down', (
      tester,
    ) async {
      var started = false;
      final ScrollController controller = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 120,
            child: QuranPlayerExpandedStageCollapsibleScrollRegion(
              scrollController: controller,
              onVerticalDragStart: (_) => started = true,
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              child: Column(
                children: List<Widget>.generate(
                  6,
                  (int i) => SizedBox(height: 48, child: Text('row $i')),
                ),
              ),
            ),
          ),
        ),
      );

      controller.jumpTo(72);
      await tester.pump();

      await tester.drag(find.byType(Scrollable), const Offset(0, 40));
      await tester.pump();

      expect(started, isFalse);
      expect(controller.offset, greaterThan(0));
    });
  });

  group('QuranPlayerExpandedStageDefaultLayout', () {
    testWidgets('does not overflow at 360x403 stage size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: QuranPlayerExpandedStageDefaultLayout(
              header: const SizedBox(height: 56),
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              centeredChrome: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 24,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(color: Colors.grey),
                  ),
                  const SizedBox(height: 56, child: Text('Surah')),
                ],
              ),
              playbackCluster: const SizedBox(height: 112),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.byType(QuranPlayerExpandedStageCollapsibleScrollRegion),
        findsOneWidget,
      );
    });

    testWidgets('downward drag on centered chrome invokes collapse drag', (
      tester,
    ) async {
      var started = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: QuranPlayerExpandedStageDefaultLayout(
              header: const SizedBox(height: 56),
              onVerticalDragStart: (_) => started = true,
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              centeredChrome: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(color: Colors.grey.shade400),
              ),
              playbackCluster: const SizedBox(height: 112),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byType(QuranPlayerExpandedStageCollapsibleScrollRegion),
        const Offset(0, 64),
      );

      expect(started, isTrue);
    });
  });
}
