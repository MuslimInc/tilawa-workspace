import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Mirrors the post-handoff branch of [_BootGateState] in
/// [app_startup_widgets.dart] for widget-level verification.
class _BootGateHandoffFixture extends StatelessWidget {
  const _BootGateHandoffFixture({
    required this.appChild,
    this.overlayKey,
  });

  final Widget appChild;
  final Key? overlayKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SplashLaunchHandoff.splashRouteHasPainted,
      builder: (BuildContext context, bool painted, Widget? _) {
        final bool showOverlay = !painted;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              appChild,
              if (showOverlay)
                DecoratedBox(
                  key: overlayKey,
                  decoration: BoxDecoration(
                    color: AppColors.launchSplashBackground,
                  ),
                  child: const SizedBox.expand(),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Mirrors [SplashScreen] scheduling [SplashLaunchHandoff.markSplashRoutePainted]
/// on the first frame.
class _SplashRoutePaintProbe extends StatefulWidget {
  const _SplashRoutePaintProbe();

  @override
  State<_SplashRoutePaintProbe> createState() => _SplashRoutePaintProbeState();
}

class _SplashRoutePaintProbeState extends State<_SplashRoutePaintProbe> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SplashLaunchHandoff.markSplashRoutePainted();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('splash_route'));
  }
}

class _MountCountingApp extends StatefulWidget {
  const _MountCountingApp({
    required this.onInit,
    required this.onDispose,
  });

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_MountCountingApp> createState() => _MountCountingAppState();
}

class _MountCountingAppState extends State<_MountCountingApp> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('mounted_app'));
  }
}

void main() {
  tearDown(SplashLaunchHandoff.resetForNewLaunch);

  group('BootGate splash handoff overlay', () {
    testWidgets('shows overlay until splash route paints', (
      WidgetTester tester,
    ) async {
      SplashLaunchHandoff.resetForNewLaunch();
      const overlayKey = Key('launch_overlay');
      const appKey = Key('app_underlay');

      await tester.pumpWidget(
        const MaterialApp(
          home: _BootGateHandoffFixture(
            overlayKey: overlayKey,
            appChild: SizedBox(key: appKey),
          ),
        ),
      );

      expect(find.byKey(overlayKey), findsOneWidget);
      expect(find.byKey(appKey), findsOneWidget);
    });

    testWidgets('removes overlay after splash route first frame', (
      WidgetTester tester,
    ) async {
      SplashLaunchHandoff.resetForNewLaunch();
      const overlayKey = Key('launch_overlay');

      await tester.pumpWidget(
        const MaterialApp(
          home: _BootGateHandoffFixture(
            overlayKey: overlayKey,
            appChild: _SplashRoutePaintProbe(),
          ),
        ),
      );

      expect(find.byKey(overlayKey), findsOneWidget);

      await tester.pump();

      expect(find.byKey(overlayKey), findsNothing);
      expect(find.byKey(const Key('splash_route')), findsOneWidget);
      expect(SplashLaunchHandoff.splashRouteHasPainted.value, isTrue);
    });

    testWidgets('keeps app underlay mounted when overlay is removed', (
      WidgetTester tester,
    ) async {
      SplashLaunchHandoff.resetForNewLaunch();
      const overlayKey = Key('launch_overlay');
      var initCount = 0;
      var disposeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: _BootGateHandoffFixture(
            overlayKey: overlayKey,
            appChild: _MountCountingApp(
              onInit: () => initCount++,
              onDispose: () => disposeCount++,
            ),
          ),
        ),
      );

      expect(find.byKey(overlayKey), findsOneWidget);
      expect(find.byKey(const Key('mounted_app')), findsOneWidget);
      expect(initCount, 1);
      expect(disposeCount, 0);

      SplashLaunchHandoff.markSplashRoutePainted();
      await tester.pump();

      expect(find.byKey(overlayKey), findsNothing);
      expect(find.byKey(const Key('mounted_app')), findsOneWidget);
      expect(initCount, 1);
      expect(disposeCount, 0);
    });
  });
}
