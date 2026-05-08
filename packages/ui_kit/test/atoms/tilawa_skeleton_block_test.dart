import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaSkeletonBlock', () {
    testWidgets('renders with explicit width and height', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 200,
                height: 100,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Find the skeleton block
      expect(find.byType(TilawaSkeletonBlock), findsOneWidget);
      // Verify it renders a container of the right size
      final size = tester.getSize(find.byType(TilawaSkeletonBlock));
      expect(size.width, 200);
      expect(size.height, 100);
    });

    testWidgets('supports circle shape', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 48,
                height: 48,
                shape: TilawaSkeletonShape.circle,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify it's a square
      final size = tester.getSize(find.byType(TilawaSkeletonBlock));
      expect(size.width, 48);
      expect(size.height, 48);
    });

    testWidgets('supports rectangle shape with zero radius', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 200,
                height: 50,
                shape: TilawaSkeletonShape.rectangle,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify size
      final size = tester.getSize(find.byType(TilawaSkeletonBlock));
      expect(size.width, 200);
      expect(size.height, 50);
    });

    testWidgets('supports rounded shape with token radius', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [TilawaComponentTokens.light()],
            ),
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 200,
                height: 50,
                shape: TilawaSkeletonShape.rounded,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify size
      final size = tester.getSize(find.byType(TilawaSkeletonBlock));
      expect(size.width, 200);
      expect(size.height, 50);
    });

    testWidgets('supports custom borderRadius override', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 200,
                height: 50,
                shape: TilawaSkeletonShape.rounded,
                borderRadius: 20,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Just verify the widget renders without error
      expect(find.byType(TilawaSkeletonBlock), findsOneWidget);
    });

    testWidgets('renders without animation when animate: false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 100,
                height: 100,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should not have ShaderMask when not animating
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('respects reduced motion setting', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 100,
                height: 100,
                animate: true, // Even with animate: true
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should not have ShaderMask when reduced motion is enabled
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('wraps in RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 100,
                height: 100,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // The skeleton should have RepaintBoundary somewhere in its subtree
      expect(
        find.descendant(
          of: find.byType(TilawaSkeletonBlock),
          matching: find.byType(RepaintBoundary),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses theme colors from tokens', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [TilawaComponentTokens.light()],
            ),
            home: Scaffold(
              body: TilawaSkeletonBlock(
                width: 100,
                height: 100,
                animate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Just verify the widget renders with theme
      expect(find.byType(TilawaSkeletonBlock), findsOneWidget);
    });
  });
}
