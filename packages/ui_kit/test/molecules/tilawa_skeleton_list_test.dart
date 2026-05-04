import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../lib/src/previews/preview_wrapper.dart';

void main() {
  group('TilawaSkeletonList', () {
    testWidgets('renders with default 3 items', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(body: TilawaSkeletonList(animate: false)),
        ),
      );

      await tester.pump();

      expect(find.byType(TilawaSkeletonList), findsOneWidget);
      expect(find.byType(TilawaSkeletonListTile), findsNWidgets(3));
    });

    testWidgets('renders with custom item count', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(
            body: TilawaSkeletonList(itemCount: 5, animate: false),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(TilawaSkeletonListTile), findsNWidgets(5));
    });

    testWidgets('passes linesPerItem to tiles', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(
            body: TilawaSkeletonList(
              itemCount: 1,
              linesPerItem: 3,
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // 1 tile with 3 lines = avatar + 3 text blocks = 4 blocks
      expect(find.byType(TilawaSkeletonBlock), findsNWidgets(4));
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(
            body: TilawaSkeletonList(
              itemCount: 1,
              padding: EdgeInsets.all(20),
              animate: false,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('respects animate: false', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(body: TilawaSkeletonList(animate: false)),
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
            child: Scaffold(body: TilawaSkeletonList(animate: true)),
          ),
        ),
      );

      await tester.pump();

      // No ShaderMask when reduced motion enabled
      expect(find.byType(ShaderMask), findsNothing);
    });
  });
}
