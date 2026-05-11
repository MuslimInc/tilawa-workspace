import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/breakpoints.dart';
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
        bottomPlayer: const SizedBox.shrink(),
        child: const ColoredBox(color: Color(0xFFEEEEEE)),
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

    testWidgets('compact body has zero bottom MediaQuery padding', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewPadding);

      late EdgeInsets capturedPadding;
      await tester.pumpWidget(
        _wrap(
          direction: TextDirection.ltr,
          child: TilawaAdaptiveShell(
            destinations: _destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: Builder(
              builder: (context) {
                capturedPadding = MediaQuery.paddingOf(context);
                return const ColoredBox(color: Color(0xFFEEEEEE));
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(capturedPadding.bottom, 0.0);
    });

    testWidgets('compact hides bottom nav while keyboard is open', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        _wrap(
          direction: TextDirection.ltr,
          child: TilawaAdaptiveShell(
            destinations: _destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(InkWell), findsNothing);
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

    testInBothDirections('expanded uses collapsed side rail', (
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
      expect(rail.extended, isFalse);
    });

    testInBothDirections('large uses extended side rail', (
      tester,
      direction,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(1200, 900),
        direction: direction,
      );
      expect(find.byType(NavigationRail), findsOneWidget);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets(
      'expanded with selectedIndex -1 renders rail with no active item',
      (tester) async {
        await _pumpShell(
          tester,
          size: const Size(1000, 900),
          direction: TextDirection.ltr,
          selectedIndex: -1,
        );
        expect(find.byType(NavigationRail), findsOneWidget);
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, isNull);
      },
    );
  });

  group('TilawaAdaptiveShell — compact bottom nav density', () {
    testWidgets('five destinations at 360dp width do not throw', (
      tester,
    ) async {
      const destinations = <TilawaNavDestination>[
        TilawaNavDestination(label: 'Reciters', icon: Icons.person_outline),
        TilawaNavDestination(label: 'Prayer Times', icon: Icons.schedule),
        TilawaNavDestination(label: 'Quran', icon: Icons.menu_book_outlined),
        TilawaNavDestination(label: 'Athkar', icon: Icons.self_improvement),
        TilawaNavDestination(label: 'Settings', icon: Icons.settings_outlined),
      ];

      await tester.binding.setSurfaceSize(const Size(360, 800));
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          direction: TextDirection.ltr,
          child: TilawaAdaptiveShell(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'narrow inner width uses icons only with full semantics',
      (tester) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Reciters', icon: Icons.person_outline),
          TilawaNavDestination(label: 'Prayer Times', icon: Icons.schedule),
          TilawaNavDestination(label: 'Quran', icon: Icons.menu_book_outlined),
          TilawaNavDestination(label: 'Athkar', icon: Icons.self_improvement),
          TilawaNavDestination(
            label: 'Settings',
            icon: Icons.settings_outlined,
          ),
        ];

        await tester.binding.setSurfaceSize(const Size(360, 800));
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            direction: TextDirection.ltr,
            child: TilawaAdaptiveShell(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Reciters'), findsNothing);
        expect(find.text('Prayer Times'), findsNothing);
        expect(find.text('Quran'), findsNothing);
        expect(find.text('Athkar'), findsNothing);
        expect(find.text('Settings'), findsNothing);

        expect(
          tester.getSemantics(find.byIcon(Icons.person_outline)).label,
          'Reciters',
        );
        expect(
          tester.getSemantics(find.byIcon(Icons.schedule)).label,
          'Prayer Times',
        );
      },
    );

    testWidgets(
      'wide compact inner width keeps all destination labels visible',
      (tester) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Reciters', icon: Icons.person_outline),
          TilawaNavDestination(label: 'Prayer Times', icon: Icons.schedule),
          TilawaNavDestination(label: 'Quran', icon: Icons.menu_book_outlined),
          TilawaNavDestination(label: 'Athkar', icon: Icons.self_improvement),
          TilawaNavDestination(
            label: 'Settings',
            icon: Icons.settings_outlined,
          ),
        ];

        final width =
            TilawaBreakpoints.compactBottomNavAllLabelsMinInnerWidth.round() +
            32 +
            8;
        await tester.binding.setSurfaceSize(Size(width.toDouble(), 800));
        tester.view.physicalSize = Size(width.toDouble(), 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            direction: TextDirection.ltr,
            child: TilawaAdaptiveShell(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Reciters'), findsOneWidget);
        expect(find.text('Prayer Times'), findsOneWidget);
        expect(find.text('Quran'), findsOneWidget);
        expect(find.text('Athkar'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testInBothDirections(
      'icons only keeps Arabic destination titles in semantics',
      (tester, direction) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'القراء', icon: Icons.person_outline),
          TilawaNavDestination(label: 'أوقات الصلاة', icon: Icons.schedule),
          TilawaNavDestination(
            label: 'القرآن',
            icon: Icons.menu_book_outlined,
          ),
        ];

        await tester.binding.setSurfaceSize(const Size(360, 800));
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            direction: direction,
            child: TilawaAdaptiveShell(
              destinations: destinations,
              selectedIndex: 1,
              onDestinationSelected: (_) {},
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('أوقات الصلاة'), findsNothing);
        expect(find.text('القراء'), findsNothing);
        expect(find.text('القرآن'), findsNothing);
        expect(
          tester.getSemantics(find.byIcon(Icons.schedule)).label,
          'أوقات الصلاة',
        );
        expect(
          tester.getSemantics(find.byIcon(Icons.person_outline)).label,
          'القراء',
        );
      },
    );
  });

  group('TilawaAdaptiveShell — bottomPlayer visibility', () {
    testWidgets('compact layout renders bottomPlayer with expected size', (
      tester,
    ) async {
      const playerKey = Key('bottom_player');
      await tester.binding.setSurfaceSize(const Size(400, 800));
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          direction: TextDirection.ltr,
          child: TilawaAdaptiveShell(
            destinations: _destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox(
              key: playerKey,
              height: 80,
              width: double.infinity,
            ),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      // bottomPlayer is placed inside Positioned.fill, so it expands to the
      // full shell surface. Verify it is present and has non-zero dimensions.
      expect(find.byKey(playerKey), findsOneWidget);
      final size = tester.getSize(find.byKey(playerKey));
      expect(size.height, greaterThan(0));
      expect(size.width, greaterThan(0));
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
