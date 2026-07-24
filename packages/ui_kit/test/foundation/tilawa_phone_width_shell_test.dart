import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../rtl_test_matrix.dart';

class _SizeProbe extends StatelessWidget {
  const _SizeProbe({required this.onBuild});

  final ValueChanged<Size> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(MediaQuery.sizeOf(context));
    return const ColoredBox(
      color: Color(0xFF00FF00),
      child: SizedBox.expand(),
    );
  }
}

Future<void> _setView(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _harness({
  required Size viewSize,
  required TextDirection direction,
  required ThemeData theme,
  required Widget child,
  double? maxContentWidth,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: viewSize,
      padding: const EdgeInsets.fromLTRB(12, 24, 18, 16),
      viewPadding: const EdgeInsets.fromLTRB(12, 24, 18, 16),
      viewInsets: const EdgeInsets.only(bottom: 40),
    ),
    child: Directionality(
      textDirection: direction,
      child: Theme(
        data: theme,
        child: TilawaPhoneWidthShell(
          maxContentWidth:
              maxContentWidth ?? TilawaBreakpoints.narrowUpperBound,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('TilawaPhoneWidthShell', () {
    testInBothDirections('phone width is pass-through', (
      tester,
      direction,
    ) async {
      const Size phone = Size(390, 844);
      await _setView(tester, phone);

      late Size reported;
      final GlobalKey childKey = GlobalKey();
      await pumpWithDirection(
        tester,
        _harness(
          viewSize: phone,
          direction: direction,
          theme: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
          child: KeyedSubtree(
            key: childKey,
            child: _SizeProbe(onBuild: (size) => reported = size),
          ),
        ),
        direction,
      );

      expect(tester.getSize(find.byKey(childKey)).width, phone.width);
      expect(reported.width, phone.width);
      expect(reported.height, phone.height);
      expect(tester.takeException(), isNull);
    });

    testInBothDirections('tablet width centers and caps at maxContentWidth', (
      tester,
      direction,
    ) async {
      const Size tablet = Size(1024, 1366);
      await _setView(tester, tablet);

      late Size reported;
      final GlobalKey childKey = GlobalKey();
      await pumpWithDirection(
        tester,
        _harness(
          viewSize: tablet,
          direction: direction,
          theme: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
          child: KeyedSubtree(
            key: childKey,
            child: _SizeProbe(onBuild: (size) => reported = size),
          ),
        ),
        direction,
      );

      const double maxWidth = TilawaBreakpoints.narrowUpperBound;
      final Size childSize = tester.getSize(find.byKey(childKey));
      expect(childSize.width, maxWidth);
      expect(childSize.height, tablet.height);

      final Offset topLeft = tester.getTopLeft(find.byKey(childKey));
      final Offset topRight = tester.getTopRight(find.byKey(childKey));
      final double sideInset = (tablet.width - maxWidth) / 2;
      expect(topLeft.dx, closeTo(sideInset, 0.5));
      expect(topRight.dx, closeTo(tablet.width - sideInset, 0.5));

      expect(reported.width, maxWidth);
      expect(reported.height, tablet.height);
      expect(tester.takeException(), isNull);
    });

    testInBothDirections('preserves vertical insets and clears horizontal', (
      tester,
      direction,
    ) async {
      const Size tablet = Size(900, 1200);
      await _setView(tester, tablet);

      late MediaQueryData nested;
      await pumpWithDirection(
        tester,
        _harness(
          viewSize: tablet,
          direction: direction,
          theme: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
          child: Builder(
            builder: (context) {
              nested = MediaQuery.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
        direction,
      );

      expect(nested.padding.left, 0);
      expect(nested.padding.right, 0);
      expect(nested.padding.top, 24);
      expect(nested.padding.bottom, 16);
      expect(nested.viewPadding.top, 24);
      expect(nested.viewPadding.bottom, 16);
      expect(nested.viewInsets.bottom, 40);
    });

    testWidgets('light and dark letterbox use theme surfaceContainer', (
      tester,
    ) async {
      const Size tablet = Size(1024, 768);
      await _setView(tester, tablet);

      for (final ThemeData theme in <ThemeData>[
        AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
        AppTheme.getDarkTheme(primaryColor: AppColors.primaryCyan),
      ]) {
        await tester.pumpWidget(
          _harness(
            viewSize: tablet,
            direction: TextDirection.ltr,
            theme: theme,
            child: const SizedBox.expand(),
          ),
        );

        final ColoredBox letterbox = tester.widget<ColoredBox>(
          find.byType(ColoredBox).first,
        );
        expect(letterbox.color, theme.colorScheme.surfaceContainer);
      }
    });

    testInBothDirections('landscape resize keeps max width without overflow', (
      tester,
      direction,
    ) async {
      const Size portrait = Size(800, 1200);
      await _setView(tester, portrait);

      final GlobalKey childKey = GlobalKey();
      await pumpWithDirection(
        tester,
        _harness(
          viewSize: portrait,
          direction: direction,
          theme: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
          child: KeyedSubtree(
            key: childKey,
            child: const ColoredBox(color: Color(0xFF0000FF)),
          ),
        ),
        direction,
      );
      expect(tester.getSize(find.byKey(childKey)).width, 600);

      const Size landscape = Size(1280, 800);
      await _setView(tester, landscape);
      await pumpWithDirection(
        tester,
        _harness(
          viewSize: landscape,
          direction: direction,
          theme: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
          child: KeyedSubtree(
            key: childKey,
            child: const ColoredBox(color: Color(0xFF0000FF)),
          ),
        ),
        direction,
      );

      final Size childSize = tester.getSize(find.byKey(childKey));
      expect(childSize.width, TilawaBreakpoints.narrowUpperBound);
      expect(childSize.width, lessThan(landscape.width));
      expect(childSize.height, landscape.height);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exact breakpoint width remains pass-through', (tester) async {
      const Size edge = Size(TilawaBreakpoints.narrowUpperBound, 900);
      await _setView(tester, edge);

      late Size reported;
      await tester.pumpWidget(
        _harness(
          viewSize: edge,
          direction: TextDirection.ltr,
          theme: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
          child: _SizeProbe(onBuild: (size) => reported = size),
        ),
      );

      expect(reported.width, TilawaBreakpoints.narrowUpperBound);
      expect(find.byType(ColoredBox), findsOneWidget);
    });
  });
}
