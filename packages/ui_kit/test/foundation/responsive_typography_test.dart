import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/responsive_typography.dart';
import '../rtl_test_matrix.dart';

class _ContextProbe extends StatelessWidget {
  const _ContextProbe({required this.onBuild});

  final ValueChanged<BuildContext> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox.shrink();
  }
}

Future<BuildContext> _pump(
  WidgetTester tester,
  Size size,
  TextDirection direction,
) async {
  late BuildContext captured;
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await pumpWithDirection(
    tester,
    MediaQuery(
      data: MediaQueryData(size: size),
      child: _ContextProbe(onBuild: (context) => captured = context),
    ),
    direction,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  return captured;
}

void main() {
  group('TilawaResponsiveTypography', () {
    group('responsiveTextTheme on compact screens', () {
      testInBothDirections('does not scale font sizes below 600px width', (
        tester,
        direction,
      ) async {
        const size = Size(480, 800);
        final ctx = await _pump(tester, size, direction);

        final responsive = ctx.responsiveTextTheme;
        final base = Theme.of(ctx).textTheme;

        // Compact screen should use base theme (no scaling)
        expect(responsive.displayLarge?.fontSize, base.displayLarge?.fontSize);
        expect(
          responsive.headlineLarge?.fontSize,
          base.headlineLarge?.fontSize,
        );
        expect(responsive.bodyLarge?.fontSize, base.bodyLarge?.fontSize);
      });
    });

    group('responsiveTextTheme on medium screens', () {
      testInBothDirections('scales font sizes for medium screens (600-840px)', (
        tester,
        direction,
      ) async {
        const size = Size(720, 800);
        final ctx = await _pump(tester, size, direction);

        final responsive = ctx.responsiveTextTheme;

        // Medium screen should have scaled sizes
        expect(responsive.displayLarge?.fontSize, 60);
        expect(responsive.displayMedium?.fontSize, 48);
        expect(responsive.titleLarge?.fontSize, 24);
        expect(responsive.bodyLarge?.fontSize, 17);
        expect(responsive.bodyMedium?.fontSize, 15);
      });
    });

    group('responsiveTextTheme on expanded screens', () {
      testInBothDirections('scales font sizes for expanded screens (840px+)', (
        tester,
        direction,
      ) async {
        const size = Size(900, 1200);
        final ctx = await _pump(tester, size, direction);

        final responsive = ctx.responsiveTextTheme;

        // Expanded screen should have larger scaled sizes
        expect(responsive.displayLarge?.fontSize, 64);
        expect(responsive.displayMedium?.fontSize, 52);
        expect(responsive.displaySmall?.fontSize, 40);
        expect(responsive.headlineLarge?.fontSize, 36);
        expect(responsive.headlineMedium?.fontSize, 32);
        expect(responsive.headlineSmall?.fontSize, 28);
        expect(responsive.titleLarge?.fontSize, 26);
        expect(responsive.titleMedium?.fontSize, 20);
        expect(responsive.titleSmall?.fontSize, 18);
        expect(responsive.bodyLarge?.fontSize, 18);
        expect(responsive.bodyMedium?.fontSize, 16);
        expect(responsive.bodySmall?.fontSize, 14);
      });
    });

    group('responsiveTextTheme on large screens', () {
      testInBothDirections('handles window size >= 1200px', (
        tester,
        direction,
      ) async {
        const size = Size(1400, 1000);
        final ctx = await _pump(tester, size, direction);

        final responsive = ctx.responsiveTextTheme;

        // Should use expanded screen sizes for 1200+
        expect(responsive.displayLarge?.fontSize, 64);
        expect(responsive.bodyLarge?.fontSize, 18);
      });
    });

    testWidgets('responsiveStyle helper works correctly', (
      WidgetTester tester,
    ) async {
      const size = Size(840, 800);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      late BuildContext captured;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: size),
            child: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      expect(
        captured.responsiveStyle((theme) => theme.bodyLarge)?.fontSize,
        18,
      );
    });

    testWidgets('responsiveTextTheme preserves non-font properties', (
      WidgetTester tester,
    ) async {
      const size = Size(700, 800);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      late BuildContext captured;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: size),
            child: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final responsive = captured.responsiveTextTheme;
      final base = Theme.of(captured).textTheme;

      // Font size changes but other properties preserved
      expect(responsive.bodyLarge?.fontSize, 17);
      expect(responsive.bodyLarge?.fontWeight, base.bodyLarge?.fontWeight);
      expect(
        responsive.bodyLarge?.letterSpacing,
        base.bodyLarge?.letterSpacing,
      );
    });

    testWidgets('handles null TextStyle gracefully', (
      WidgetTester tester,
    ) async {
      const size = Size(840, 800);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      late BuildContext captured;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: size),
            child: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Should not throw when accessing null styles
      expect(
        () => captured.responsiveStyle((theme) => theme.bodySmall),
        returnsNormally,
      );
    });

    group('medium screen font scaling correctness', () {
      testInBothDirections('scales displayLarge to 60', (
        tester,
        direction,
      ) async {
        const size = Size(600, 800);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.displayLarge?.fontSize, 60);
      });

      testInBothDirections('scales displayMedium to 48', (
        tester,
        direction,
      ) async {
        const size = Size(700, 800);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.displayMedium?.fontSize, 48);
      });

      testInBothDirections('scales titleLarge to 24', (
        tester,
        direction,
      ) async {
        const size = Size(650, 800);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.titleLarge?.fontSize, 24);
      });

      testInBothDirections('scales bodyLarge to 17', (tester, direction) async {
        const size = Size(800, 800);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.bodyLarge?.fontSize, 17);
      });

      testInBothDirections('scales bodyMedium to 15', (
        tester,
        direction,
      ) async {
        const size = Size(750, 800);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.bodyMedium?.fontSize, 15);
      });
    });

    group('expanded screen font scaling correctness', () {
      testInBothDirections('scales displayLarge to 64', (
        tester,
        direction,
      ) async {
        const size = Size(900, 1200);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.displayLarge?.fontSize, 64);
      });

      testInBothDirections('scales displaySmall to 40', (
        tester,
        direction,
      ) async {
        const size = Size(1000, 1200);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.displaySmall?.fontSize, 40);
      });

      testInBothDirections('scales headlineLarge to 36', (
        tester,
        direction,
      ) async {
        const size = Size(950, 1200);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.headlineLarge?.fontSize, 36);
      });

      testInBothDirections('scales titleLarge to 26', (
        tester,
        direction,
      ) async {
        const size = Size(1100, 1200);
        final ctx = await _pump(tester, size, direction);
        expect(ctx.responsiveTextTheme.titleLarge?.fontSize, 26);
      });
    });
  });
}
