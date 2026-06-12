import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/app/default_route_system_ui_overlay.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _FakeRouteChanges extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _OverlayHarness {
  _OverlayHarness({String initialPath = '/'}) : _path = initialPath;

  final ValueNotifier<bool> splashPainted = ValueNotifier<bool>(false);
  final _FakeRouteChanges routeChanges = _FakeRouteChanges();
  final QuranPlayerChromeNotifier chromeNotifier = QuranPlayerChromeNotifier();
  String _path;
  int markCount = 0;

  /// Changes the active route path and fires a route-change notification.
  void goTo(String path) {
    _path = path;
    routeChanges.notify();
  }

  Widget build({Widget? child = const SizedBox.expand()}) {
    return ChangeNotifierProvider<QuranPlayerChromeNotifier>.value(
      value: chromeNotifier,
      child: MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.primaryCoral),
        home: DefaultRouteSystemUiOverlay(
          routeChanges: routeChanges,
          currentRoutePath: () => _path,
          splashRouteHasPainted: splashPainted,
          markSplashRoutePainted: () {
            markCount += 1;
            splashPainted.value = true;
          },
          child: child,
        ),
      ),
    );
  }

  // No dispose: the chrome notifier defers `notifyListeners` to a post-frame
  // callback that can fire during the next test's warm-up frame; disposing
  // here would turn that late no-op notify into a use-after-dispose error.
}

SystemUiOverlayStyle _annotatedStyle(WidgetTester tester) {
  return tester
      .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      )
      .value;
}

SystemUiOverlayStyle get _launchStyle =>
    AppSystemChromeStyle.buildColoredScreenStyle(
      backgroundColor: AppColors.launchSplashBackground,
    );

ThemeData get _theme =>
    AppTheme.getLightTheme(primaryColor: AppColors.primaryCoral);

