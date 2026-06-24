import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/app_colors.dart';
import '../../lib/src/foundation/app_theme.dart';
import '../../lib/src/foundation/component_tokens.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/organisms/tilawa_adaptive_shell.dart';
import '../rtl_test_matrix.dart';

const _bottomNavDockKey = Key('tilawa_bottom_nav_dock');
const _bottomNavKey = Key('tilawa_bottom_nav_bar');

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
    testInBothDirections('narrow window uses bottom nav', (
      tester,
      direction,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(400, 800),
        direction: direction,
      );
      // Narrow phone layout: Material bottom bar, no rail.
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(_bottomNavKey), findsOneWidget);
    });

    testWidgets('phone bottom nav uses sheet footer top border', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(400, 800),
        direction: TextDirection.ltr,
      );

      final BuildContext context = tester.element(
        find.byKey(_bottomNavDockKey),
      );
      final ThemeData theme = Theme.of(context);
      final DecoratedBox decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(_bottomNavDockKey),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).border?.top != null,
          ),
        ),
      );
      final BorderSide topBorder =
          (decoratedBox.decoration as BoxDecoration).border!.top;

      expect(
        topBorder.width,
        theme.componentTokens.bottomSheetScaffold.footerTopBorderWidth,
      );
      expect(topBorder.color, theme.colorScheme.outlineVariant);
    });

    testWidgets('phone bottom nav spans full viewport width', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(360, 800),
        direction: TextDirection.ltr,
      );

      final Rect dockRect = tester.getRect(find.byKey(_bottomNavDockKey));
      expect(dockRect.left, 0);
      expect(dockRect.width, 360);
    });

    testWidgets(
      'narrow bottom nav survives parent text scale clamped above 1.0',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 800));
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
            home: MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.2,
              maxScaleFactor: 2.0,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TilawaAdaptiveShell(
                  destinations: _destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  bottomPlayer: const SizedBox.shrink(),
                  child: const ColoredBox(color: Color(0xFFEEEEEE)),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(_bottomNavKey), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'narrow hides bottom nav when phoneBottomNavigationBarVisible is false',
      (tester) async {
        final visible = ValueNotifier<bool>(false);
        addTearDown(visible.dispose);

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
              phoneBottomNavigationBarVisible: visible,
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(_bottomNavKey), findsNothing);
      },
    );

    testWidgets(
      'narrow keeps phoneFooterAboveNav when bottom nav is hidden',
      (tester) async {
        const Key footerKey = Key('shell_footer_above_nav');
        final visible = ValueNotifier<bool>(false);
        addTearDown(visible.dispose);

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
              phoneBottomNavigationBarVisible: visible,
              phoneFooterAboveNav: const SizedBox(
                key: footerKey,
                height: 72,
                child: ColoredBox(color: Color(0xFF336699)),
              ),
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(_bottomNavKey), findsNothing);
        expect(find.byKey(footerKey), findsOneWidget);
      },
    );

    testWidgets(
      'narrow docks phoneFooterAboveNav flush with visible bottom nav',
      (tester) async {
        const Key footerKey = Key('shell_footer_above_nav');

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
              phoneFooterAboveNav: const SizedBox(
                key: footerKey,
                height: 72,
                child: ColoredBox(color: Color(0xFF336699)),
              ),
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        final Rect footerRect = tester.getRect(find.byKey(footerKey));
        final Rect bottomNavRect = tester.getRect(
          find.byKey(_bottomNavDockKey),
        );

        expect(footerRect.bottom, bottomNavRect.top);
      },
    );

    testWidgets('narrow body has zero bottom MediaQuery padding', (
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

    testWidgets('narrow keeps bottom nav visible while keyboard is open', (
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

      late double bodyBottom;
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
                bodyBottom = MediaQuery.paddingOf(context).bottom;
                return const ColoredBox(color: Color(0xFFEEEEEE));
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(bodyBottom, 0.0);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(_bottomNavKey), findsOneWidget);
    });

    testInBothDirections('medium window uses bottom nav', (
      tester,
      direction,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(700, 900),
        direction: direction,
      );
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(_bottomNavKey), findsOneWidget);
    });

    testInBothDirections('expanded window uses bottom nav', (
      tester,
      direction,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(1000, 900),
        direction: direction,
      );
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(_bottomNavKey), findsOneWidget);
    });

    testInBothDirections('large window uses bottom nav', (
      tester,
      direction,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(1200, 900),
        direction: direction,
      );
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(_bottomNavKey), findsOneWidget);
    });

    testWidgets(
      'expanded with selectedIndex -1 renders bottom nav with no active item',
      (tester) async {
        await _pumpShell(
          tester,
          size: const Size(1000, 900),
          direction: TextDirection.ltr,
          selectedIndex: -1,
        );
        expect(find.byKey(_bottomNavKey), findsOneWidget);
        expect(find.text('Home'), findsNothing);
        expect(find.text('Library'), findsNothing);
      },
    );
  });

  group('TilawaAdaptiveShell — phone bottom nav sizing', () {
    testWidgets('five destinations at 360dp width do not throw', (
      tester,
    ) async {
      const destinations = <TilawaNavDestination>[
        TilawaNavDestination(label: 'Reciters', icon: Icons.person_outline),
        TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
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
      'narrow width exposes destination labels through semantics only',
      (tester) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Reciters', icon: Icons.person_outline),
          TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
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
        expect(find.text('Prayer'), findsNothing);
        expect(find.text('Quran'), findsNothing);
        expect(find.text('Athkar'), findsNothing);
        expect(find.text('Settings'), findsNothing);

        expect(
          tester.getSemantics(find.byIcon(Icons.person_outline)).label,
          startsWith('Reciters'),
        );
        expect(
          tester.getSemantics(find.byIcon(Icons.schedule)).label,
          startsWith('Prayer'),
        );
      },
    );

    testInBothDirections(
      'narrow width exposes Arabic destination labels through semantics only',
      (tester, direction) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'القراء', icon: Icons.person_outline),
          TilawaNavDestination(label: 'الصلاة', icon: Icons.schedule),
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

        expect(find.text('الصلاة'), findsNothing);
        expect(find.text('القراء'), findsNothing);

        expect(
          tester.getSemantics(find.byIcon(Icons.schedule)).label,
          startsWith('الصلاة'),
        );
        expect(
          tester.getSemantics(find.byIcon(Icons.person_outline)).label,
          startsWith('القراء'),
        );
      },
    );

    testWidgets(
      'bottom nav outer height includes system navigation view padding',
      (tester) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'القراء', icon: Icons.person_outline),
          TilawaNavDestination(label: 'الصلاة', icon: Icons.schedule),
        ];
        const systemInset = 48.0;

        await tester.binding.setSurfaceSize(const Size(360, 800));
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        tester.view.viewPadding = const FakeViewPadding(bottom: systemInset);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewPadding);

        await tester.pumpWidget(
          _wrap(
            direction: TextDirection.rtl,
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

        final BuildContext dockContext = tester.element(
          find.byKey(_bottomNavDockKey),
        );
        final tokens = Theme.of(dockContext).componentTokens.adaptiveShell;
        final double bottomBarTextScale = MediaQuery.textScalerOf(
          dockContext,
        ).scale(1.0).clamp(0.01, 1.0);
        final double expectedHeight = tokens.phoneBottomNavPaintedHeight(
          TextScaler.linear(bottomBarTextScale),
          systemInset,
        );

        final Rect dockRect = tester.getRect(find.byKey(_bottomNavDockKey));
        expect(dockRect.height, closeTo(expectedHeight, 1.0));

        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      },
    );

    testWidgets(
      'bottom nav is centered and supports horizontal swipe between destinations',
      (tester) async {
        var selectedIndex = 0;
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
          TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
          TilawaNavDestination(label: 'Settings', icon: Icons.settings),
        ];

        await tester.binding.setSurfaceSize(const Size(360, 800));
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        Future<void> pumpShell() {
          return tester.pumpWidget(
            _wrap(
              direction: TextDirection.rtl,
              child: TilawaAdaptiveShell(
                destinations: destinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  selectedIndex = index;
                },
                onAdjacentDestinationSelected: (direction) {
                  final int delta = switch (direction) {
                    TilawaNavAdjacentDirection.next => 1,
                    TilawaNavAdjacentDirection.previous => -1,
                  };
                  selectedIndex =
                      (selectedIndex + delta + destinations.length) %
                      destinations.length;
                },
                bottomPlayer: const SizedBox.shrink(),
                child: const ColoredBox(color: Color(0xFFEEEEEE)),
              ),
            ),
          );
        }

        await pumpShell();
        await tester.pump();

        final Rect barRect = tester.getRect(
          find.byKey(const Key('tilawa_bottom_nav_bar')),
        );
        expect(barRect.center.dx, closeTo(180, 24));

        await tester.fling(
          find.byKey(const Key('tilawa_bottom_nav_bar')),
          const Offset(-300, 0),
          1200,
        );
        await pumpShell();
        await tester.pumpAndSettle();
        expect(selectedIndex, 1);

        await tester.fling(
          find.byKey(const Key('tilawa_bottom_nav_bar')),
          const Offset(300, 0),
          1200,
        );
        await pumpShell();
        await tester.pumpAndSettle();
        expect(selectedIndex, 0);
      },
    );

    testWidgets('long press opens radial selector and release commits focus', (
      tester,
    ) async {
      var selectedIndex = 0;
      const destinations = <TilawaNavDestination>[
        TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
        TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
        TilawaNavDestination(label: 'Settings', icon: Icons.settings),
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
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => selectedIndex = index,
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      final Finder homeIcon = find.byIcon(Icons.home_outlined);
      expect(homeIcon, findsOneWidget);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(homeIcon),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.byKey(const Key('tilawa_bottom_nav_radial')), findsOneWidget);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byKey(const Key('tilawa_bottom_nav_radial')), findsNothing);
      expect(selectedIndex, 0);
    });

    testWidgets(
      'RTL radial arc mirrors bar order with home on physical right',
      (
        tester,
      ) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
          TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
          TilawaNavDestination(label: 'Settings', icon: Icons.settings),
        ];

        await tester.binding.setSurfaceSize(const Size(360, 800));
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            direction: TextDirection.rtl,
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

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.home_outlined)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        final Finder radial = find.byKey(const Key('tilawa_bottom_nav_radial'));
        expect(radial, findsOneWidget);

        final double homeDx = tester
            .getCenter(
              find.descendant(
                of: radial,
                matching: find.byIcon(Icons.home_outlined),
              ),
            )
            .dx;
        final double prayerDx = tester
            .getCenter(
              find.descendant(
                of: radial,
                matching: find.byIcon(Icons.schedule),
              ),
            )
            .dx;
        final double settingsDx = tester
            .getCenter(
              find.descendant(
                of: radial,
                matching: find.byIcon(Icons.settings),
              ),
            )
            .dx;

        expect(homeDx, greaterThan(prayerDx));
        expect(prayerDx, greaterThan(settingsDx));

        await gesture.up();
        await tester.pump();
      },
    );

    testWidgets('vertical long press does not grow bottom nav dock height', (
      tester,
    ) async {
      const destinations = <TilawaNavDestination>[
        TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
        TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
        TilawaNavDestination(label: 'Quran', icon: Icons.menu_book_outlined),
        TilawaNavDestination(label: 'Library', icon: Icons.bookmark_outline),
        TilawaNavDestination(label: 'Qibla', icon: Icons.explore_outlined),
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
          direction: TextDirection.rtl,
          child: TilawaAdaptiveShell(
            destinations: destinations,
            selectedIndex: 0,
            phoneBottomNavLongPressMode:
                TilawaPhoneBottomNavLongPressMode.verticalRight,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      final double idleDockHeight = tester
          .getSize(find.byKey(_bottomNavDockKey))
          .height;

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.home_outlined)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('tilawa_bottom_nav_vertical')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(_bottomNavDockKey)).height,
        closeTo(idleDockHeight, 1.0),
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('vertical long press stacks items on physical right', (
      tester,
    ) async {
      const destinations = <TilawaNavDestination>[
        TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
        TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
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
            phoneBottomNavLongPressMode:
                TilawaPhoneBottomNavLongPressMode.verticalRight,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.home_outlined)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final Finder vertical = find.byKey(
        const Key('tilawa_bottom_nav_vertical'),
      );
      expect(vertical, findsOneWidget);
      expect(find.byKey(const Key('tilawa_bottom_nav_radial')), findsNothing);

      final double homeDy = tester
          .getCenter(
            find.descendant(
              of: vertical,
              matching: find.byIcon(Icons.home_outlined),
            ),
          )
          .dy;
      final double settingsDy = tester
          .getCenter(
            find.descendant(
              of: vertical,
              matching: find.byIcon(Icons.settings_outlined),
            ),
          )
          .dy;
      final double homeDx = tester
          .getCenter(
            find.descendant(
              of: vertical,
              matching: find.byIcon(Icons.home_outlined),
            ),
          )
          .dx;

      expect(homeDy, greaterThan(settingsDy));
      expect(homeDx, lessThan(140));

      await gesture.up();
      await tester.pump();
    });

    testWidgets(
      'vertical long press on last index anchors last item at thumb',
      (tester) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
          TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
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
              selectedIndex: 2,
              phoneBottomNavLongPressMode:
                  TilawaPhoneBottomNavLongPressMode.verticalRight,
              onDestinationSelected: (_) {},
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.settings_outlined)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        final Finder vertical = find.byKey(
          const Key('tilawa_bottom_nav_vertical'),
        );
        expect(vertical, findsOneWidget);

        final double homeDy = tester
            .getCenter(
              find.descendant(
                of: vertical,
                matching: find.byIcon(Icons.home_outlined),
              ),
            )
            .dy;
        final double settingsDy = tester
            .getCenter(
              find.descendant(
                of: vertical,
                matching: find.byIcon(Icons.settings_outlined),
              ),
            )
            .dy;
        final double settingsDx = tester
            .getCenter(
              find.descendant(
                of: vertical,
                matching: find.byIcon(Icons.settings_outlined),
              ),
            )
            .dx;

        expect(settingsDy, greaterThan(homeDy));
        expect(settingsDx, greaterThan(180));

        await gesture.up();
        await tester.pump();
      },
    );

    testWidgets(
      'verticalRight mode uses radial selector for middle destinations',
      (tester) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
          TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
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
              selectedIndex: 1,
              phoneBottomNavLongPressMode:
                  TilawaPhoneBottomNavLongPressMode.verticalRight,
              onDestinationSelected: (_) {},
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.schedule)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();

        expect(
          find.byKey(const Key('tilawa_bottom_nav_radial')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('tilawa_bottom_nav_vertical')),
          findsNothing,
        );

        await gesture.up();
        await tester.pump();
      },
    );

    testWidgets(
      'RTL vertical long press on last index anchors last item at thumb',
      (tester) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
          TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
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
            direction: TextDirection.rtl,
            child: TilawaAdaptiveShell(
              destinations: destinations,
              selectedIndex: 2,
              phoneBottomNavLongPressMode:
                  TilawaPhoneBottomNavLongPressMode.verticalRight,
              onDestinationSelected: (_) {},
              bottomPlayer: const SizedBox.shrink(),
              child: const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
          ),
        );
        await tester.pump();

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.settings_outlined)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        final Finder vertical = find.byKey(
          const Key('tilawa_bottom_nav_vertical'),
        );
        expect(vertical, findsOneWidget);

        final double homeDy = tester
            .getCenter(
              find.descendant(
                of: vertical,
                matching: find.byIcon(Icons.home_outlined),
              ),
            )
            .dy;
        final double settingsDy = tester
            .getCenter(
              find.descendant(
                of: vertical,
                matching: find.byIcon(Icons.settings_outlined),
              ),
            )
            .dy;
        final double settingsDx = tester
            .getCenter(
              find.descendant(
                of: vertical,
                matching: find.byIcon(Icons.settings_outlined),
              ),
            )
            .dx;

        expect(settingsDy, greaterThan(homeDy));
        expect(settingsDx, lessThan(140));

        await gesture.up();
        await tester.pump();
      },
    );

    testWidgets('RTL vertical stack keeps home above pressed home on right', (
      tester,
    ) async {
      const destinations = <TilawaNavDestination>[
        TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
        TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
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
          direction: TextDirection.rtl,
          child: TilawaAdaptiveShell(
            destinations: destinations,
            selectedIndex: 0,
            phoneBottomNavLongPressMode:
                TilawaPhoneBottomNavLongPressMode.verticalRight,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.home_outlined)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      final Finder vertical = find.byKey(
        const Key('tilawa_bottom_nav_vertical'),
      );
      expect(vertical, findsOneWidget);

      final double homeDy = tester
          .getCenter(
            find.descendant(
              of: vertical,
              matching: find.byIcon(Icons.home_outlined),
            ),
          )
          .dy;
      final double settingsDy = tester
          .getCenter(
            find.descendant(
              of: vertical,
              matching: find.byIcon(Icons.settings_outlined),
            ),
          )
          .dy;
      final double homeDx = tester
          .getCenter(
            find.descendant(
              of: vertical,
              matching: find.byIcon(Icons.home_outlined),
            ),
          )
          .dx;

      expect(homeDy, greaterThan(settingsDy));
      expect(homeDx, greaterThan(180));

      await gesture.up();
      await tester.pump();
    });
  });

  group('TilawaAdaptiveShell — bottomPlayer visibility', () {
    testWidgets('narrow layout renders bottomPlayer with expected size', (
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
            bottomPlayer: const ColoredBox(
              key: playerKey,
              color: Color(0xFFFF0000),
            ),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      // [Positioned.fill] expands the bottom slot to the body; verify it
      // receives non-zero layout after the scaffold lays out.
      expect(find.byKey(playerKey), findsOneWidget);
      final size = tester.getSize(find.byKey(playerKey));
      expect(size.height, greaterThan(0));
      expect(size.width, greaterThan(0));
    });
  });

  group('TilawaAdaptiveShell — scaffold canvas', () {
    testWidgets('phone and wide layouts use theme scaffoldBackgroundColor', (
      tester,
    ) async {
      final ThemeData theme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      final Color expectedCanvas = theme.scaffoldBackgroundColor;

      for (final Size size in <Size>[
        const Size(400, 800),
        const Size(1000, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: TilawaAdaptiveShell(
              destinations: _destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              bottomPlayer: const SizedBox.shrink(),
              child: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pump();

        final Scaffold scaffold = tester.widget<Scaffold>(
          find.byType(Scaffold).first,
        );
        expect(
          scaffold.backgroundColor,
          expectedCanvas,
          reason: 'size $size',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Programmatic index-change attention animation
  //
  // CONTRACT: When the bottom nav's selected index changes through a prop update
  // (not from inside the widget via onDestinationSelected), the newly selected
  // icon plays a brief scale pulse (1.0 → peak → 1.0) so the user notices the
  // change. User taps and the initial first-frame selection must NOT trigger
  // this animation.
  //
  // Key used to find the ScaleTransition wrapper: Key('nav_pulse_<index>').
  // ---------------------------------------------------------------------------
  group('programmatic index-change attention animation', () {
    testWidgets(
      // CONTRACT: initial selection must not trigger the pulse animation.
      'initial selected index does not trigger pulse animation',
      (tester) async {
        await _pumpDrivableShell(
          tester,
          size: const Size(400, 800),
          initialIndex: 0,
        );

        final pulse = _findNavPulse(tester, 0);
        expect(pulse, isNotNull, reason: 'pulse widget should exist');
        // Animation must be idle at scale = 1.0 on first frame.
        expect(
          pulse!.scale.value,
          closeTo(1.0, 0.001),
          reason: 'no pulse on initial render',
        );
      },
    );

    testWidgets(
      // CONTRACT: programmatic index change triggers the pulse mid-animation.
      'programmatic index change triggers pulse on newly selected item',
      (tester) async {
        final drive = await _pumpDrivableShell(
          tester,
          size: const Size(400, 800),
          initialIndex: 0,
        );

        // Programmatically move to index 1 (not via onDestinationSelected).
        await drive(tester, 1);
        // 30 ms into the animation — scale should be above 1.0 (rising phase).
        await tester.pump(const Duration(milliseconds: 30));

        final pulse = _findNavPulse(tester, 1);
        expect(pulse, isNotNull);
        expect(
          pulse!.scale.value,
          greaterThan(1.0),
          reason:
              'scale should be above 1.0 mid-pulse after programmatic change',
        );
      },
    );

    testWidgets(
      // CONTRACT: user tap must NOT trigger the pulse animation.
      'user tap on nav item does not trigger pulse animation',
      (tester) async {
        await _pumpDrivableShell(
          tester,
          size: const Size(400, 800),
          initialIndex: 0,
        );

        // Simulate a real user tap on destination index 1.
        await tester.tap(find.byKey(const Key('nav_button_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));

        final pulse = _findNavPulse(tester, 1);
        expect(pulse, isNotNull);
        expect(
          pulse!.scale.value,
          closeTo(1.0, 0.001),
          reason: 'user tap must not trigger scale pulse',
        );
      },
    );

    testWidgets(
      // CONTRACT: animation returns to 1.0 after completing.
      'pulse animation returns to scale 1.0 after completing',
      (tester) async {
        final drive = await _pumpDrivableShell(
          tester,
          size: const Size(400, 800),
          initialIndex: 0,
        );

        await drive(tester, 2);
        // Let the full animation complete (> 300 ms total).
        await tester.pump(const Duration(milliseconds: 350));

        final pulse = _findNavPulse(tester, 2);
        expect(pulse, isNotNull);
        expect(
          pulse!.scale.value,
          closeTo(1.0, 0.001),
          reason: 'scale must settle back to 1.0 after animation completes',
        );
      },
    );

    testWidgets(
      // CONTRACT: existing onDestinationSelected still fires on user tap.
      'user tap still fires onDestinationSelected callback',
      (tester) async {
        int? tappedIndex;
        await _pumpDrivableShell(
          tester,
          size: const Size(400, 800),
          initialIndex: 0,
          onDestinationSelected: (i) => tappedIndex = i,
        );

        await tester.tap(find.byKey(const Key('nav_button_2')));
        await tester.pump();

        expect(tappedIndex, 2);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers for programmatic-index-change tests
// ---------------------------------------------------------------------------

/// A [ChangeNotifier] that drives [selectedIndex] on [TilawaAdaptiveShell]
/// from outside the widget tree, simulating a programmatic tab change
/// (e.g. MainScreenCubit.selectTab).
class _NavShellController extends ChangeNotifier {
  _NavShellController(int initialIndex) : _index = initialIndex;

  int _index;
  int get index => _index;
  set index(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }
}

/// Pumps a [TilawaAdaptiveShell] driven by a [_NavShellController] and
/// returns a drive function that changes the index programmatically
/// (without going through [onDestinationSelected]).
///
/// The returned drive function signature is:
///   `Future<void> Function(WidgetTester tester, int newIndex)`
Future<Future<void> Function(WidgetTester, int)> _pumpDrivableShell(
  WidgetTester tester, {
  required Size size,
  int initialIndex = 0,
  ValueChanged<int>? onDestinationSelected,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = _NavShellController(initialIndex);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => TilawaAdaptiveShell(
            destinations: _destinations,
            selectedIndex: controller.index,
            onDestinationSelected: (i) {
              onDestinationSelected?.call(i);
              controller.index = i;
            },
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return (WidgetTester t, int newIndex) async {
    controller.index = newIndex;
    await t.pump();
  };
}

/// Finds the [ScaleTransition] for a given nav destination [index] using
/// the key `Key('nav_pulse_<index>')`.  Returns `null` if not found.
ScaleTransition? _findNavPulse(WidgetTester tester, int index) {
  final finder = find.byKey(Key('nav_pulse_$index'));
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<ScaleTransition>(finder);
}
