import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../lib/src/previews/preview_wrapper.dart';

void main() {
  group('TilawaSkeletonCard', () {
    testWidgets('renders with image and title', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(body: TilawaSkeletonCard(width: 200, animate: false)),
        ),
      );

      await tester.pump();

      expect(find.byType(TilawaSkeletonCard), findsOneWidget);
      expect(
        find.byType(TilawaSkeletonBlock),
        findsAtLeastNWidgets(2),
      ); // image + title
    });

    testWidgets('renders with subtitle when showSubtitle is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(
            body: TilawaSkeletonCard(
              width: 200,
              showSubtitle: true,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should have image + title + subtitle = 3 blocks
      expect(find.byType(TilawaSkeletonBlock), findsNWidgets(3));
    });

    testWidgets('renders without subtitle when showSubtitle is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(
            body: TilawaSkeletonCard(
              width: 200,
              showSubtitle: false,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should have image + title only = 2 blocks
      expect(find.byType(TilawaSkeletonBlock), findsNWidgets(2));
    });

    testWidgets('uses Flexible-wrapped AspectRatio for image', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(body: TilawaSkeletonCard(width: 200, animate: false)),
        ),
      );

      await tester.pump();

      final aspectRatioFinder = find.byType(AspectRatio);
      expect(aspectRatioFinder, findsOneWidget);
      expect(
        find.ancestor(of: aspectRatioFinder, matching: find.byType(Flexible)),
        findsOneWidget,
      );
    });

    testWidgets('respects animate: false', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(body: TilawaSkeletonCard(animate: false)),
        ),
      );

      await tester.pump();

      // No ShaderMask when not animating
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('respects reduced motion', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const TilawaPreviewWrapper(
            child: Scaffold(body: TilawaSkeletonCard(animate: true)),
          ),
        ),
      );

      await tester.pump();

      // No ShaderMask when reduced motion enabled
      expect(find.byType(ShaderMask), findsNothing);
    });
  });
}