void main() {
  final List<MethodCall> overlayStyleCalls = <MethodCall>[];

  setUp(() {
    overlayStyleCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          if (call.method == 'SystemChrome.setSystemUIOverlayStyle') {
            overlayStyleCalls.add(call);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Clears [SystemChrome]'s process-wide cached style so each test starts
  /// from a platform that has no style applied (mirrors a fresh window).
  Future<void> resetSystemChromeCache(WidgetTester tester) async {
    SystemChrome.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    await tester.pump();
    overlayStyleCalls.clear();
  }

  /// Pumps until the launch handoff has marked the first routed frame and all
  /// scheduled chrome refreshes have run, then clears the recorded calls.
  Future<void> settleAndClear(WidgetTester tester) async {
    await tester.pumpAndSettle();
    overlayStyleCalls.clear();
    // Stability precondition: an idle frame must not re-send any style.
    await tester.pump();
    expect(overlayStyleCalls, isEmpty);
  }

  Future<void> simulateBackgroundThenResume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    overlayStyleCalls.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
  }

  group('launch handoff', () {
    testWidgets('shows launch splash style until the routed frame is marked', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build());

      expect(harness.markCount, 0);
      expect(harness.splashPainted.value, isFalse);
      expect(_annotatedStyle(tester), _launchStyle);
    });

    testWidgets('marks the handoff and applies the route style', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(harness.markCount, 1);
      expect(harness.splashPainted.value, isTrue);
      final SystemUiOverlayStyle expected =
          AppSystemChromeStyle.buildDefaultAppStyle(
            _theme,
            statusBarBackgroundColor: _theme.scaffoldBackgroundColor,
            navigationBarColor:
                _theme.componentTokens.adaptiveShell.bottomNavBackgroundColor,
          );
      expect(_annotatedStyle(tester), expected);
      expect(AppSystemChromeStyle.defaultAppStyle, expected);
      expect(overlayStyleCalls, isNotEmpty);
    });

    testWidgets('does not mark the handoff without a routed child', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build(child: null));
      await tester.pump();
      await tester.pump();

      expect(harness.markCount, 0);
      expect(harness.splashPainted.value, isFalse);
    });

    testWidgets('schedules a refresh when the mark does not repaint', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final ValueNotifier<bool> splash = ValueNotifier<bool>(false);
      int marks = 0;

      await tester.pumpWidget(
        ChangeNotifierProvider<QuranPlayerChromeNotifier>.value(
          value: QuranPlayerChromeNotifier(),
          child: MaterialApp(
            theme: _theme,
            home: DefaultRouteSystemUiOverlay(
              routeChanges: _FakeRouteChanges(),
              currentRoutePath: () => '/',
              splashRouteHasPainted: splash,
              // Mark without flipping the painted flag: the immediate apply
              // stays inert and the widget falls back to a deferred refresh.
              markSplashRoutePainted: () => marks += 1,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(marks, 1);
      expect(_annotatedStyle(tester), _launchStyle);
      // The imperative path stays inert; only the launch style may have been
      // sent (by the per-frame AnnotatedRegion compositing).
      for (final MethodCall call in overlayStyleCalls) {
        final Map<Object?, Object?> sent =
            call.arguments as Map<Object?, Object?>;
        expect(
          sent['statusBarIconBrightness'],
          '${_launchStyle.statusBarIconBrightness}',
        );
      }
    });

    testWidgets('skips the deferred mark when splash paints in between', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build());
      // The mark is scheduled for the next frame; paint the splash first.
      harness.splashPainted.value = true;
      await tester.pumpAndSettle();

      expect(harness.markCount, 0);
    });
  });

  group('route styles', () {
    testWidgets('maps each route to its overlay style', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness(initialPath: '/splash');
      harness.splashPainted.value = true;

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();
      expect(_annotatedStyle(tester), _launchStyle);

      harness.goTo('/login');
      await tester.pumpAndSettle();
      expect(
        _annotatedStyle(tester),
        AppSystemChromeStyle.buildColoredScreenStyle(
          backgroundColor: _theme.colorScheme.primary,
        ),
      );

      final SystemUiOverlayStyle onboardingStyle =
          AppSystemChromeStyle.buildDefaultAppStyle(
            _theme,
            statusBarBackgroundColor: _theme.scaffoldBackgroundColor,
            navigationBarColor: _theme.scaffoldBackgroundColor,
          );
      harness.goTo('/language-welcome');
      await tester.pumpAndSettle();
      expect(_annotatedStyle(tester), onboardingStyle);

      harness.goTo('/onboarding');
      await tester.pumpAndSettle();
      expect(_annotatedStyle(tester), onboardingStyle);

      harness.goTo('/');
      await tester.pumpAndSettle();
      expect(
        _annotatedStyle(tester),
        AppSystemChromeStyle.buildDefaultAppStyle(
          _theme,
          statusBarBackgroundColor: _theme.scaffoldBackgroundColor,
          navigationBarColor:
              _theme.componentTokens.adaptiveShell.bottomNavBackgroundColor,
        ),
      );
    });

    testWidgets('uses the player navigation bar override on default routes', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();
      harness.splashPainted.value = true;

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      const Color override = Color(0xFF123456);
      harness.chromeNotifier.setSystemNavigationBarColorOverride(override);
      // The notifier defers notifyListeners to a post-frame callback without
      // requesting a frame, so request one for the deferred notify to run.
      tester.binding.scheduleFrame();
      await tester.pumpAndSettle();

      expect(_annotatedStyle(tester).systemNavigationBarColor, override);
    });

    testWidgets('dedupes refreshes that resolve to the same style', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build());
      await settleAndClear(tester);

      harness.goTo('/');
      await tester.pumpAndSettle();

      expect(overlayStyleCalls, isEmpty);
    });

    testWidgets('sends the new style when the route changes', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build());
      await settleAndClear(tester);

      harness.goTo('/login');
      await tester.pumpAndSettle();

      expect(overlayStyleCalls, isNotEmpty);
      expect(
        _annotatedStyle(tester),
        AppSystemChromeStyle.buildColoredScreenStyle(
          backgroundColor: _theme.colorScheme.primary,
        ),
      );
    });
  });

  group('app resume', () {
    testWidgets('re-sends the unchanged style to the platform on resume', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build());
      await settleAndClear(tester);
      final SystemUiOverlayStyle styleBeforeResume = _annotatedStyle(tester);

      // Back-gesture exit + fast relaunch: Android resets the window bars but
      // the framework caches mean nothing is re-sent without the resume hook.
      await simulateBackgroundThenResume(tester);

      expect(overlayStyleCalls, isNotEmpty);
      expect(_annotatedStyle(tester), styleBeforeResume);
      final Map<Object?, Object?> sent =
          overlayStyleCalls.last.arguments as Map<Object?, Object?>;
      expect(
        sent['statusBarIconBrightness'],
        '${styleBeforeResume.statusBarIconBrightness}',
      );
    });

    testWidgets('does nothing on non-resume lifecycle changes', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build());
      await settleAndClear(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(overlayStyleCalls, isEmpty);

      // Restore for the remaining tests.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    });

    testWidgets('resume before the splash painted keeps the launch style', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      final _OverlayHarness harness = _OverlayHarness();

      await tester.pumpWidget(harness.build(child: null));
      await tester.pumpAndSettle();

      await simulateBackgroundThenResume(tester);

      // The imperative path must stay inert before the handoff; only the
      // launch splash style may reach the platform (via the AnnotatedRegion).
      expect(_annotatedStyle(tester), _launchStyle);
      for (final MethodCall call in overlayStyleCalls) {
        final Map<Object?, Object?> sent =
            call.arguments as Map<Object?, Object?>;
        expect(
          sent['statusBarIconBrightness'],
          '${_launchStyle.statusBarIconBrightness}',
        );
      }
    });
  });

  group('production defaults', () {
    testWidgets('falls back to AppRouter and SplashLaunchHandoff', (
      WidgetTester tester,
    ) async {
      await resetSystemChromeCache(tester);
      AppRouter.resetForTesting();
      SplashLaunchHandoff.resetForNewLaunch();
      addTearDown(AppRouter.resetForTesting);
      addTearDown(SplashLaunchHandoff.resetForNewLaunch);

      await tester.pumpWidget(
        ChangeNotifierProvider<QuranPlayerChromeNotifier>.value(
          value: QuranPlayerChromeNotifier(),
          child: MaterialApp(
            theme: _theme,
            // No routed child: the widget listens to the real router delegate
            // and splash notifier but never queries the router state.
            home: const DefaultRouteSystemUiOverlay(child: null),
          ),
        ),
      );
      await tester.pump();

      expect(_annotatedStyle(tester), _launchStyle);
      expect(SplashLaunchHandoff.splashRouteHasPainted.value, isFalse);

      // Dispose cleanly to cover the default listener teardown.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
