import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/app_colors.dart';
import '../../lib/src/foundation/app_theme.dart';
import '../../lib/src/foundation/component_tokens.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/foundation/safe_area_ext.dart';
import '../../lib/src/foundation/tilawa_interactive_surface.dart';
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
    theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
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

    testWidgets('phone bottom nav destinations suppress Material ink', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(360, 800),
        direction: TextDirection.ltr,
      );

      for (final inkWell in tester.widgetList<InkWell>(
        find.descendant(
          of: find.byKey(_bottomNavKey),
          matching: find.byType(InkWell),
        ),
      )) {
        expect(inkWell.splashColor, Colors.transparent);
        expect(inkWell.highlightColor, Colors.transparent);
        expect(inkWell.hoverColor, Colors.transparent);
      }

      expect(
        find.descendant(
          of: find.byKey(_bottomNavKey),
          matching: find.byType(TilawaInteractiveSurface),
        ),
        findsNWidgets(_destinations.length),
      );
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
            theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
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
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Library'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
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
      'narrow width shows labels on every destination',
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

        expect(find.text('Reciters'), findsOneWidget);
        expect(find.text('Prayer'), findsOneWidget);
        expect(find.text('Quran'), findsOneWidget);
        expect(find.text('Athkar'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

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

    testWidgets(
      'narrow width styles selected label with primary and bold weight',
      (tester) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'Reciters', icon: Icons.person_outline),
          TilawaNavDestination(label: 'Prayer', icon: Icons.schedule),
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

        final BuildContext context = tester.element(find.text('Reciters'));
        final ThemeData theme = Theme.of(context);
        final TextStyle selectedStyle = tester
            .widget<Text>(
              find.text('Reciters'),
            )
            .style!;
        final TextStyle unselectedStyle = tester
            .widget<Text>(
              find.text('Prayer'),
            )
            .style!;

        expect(selectedStyle.color, theme.colorScheme.primary);
        expect(
          selectedStyle.fontWeight,
          theme.componentTokens.adaptiveShell.navButtonSelectedLabelWeight,
        );
        expect(unselectedStyle.color, theme.colorScheme.onSurfaceVariant);
        expect(
          unselectedStyle.fontWeight,
          theme.componentTokens.adaptiveShell.navButtonUnselectedLabelWeight,
        );
      },
    );

    testInBothDirections(
      'narrow width shows Arabic labels on every tab',
      (tester, direction) async {
        const destinations = <TilawaNavDestination>[
          TilawaNavDestination(label: 'القراء', icon: Icons.person_outline),
          TilawaNavDestination(label: 'الصلاة', icon: Icons.schedule),
          TilawaNavDestination(
            label: 'المصحف',
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

        expect(find.text('الصلاة'), findsOneWidget);
        expect(find.text('القراء'), findsOneWidget);
        expect(find.text('المصحف'), findsOneWidget);

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
          dockContext.floatingBottomPadding,
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

    testWidgets('long press does not open radial or vertical selector', (
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

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.home_outlined)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(find.byKey(const Key('tilawa_bottom_nav_radial')), findsNothing);
      expect(find.byKey(const Key('tilawa_bottom_nav_vertical')), findsNothing);

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

  group('TilawaAdaptiveShell — bottom nav selection chrome', () {
    testWidgets('selected tab has no background pill indicator', (
      tester,
    ) async {
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
            selectedIndex: 1,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedPositionedDirectional), findsNothing);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('programmatic index change keeps no pill indicator', (
      tester,
    ) async {
      final drive = await _pumpDrivableShell(
        tester,
        size: const Size(400, 800),
        initialIndex: 0,
      );

      expect(find.byType(AnimatedPositionedDirectional), findsNothing);

      await drive(tester, 2);
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedPositionedDirectional), findsNothing);
    });

    testWidgets('user tap fires onDestinationSelected callback', (
      tester,
    ) async {
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
    });

    testWidgets('nav tap does not paint state-layer press wash', (
      tester,
    ) async {
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
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      final Finder navSurface = find.descendant(
        of: find.byKey(const Key('nav_button_1')),
        matching: find.byType(TilawaInteractiveSurface),
      );
      final TilawaInteractiveSurface surface = tester.widget(navSurface);
      expect(surface.enableInk, isFalse);
      expect(surface.enableStateLayer, isFalse);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('nav_button_1'))),
      );
      await tester.pump();

      final Iterable<DecoratedBox> washes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: navSurface,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color != null &&
                (widget.decoration as BoxDecoration).border == null,
          ),
        ),
      );
      expect(washes, isEmpty);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('profile destination shows label when unselected', (
      tester,
    ) async {
      final destinations = <TilawaNavDestination>[
        const TilawaNavDestination(
          label: 'Home',
          icon: Icons.home_outlined,
        ),
        TilawaNavDestination(
          label: 'Profile',
          icon: Icons.person_outline,
          selectionUsesBackground: false,
          iconBuilder:
              (
                BuildContext context, {
                required bool isSelected,
                required Color color,
              }) {
                return Icon(Icons.person_outline, color: color);
              },
        ),
      ];

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
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(AnimatedPositionedDirectional), findsNothing);
    });

    testWidgets('selected and unselected icons use the same scale', (
      tester,
    ) async {
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
            selectedIndex: 1,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      final AnimatedScale selectedScale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byKey(const Key('nav_button_1')),
          matching: find.byType(AnimatedScale),
        ),
      );
      final AnimatedScale unselectedScale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byKey(const Key('nav_button_0')),
          matching: find.byType(AnimatedScale),
        ),
      );

      expect(selectedScale.scale, unselectedScale.scale);
    });

    testWidgets('nav icon builders share the token icon box size', (
      tester,
    ) async {
      const double customAvatarSize = 28;
      final destinations = <TilawaNavDestination>[
        const TilawaNavDestination(
          label: 'Home',
          icon: Icons.home_outlined,
        ),
        TilawaNavDestination(
          label: 'Quran',
          icon: Icons.menu_book_outlined,
          iconBuilder:
              (
                BuildContext context, {
                required bool isSelected,
                required Color color,
              }) {
                return SizedBox(
                  width: customAvatarSize,
                  height: customAvatarSize,
                  child: Icon(Icons.menu_book_outlined, color: color),
                );
              },
        ),
      ];

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
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            child: const ColoredBox(color: Color(0xFFEEEEEE)),
          ),
        ),
      );
      await tester.pump();

      final ThemeData theme = Theme.of(
        tester.element(find.byType(TilawaAdaptiveShell)),
      );
      final double iconSize =
          theme.componentTokens.adaptiveShell.navButtonIconSize;

      for (final int index in <int>[0, 1]) {
        final Finder iconBox = find.descendant(
          of: find.byKey(Key('nav_button_$index')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SizedBox &&
                widget.width == iconSize &&
                widget.height == iconSize &&
                widget.child is Center &&
                (widget.child! as Center).child is FittedBox,
          ),
        );
        expect(iconBox, findsOneWidget);
        expect(tester.getSize(iconBox), Size(iconSize, iconSize));
      }
    });
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
      theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
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
