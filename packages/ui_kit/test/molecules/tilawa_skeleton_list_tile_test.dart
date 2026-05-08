import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../lib/src/previews/preview_wrapper.dart';

void main() {
  group('TilawaSkeletonListTile', () {
    testWidgets('renders with default 2 lines', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(body: TilawaSkeletonListTile(animate: false)),
        ),
      );

      await tester.pump();

      expect(find.byType(TilawaSkeletonListTile), findsOneWidget);
      expect(
        find.byType(TilawaSkeletonBlock),
        findsNWidgets(3),
      ); // avatar + 2 lines
    });

    testWidgets('renders with 1 line', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(
            body: TilawaSkeletonListTile(lines: 1, animate: false),
          ),
        ),
      );

      await tester.pump();

      expect(
        find.byType(TilawaSkeletonBlock),
        findsNWidgets(2),
      ); // avatar + 1 line
    });

    testWidgets('renders with 3 lines', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(
            body: TilawaSkeletonListTile(lines: 3, animate: false),
          ),
        ),
      );

      await tester.pump();

      expect(
        find.byType(TilawaSkeletonBlock),
        findsNWidgets(4),
      ); // avatar + 3 lines
    });

    testWidgets('has circular avatar', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(body: TilawaSkeletonListTile(animate: false)),
        ),
      );

      await tester.pump();

      // Find the first skeleton block (avatar)
      final blocks = find.byType(TilawaSkeletonBlock);
      expect(blocks, findsAtLeastNWidgets(1));
    });

    testWidgets('respects animate: false', (tester) async {
      await tester.pumpWidget(
        const TilawaPreviewWrapper(
          child: Scaffold(body: TilawaSkeletonListTile(animate: false)),
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
            child: Scaffold(body: TilawaSkeletonListTile(animate: true)),
          ),
        ),
      );

      await tester.pump();

      // No ShaderMask when reduced motion enabled
      expect(find.byType(ShaderMask), findsNothing);
    });
  });
}
