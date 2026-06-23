import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/startup_blur_shader_warmup.dart';
import 'package:tilawa/core/telemetry/startup_perf_log.dart';

void main() {
  setUp(() {
    StartupPerfLog.enabledInTests = true;
    StartupPerfLog.resetForTesting();
  });

  tearDown(() {
    StartupBlurShaderWarmup.resetForTest();
    StartupPerfLog.enabledInTests = false;
    StartupPerfLog.resetForTesting();
  });

  testWidgets('scheduleOnce inserts offscreen warmup via navigator context', (
    tester,
  ) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();

    expect(StartupBlurShaderWarmup.isComplete, isFalse);

    StartupBlurShaderWarmup.scheduleOnce(
      resolveOverlay: () => navigatorKey.currentState?.overlay,
    );
    await tester.pump();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(StartupBlurShaderWarmup.isComplete, isFalse);

    while (!StartupBlurShaderWarmup.isComplete) {
      await tester.pump();
    }
    await tester.pump();

    expect(find.byType(BackdropFilter), findsNothing);

    StartupBlurShaderWarmup.scheduleOnce(
      resolveOverlay: () => navigatorKey.currentState?.overlay,
    );
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('scheduleOnce retries when overlay is not ready yet', (
    tester,
  ) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();

    StartupBlurShaderWarmup.scheduleOnce(resolveOverlay: () => null);
    await tester.pump();

    expect(StartupBlurShaderWarmup.isComplete, isFalse);

    StartupBlurShaderWarmup.scheduleOnce(
      resolveOverlay: () => navigatorKey.currentState?.overlay,
    );
    await tester.pump();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('StartupBlurShaderWarmupWidget spreads blur then nav shadow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StartupBlurShaderWarmupWidget(),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(DecoratedBox), findsOneWidget);

    await tester.pump();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(DecoratedBox), findsWidgets);
  });

  testWidgets('hero blur warmup uses ClipRRect like HomeHeroGlassSurface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StartupBlurShaderWarmupWidget(),
        ),
      ),
    );

    expect(find.byType(ClipRRect), findsOneWidget);
  });
}
