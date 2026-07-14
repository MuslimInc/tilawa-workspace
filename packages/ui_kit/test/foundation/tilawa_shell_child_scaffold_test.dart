import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  final ThemeData theme = AppTheme.getLightTheme(
    primaryColor: AppColors.defaultPrimary,
  );

  Widget wrap({
    required Widget child,
    Size size = const Size(360, 800),
    double textScale = 1,
    TextDirection textDirection = TextDirection.ltr,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        viewInsets: viewInsets,
      ),
      child: MaterialApp(
        theme: theme,
        home: Directionality(
          textDirection: textDirection,
          child: child,
        ),
      ),
    );
  }

  group('TilawaShellChildScaffold', () {
    testWidgets('defaults resizeToAvoidBottomInset to false', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const TilawaShellChildScaffold(
            body: Text('body'),
          ),
        ),
      );

      final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.resizeToAvoidBottomInset, isFalse);
      expect(find.byType(TilawaShellChildScaffold), findsOneWidget);
    });

    testWidgets('allows explicit resize override', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const TilawaShellChildScaffold(
            resizeToAvoidBottomInset: true,
            body: Text('body'),
          ),
        ),
      );

      final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.resizeToAvoidBottomInset, isTrue);
    });
  });

  group('TilawaAdaptiveShell keyboard ownership', () {
    Future<void> pumpShellWithChild(
      WidgetTester tester, {
      required Size size,
      required double keyboardInset,
      required TextDirection textDirection,
      double textScale = 1,
    }) async {
      await tester.pumpWidget(
        wrap(
          size: size,
          textScale: textScale,
          textDirection: textDirection,
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
          child: TilawaAdaptiveShell(
            destinations: const [
              TilawaNavDestination(
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
              ),
              TilawaNavDestination(
                label: 'More',
                icon: Icons.menu_outlined,
                activeIcon: Icons.menu,
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bottomPlayer: const SizedBox.shrink(),
            phoneBottomNavigationBarVisible: const AlwaysStoppedAnimation<bool>(
              false,
            ),
            child: TilawaShellChildScaffold(
              appBar: AppBar(title: const Text('Hub')),
              body: ListView(
                children: const [
                  SizedBox(height: 48, child: TextField()),
                  SizedBox(height: 400, child: Text('tail')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> expectNoNestedResizeAndFieldVisible(
      WidgetTester tester, {
      required Size size,
      required double keyboardInset,
      required TextDirection textDirection,
      double textScale = 1,
    }) async {
      await pumpShellWithChild(
        tester,
        size: size,
        keyboardInset: keyboardInset,
        textDirection: textDirection,
        textScale: textScale,
      );

      final Iterable<Scaffold> scaffolds = tester.widgetList<Scaffold>(
        find.byType(Scaffold),
      );
      // Outer shell + inner shell-child.
      expect(scaffolds.length, greaterThanOrEqualTo(2));
      expect(
        scaffolds.any((s) => s.resizeToAvoidBottomInset == true),
        isTrue,
        reason: 'shell must own IME resize',
      );
      expect(
        tester
            .widget<Scaffold>(
              find.descendant(
                of: find.byType(TilawaShellChildScaffold),
                matching: find.byType(Scaffold),
              ),
            )
            .resizeToAvoidBottomInset,
        isFalse,
      );

      final Size fieldSize = tester.getSize(find.byType(TextField));
      expect(fieldSize.height, greaterThan(0));
      expect(tester.takeException(), isNull);

      // Body above the IME: field top stays within the shrunk viewport.
      final double fieldTop = tester.getTopLeft(find.byType(TextField)).dy;
      expect(fieldTop, lessThan(size.height - keyboardInset));
    }

    testWidgets('short Android LTR — nested child does not double-shrink', (
      tester,
    ) async {
      await expectNoNestedResizeAndFieldVisible(
        tester,
        size: const Size(360, 640),
        keyboardInset: 280,
        textDirection: TextDirection.ltr,
      );
    });

    testWidgets('tall Android RTL + large text scale', (tester) async {
      await expectNoNestedResizeAndFieldVisible(
        tester,
        size: const Size(412, 915),
        keyboardInset: 320,
        textDirection: TextDirection.rtl,
        textScale: 1.4,
      );
    });

    testWidgets('shell Scaffold resize flag is explicit true', (tester) async {
      await pumpShellWithChild(
        tester,
        size: const Size(360, 800),
        keyboardInset: 0,
        textDirection: TextDirection.ltr,
      );

      final Scaffold shellScaffold = tester
          .widgetList<Scaffold>(
            find.byType(Scaffold),
          )
          .firstWhere((s) => s.resizeToAvoidBottomInset == true);

      expect(shellScaffold.resizeToAvoidBottomInset, isTrue);
    });
  });
}
