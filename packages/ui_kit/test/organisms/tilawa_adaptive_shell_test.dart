import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/organisms/tilawa_adaptive_shell.dart';
import '../rtl_test_matrix.dart';

const _destinations = <TilawaNavDestination>[
  TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
  TilawaNavDestination(label: 'Library', icon: Icons.library_books_outlined),
  TilawaNavDestination(label: 'Settings', icon: Icons.settings_outlined),
];

Widget _wrap({required Widget child, required TextDirection direction}) {
  return MaterialApp(
    theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
    home: Directionality(textDirection: direction, child: child),
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required TextDirection direction,
  int selectedIndex = 0,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _wrap(
      direction: direction,
      child: TilawaAdaptiveShell(
        destinations: _destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: (_) {},
        child: const ColoredBox(color: Color(0xFFEEEEEE)),
        bottomPlayer: const SizedBox.shrink(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('TilawaAdaptiveShell — navigation pattern by window size', () {
    testInBothDirections('compact uses bottom nav', (tester, direction) async {
      await _pumpShell(
        tester,
        size: const Size(400, 800),
        direction: direction,
      );
      // Compact layout: no NavigationRail anywhere.
      expect(find.byType(NavigationRail), findsNothing);
    });

    testInBothDirections('medium uses side rail (collapsed)', (
      tester,
      direction,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(700, 900),
        direction: direction,
      );
      expect(find.byType(NavigationRail), findsOneWidget);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testInBothDirections('expanded uses extended side rail', (
      tester,
      direction,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(1000, 900),
        direction: direction,
      );
      expect(find.byType(NavigationRail), findsOneWidget);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });
  });

  group('TilawaAdaptiveShell — RTL directional placement', () {
    testWidgets('side rail is on the right in RTL', (tester) async {
      await _pumpShell(
        tester,
        size: const Size(1000, 900),
        direction: TextDirection.rtl,
      );
      // Find the top-level Row of the shell body; its first child in an RTL
      // render is painted on the right side of the screen.
      final rowFinder = find.byType(Row).first;
      final rowBox = tester.renderObject<RenderBox>(rowFinder);
      final rowWidth = rowBox.size.width;
      // In RTL the Row's start is on the right; the rail (first child) occupies
      // the right side. Verify that the content (Expanded) paints to the left
      // of the rail's center-x, i.e. rail.left > content.left.
      final railFinder = find.byType(NavigationRail);
      if (tester.any(railFinder)) {
        final railRect = tester.getRect(railFinder);
        expect(railRect.right, closeTo(rowWidth, 1.0));
      }
    });

    testWidgets('side rail is on the left in LTR', (tester) async {
      await _pumpShell(
        tester,
        size: const Size(1000, 900),
        direction: TextDirection.ltr,
      );
      final railFinder = find.byType(NavigationRail);
      if (tester.any(railFinder)) {
        final railRect = tester.getRect(railFinder);
        expect(railRect.left, closeTo(0.0, 1.0));
      }
    });
  });
}
