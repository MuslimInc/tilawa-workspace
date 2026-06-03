import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_expanded_stage_gesture_scope.dart';
import 'package:tilawa/shared/widgets/quran_player_expanded_stage_layouts.dart';

void main() {
  group('QuranPlayerStageVerticalDragLogic', () {
    test('downward delta arms collapse once', () {
      expect(
        QuranPlayerStageVerticalDragLogic.shouldStartCollapseDrag(
          deltaY: 2,
          collapseDragActive: false,
        ),
        isTrue,
      );
      expect(
        QuranPlayerStageVerticalDragLogic.shouldStartCollapseDrag(
          deltaY: 2,
          collapseDragActive: true,
        ),
        isFalse,
      );
    });

    test('routes down to player and up to queue', () {
      expect(QuranPlayerStageVerticalDragLogic.routesToPlayerCollapse(1), isTrue);
      expect(
        QuranPlayerStageVerticalDragLogic.routesToPlayerCollapse(-1),
        isFalse,
      );
      expect(QuranPlayerStageVerticalDragLogic.routesToQueueResize(-1), isTrue);
      expect(QuranPlayerStageVerticalDragLogic.routesToQueueResize(1), isFalse);
    });

    test('applyQuranPlayerStageVerticalDragDelta arms and routes', () {
      var armed = false;
      var playerUpdates = 0;
      var queueUpdates = 0;

      applyQuranPlayerStageVerticalDragDelta(
        deltaY: 4,
        collapseDragActive: armed,
        onArmCollapseDrag: () => armed = true,
        onPlayerCollapseDragUpdate: (_) => playerUpdates++,
        onQueueSheetDragUp: (_) => queueUpdates++,
      );

      expect(armed, isTrue);
      expect(playerUpdates, 1);
      expect(queueUpdates, 0);

      applyQuranPlayerStageVerticalDragDelta(
        deltaY: 3,
        collapseDragActive: armed,
        onArmCollapseDrag: () => armed = true,
        onPlayerCollapseDragUpdate: (_) => playerUpdates++,
        onQueueSheetDragUp: (_) => queueUpdates++,
      );

      expect(playerUpdates, 2);

      applyQuranPlayerStageVerticalDragDelta(
        deltaY: -2,
        collapseDragActive: armed,
        onArmCollapseDrag: () {},
        onPlayerCollapseDragUpdate: (_) => playerUpdates++,
        onQueueSheetDragUp: (_) => queueUpdates++,
      );

      expect(queueUpdates, 1);
      expect(playerUpdates, 2);
    });
  });

  group('QuranPlayerExpandedStageGestureScope', () {
    testWidgets('tap on empty background invokes onCollapse', (tester) async {
      var collapsed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: QuranPlayerExpandedStageGestureScope(
              onCollapse: () => collapsed = true,
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.menu),
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(200, 300));
      expect(collapsed, isTrue);
    });

    testWidgets('tap on IconButton does not invoke onCollapse', (tester) async {
      var collapsed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: QuranPlayerExpandedStageGestureScope(
              onCollapse: () => collapsed = true,
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              child: Center(
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(collapsed, isFalse);
    });

    testWidgets('vertical drag down on empty area invokes drag lifecycle', (
      tester,
    ) async {
      var started = false;
      var ended = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: QuranPlayerExpandedStageGestureScope(
              onCollapse: () {},
              onVerticalDragStart: (_) => started = true,
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) => ended = true,
              child: const Column(
                children: [
                  SizedBox(height: 48, width: 360),
                  Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byType(QuranPlayerExpandedStageGestureScope),
        const Offset(0, 72),
      );

      expect(started, isTrue);
      expect(ended, isTrue);
    });

    testWidgets('vertical drag on IconButton does not start background drag', (
      tester,
    ) async {
      var started = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: QuranPlayerExpandedStageGestureScope(
              onCollapse: () {},
              onVerticalDragStart: (_) => started = true,
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              child: Center(
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                ),
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(IconButton)),
      );
      await gesture.moveBy(const Offset(0, 40));
      await gesture.up();

      expect(started, isFalse);
    });
  });

  group('QuranPlayerExpandedStageQueueFocusedLayout', () {
    testWidgets('does not overflow at 360x403 with tall content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return QuranPlayerExpandedStageQueueFocusedLayout(
                  maxHeight: constraints.maxHeight,
                  onVerticalDragStart: (_) {},
                  onVerticalDragUpdate: (_) {},
                  onVerticalDragEnd: (_) {},
                  children: [
                    Container(height: 56, color: Colors.red),
                    Container(height: 88, color: Colors.green),
                    Container(height: 240, color: Colors.blue),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolls when content exceeds viewport', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return QuranPlayerExpandedStageQueueFocusedLayout(
                  maxHeight: constraints.maxHeight,
                  onVerticalDragStart: (_) {},
                  onVerticalDragUpdate: (_) {},
                  onVerticalDragEnd: (_) {},
                  children: List<Widget>.generate(
                    8,
                    (int i) => SizedBox(height: 48, child: Text('row $i')),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsOneWidget);

      await tester.drag(find.byType(Scrollable), const Offset(0, -120));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'minHeight fill passes taps through to scope below short content',
      (tester) async {
      var collapsed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: QuranPlayerExpandedStageGestureScope(
              onCollapse: () => collapsed = true,
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return QuranPlayerExpandedStageQueueFocusedLayout(
                    maxHeight: constraints.maxHeight,
                    onVerticalDragStart: (_) {},
                    onVerticalDragUpdate: (_) {},
                    onVerticalDragEnd: (_) {},
                    children: const [
                      SizedBox(height: 48, width: 360),
                      SizedBox(height: 80, width: 360),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(180, 350));
      expect(collapsed, isTrue);
    });

    testWidgets('tap on scrollable content does not invoke scope onCollapse', (
      tester,
    ) async {
      var collapsed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: QuranPlayerExpandedStageGestureScope(
              onCollapse: () => collapsed = true,
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return QuranPlayerExpandedStageQueueFocusedLayout(
                    maxHeight: constraints.maxHeight,
                    onVerticalDragStart: (_) {},
                    onVerticalDragUpdate: (_) {},
                    onVerticalDragEnd: (_) {},
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 48,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 80, width: 360),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(180, 24));
      expect(collapsed, isFalse);
    });
  });

  group('QuranPlayerExpandedStageQueueFocusedLayout drag', () {
    testWidgets('downward drag on scroll region invokes vertical drag start', (
      tester,
    ) async {
      var started = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 403,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return QuranPlayerExpandedStageQueueFocusedLayout(
                  maxHeight: constraints.maxHeight,
                  onVerticalDragStart: (_) => started = true,
                  onVerticalDragUpdate: (_) {},
                  onVerticalDragEnd: (_) {},
                  children: const [
                    SizedBox(height: 48, width: 360),
                    SizedBox(height: 80, width: 360),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.drag(
        find.byType(QuranPlayerExpandedStageCollapsibleScrollRegion),
        const Offset(0, 48),
      );

      expect(started, isTrue);
    });
  });
}
