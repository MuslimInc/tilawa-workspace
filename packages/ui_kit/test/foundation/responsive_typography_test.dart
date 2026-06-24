import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/app_colors.dart';
import '../../lib/src/foundation/app_theme.dart';
import '../../lib/src/foundation/responsive_typography.dart';
import '../rtl_test_matrix.dart';

double _nudgedSize(double? baseSize, double design, double m3Default) {
  return baseSize! * (design / m3Default);
}

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
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: _ContextProbe(onBuild: (context) => captured = context),
      ),
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
    group('responsiveTextTheme on narrow window class', () {
      testInBothDirections('preserves display/headline font sizes', (
        tester,
        direction,
      ) async {
        const size = Size(480, 800);
        final ctx = await _pump(tester, size, direction);

        final responsive = ctx.responsiveTextTheme;
        final base = Theme.of(ctx).textTheme;

        // Narrow window class does not change display/headline font sizes — it only
        // tunes height and letterSpacing for presence on small screens.
        expect(responsive.displayLarge?.fontSize, base.displayLarge?.fontSize);
        expect(
          responsive.headlineLarge?.fontSize,
          base.headlineLarge?.fontSize,
        );
      });

      testInBothDirections(
        'nudges titleLarge and bodyLarge sub-pt for presence on phones',
        (tester, direction) async {
          const size = Size(412, 800);
          final ctx = await _pump(tester, size, direction);

          final responsive = ctx.responsiveTextTheme;
          final base = Theme.of(ctx).textTheme;

          expect(
            responsive.titleLarge?.fontSize,
            _nudgedSize(base.titleLarge?.fontSize, 23, 22),
          );
          expect(
            responsive.bodyLarge?.fontSize,
            _nudgedSize(base.bodyLarge?.fontSize, 16.5, 16),
          );
        },
      );

      testInBothDirections(
        'applies explicit height and letterSpacing on narrow class',
        (tester, direction) async {
          const size = Size(412, 800);
          final ctx = await _pump(tester, size, direction);

          final responsive = ctx.responsiveTextTheme;

          // Headlines/displays get tighter line height for presence.
          expect(responsive.displayLarge?.height, 1.25);
          expect(responsive.headlineLarge?.height, 1.25);
          expect(responsive.titleLarge?.height, 1.25);

          // Body styles get a relaxed line height for readability.
          expect(responsive.bodyLarge?.height, 1.4);
          expect(responsive.bodyMedium?.height, 1.4);

          // Display sizes get a tightened letterSpacing.
          expect(responsive.displayLarge?.letterSpacing, -0.2);
        },
      );
    });

    group('responsiveTextTheme on medium screens', () {
      testInBothDirections('scales font sizes for medium screens (600-840px)', (
        tester,
        direction,
      ) async {
        const size = Size(720, 800);
        final ctx = await _pump(tester, size, direction);

        final responsive = ctx.responsiveTextTheme;
        final base = Theme.of(ctx).textTheme;

        expect(
          responsive.displayLarge?.fontSize,
          _nudgedSize(base.displayLarge?.fontSize, 60, 57),
        );
        expect(
          responsive.displayMedium?.fontSize,
          _nudgedSize(base.displayMedium?.fontSize, 48, 45),
        );
        expect(
          responsive.titleLarge?.fontSize,
          _nudgedSize(base.titleLarge?.fontSize, 24, 22),
        );
        expect(
          responsive.bodyLarge?.fontSize,
          _nudgedSize(base.bodyLarge?.fontSize, 17, 16),
        );
        expect(
          responsive.bodyMedium?.fontSize,
          _nudgedSize(base.bodyMedium?.fontSize, 15, 14),
        );
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
        final base = Theme.of(ctx).textTheme;

        expect(
          responsive.displayLarge?.fontSize,
          _nudgedSize(base.displayLarge?.fontSize, 64, 57),
        );
        expect(
          responsive.displayMedium?.fontSize,
          _nudgedSize(base.displayMedium?.fontSize, 52, 45),
        );
        expect(
          responsive.displaySmall?.fontSize,
          _nudgedSize(base.displaySmall?.fontSize, 40, 36),
        );
        expect(
          responsive.headlineLarge?.fontSize,
          _nudgedSize(base.headlineLarge?.fontSize, 36, 32),
        );
        expect(
          responsive.headlineMedium?.fontSize,
          _nudgedSize(base.headlineMedium?.fontSize, 32, 28),
        );
        expect(
          responsive.headlineSmall?.fontSize,
          _nudgedSize(base.headlineSmall?.fontSize, 28, 24),
        );
        expect(
          responsive.titleLarge?.fontSize,
          _nudgedSize(base.titleLarge?.fontSize, 26, 22),
        );
        expect(
          responsive.titleMedium?.fontSize,
          _nudgedSize(base.titleMedium?.fontSize, 20, 16),
        );
        expect(
          responsive.titleSmall?.fontSize,
          _nudgedSize(base.titleSmall?.fontSize, 18, 14),
        );
        expect(
          responsive.bodyLarge?.fontSize,
          _nudgedSize(base.bodyLarge?.fontSize, 18, 16),
        );
        expect(
          responsive.bodyMedium?.fontSize,
          _nudgedSize(base.bodyMedium?.fontSize, 16, 14),
        );
        expect(
          responsive.bodySmall?.fontSize,
          _nudgedSize(base.bodySmall?.fontSize, 14, 12),
        );
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
        final base = Theme.of(ctx).textTheme;

        expect(
          responsive.displayLarge?.fontSize,
          _nudgedSize(base.displayLarge?.fontSize, 64, 57),
        );
        expect(
          responsive.bodyLarge?.fontSize,
          _nudgedSize(base.bodyLarge?.fontSize, 18, 16),
        );
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
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
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

      final base = Theme.of(captured).textTheme;
      expect(
        captured.responsiveStyle((theme) => theme.bodyLarge)?.fontSize,
        _nudgedSize(base.bodyLarge?.fontSize, 18, 16),
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
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
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

      expect(
        responsive.bodyLarge?.fontSize,
        _nudgedSize(base.bodyLarge?.fontSize, 17, 16),
      );
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
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
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
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.displayLarge?.fontSize,
          _nudgedSize(base.displayLarge?.fontSize, 60, 57),
        );
      });

      testInBothDirections('scales displayMedium to 48', (
        tester,
        direction,
      ) async {
        const size = Size(700, 800);
        final ctx = await _pump(tester, size, direction);
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.displayMedium?.fontSize,
          _nudgedSize(base.displayMedium?.fontSize, 48, 45),
        );
      });

      testInBothDirections('scales titleLarge to 24', (
        tester,
        direction,
      ) async {
        const size = Size(650, 800);
        final ctx = await _pump(tester, size, direction);
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.titleLarge?.fontSize,
          _nudgedSize(base.titleLarge?.fontSize, 24, 22),
        );
      });

      testInBothDirections('scales bodyLarge to 17', (tester, direction) async {
        const size = Size(800, 800);
        final ctx = await _pump(tester, size, direction);
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.bodyLarge?.fontSize,
          _nudgedSize(base.bodyLarge?.fontSize, 17, 16),
        );
      });

      testInBothDirections('scales bodyMedium to 15', (
        tester,
        direction,
      ) async {
        const size = Size(750, 800);
        final ctx = await _pump(tester, size, direction);
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.bodyMedium?.fontSize,
          _nudgedSize(base.bodyMedium?.fontSize, 15, 14),
        );
      });
    });

    group('expanded screen font scaling correctness', () {
      testInBothDirections('scales displayLarge to 64', (
        tester,
        direction,
      ) async {
        const size = Size(900, 1200);
        final ctx = await _pump(tester, size, direction);
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.displayLarge?.fontSize,
          _nudgedSize(base.displayLarge?.fontSize, 64, 57),
        );
      });

      testInBothDirections('scales displaySmall to 40', (
        tester,
        direction,
      ) async {
        const size = Size(1000, 1200);
        final ctx = await _pump(tester, size, direction);
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.displaySmall?.fontSize,
          _nudgedSize(base.displaySmall?.fontSize, 40, 36),
        );
      });

      testInBothDirections('scales headlineLarge to 36', (
        tester,
        direction,
      ) async {
        const size = Size(950, 1200);
        final ctx = await _pump(tester, size, direction);
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.headlineLarge?.fontSize,
          _nudgedSize(base.headlineLarge?.fontSize, 36, 32),
        );
      });

      testInBothDirections('scales titleLarge to 26', (
        tester,
        direction,
      ) async {
        const size = Size(1100, 1200);
        final ctx = await _pump(tester, size, direction);
        final base = Theme.of(ctx).textTheme;
        expect(
          ctx.responsiveTextTheme.titleLarge?.fontSize,
          _nudgedSize(base.titleLarge?.fontSize, 26, 22),
        );
      });
    });
  });
}
