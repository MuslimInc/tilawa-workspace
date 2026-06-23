import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/startup_blur_shader_warmup.dart';
import 'package:tilawa/core/telemetry/startup_perf_log.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_glass_surface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUp(() {
    StartupPerfLog.enabledInTests = true;
    StartupPerfLog.resetForTesting();
    StartupBlurShaderWarmup.resetForTest();
  });

  tearDown(() {
    StartupBlurShaderWarmup.resetForTest();
    StartupPerfLog.enabledInTests = false;
    StartupPerfLog.resetForTesting();
  });

  testWidgets('HomeHeroGlassSurface defers BackdropFilter until warmup ends', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Scaffold(
          body: HomeHeroGlassSurface(
            child: const Text('metrics'),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);

    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);

    StartupBlurShaderWarmup.completeForTest();
    await tester.pump();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets(
    'HomeHeroGlassSurface enables blur when warmup already complete',
    (
      tester,
    ) async {
      StartupBlurShaderWarmup.completeForTest();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: Scaffold(
            body: HomeHeroGlassSurface(
              child: const Text('metrics'),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);

      await tester.pump();

      expect(find.byType(BackdropFilter), findsOneWidget);
    },
  );
}
