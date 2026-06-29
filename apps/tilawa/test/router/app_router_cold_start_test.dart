import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';

void main() {
  setUp(AppRouter.resetForTesting);

  tearDown(AppRouter.resetForTesting);

  group('AppRouter cold start', () {
    test(
      'resolveInitialLocation uses home when pending cold start route',
      () {
        AppRouter.setPendingColdStartRoute('/reciter/7');
        expect(AppRouter.resolveInitialLocation(), const HomeRoute().location);
      },
    );

    test('resolveInitialLocation falls back to splash', () {
      expect(
        AppRouter.resolveInitialLocation(),
        const SplashRoute().location,
      );
    });

    test('resolveInitialLocation uses boot-selected launch location', () {
      AppRouter.setInitialLaunchLocation(const LoginRoute().location);
      expect(AppRouter.resolveInitialLocation(), const LoginRoute().location);
    });

    test('setPendingColdStartRoute marks startup notification launch', () {
      AppRouter.setPendingColdStartRoute(const HomeRoute().location);
      expect(AppRouter.pendingStartupNotificationLaunch, isTrue);
      expect(AppRouter.disableStateRestoration, isTrue);
    });

    test('applyBootLaunchPlan keeps router off splash for home', () {
      AppRouter.applyBootLaunchPlan(targetLocation: const HomeRoute().location);
      expect(AppRouter.bootLaunchPlanApplied, isTrue);
      expect(
        AppRouter.resolveInitialLocation(),
        isNot(const SplashRoute().location),
      );
      expect(AppRouter.resolveInitialLocation(), const HomeRoute().location);
    });

    test('applyBootLaunchPlan keeps router off splash for login', () {
      AppRouter.applyBootLaunchPlan(
        targetLocation: const LoginRoute().location,
      );
      expect(AppRouter.bootLaunchPlanApplied, isTrue);
      expect(
        AppRouter.resolveInitialLocation(),
        const LoginRoute().location,
      );
    });

    test('applyBootLaunchPlan uses home initial route for notification', () {
      AppRouter.applyBootLaunchPlan(
        targetLocation: const PrayerNotificationStatusRoute().location,
        notificationLocation: const PrayerNotificationStatusRoute().location,
        notificationExtra: '{"prayer_key":"fajr"}',
      );
      expect(AppRouter.bootLaunchPlanApplied, isTrue);
      expect(
        AppRouter.resolveInitialLocation(),
        const HomeRoute().location,
      );
      expect(
        AppRouter.pendingColdStartLocation,
        const PrayerNotificationStatusRoute().location,
      );
    });

    test('consumeBootLaunchPlan clears boot flags and initial launch', () {
      AppRouter.applyBootLaunchPlan(
        targetLocation: const HomeRoute().location,
        timedOut: true,
      );

      AppRouter.consumeBootLaunchPlan();

      expect(AppRouter.bootLaunchPlanApplied, isFalse);
      expect(AppRouter.bootLaunchTimedOut, isFalse);
      expect(AppRouter.initialLaunchLocation, isNull);
      expect(
        AppRouter.resolveInitialLocation(),
        const SplashRoute().location,
      );
    });

    test(
      'consumeBootLaunchPlan does not clear pending notification cold start',
      () {
        AppRouter.applyBootLaunchPlan(
          targetLocation: const PrayerNotificationStatusRoute().location,
          notificationLocation: const PrayerNotificationStatusRoute().location,
          notificationExtra: '{"prayer_key":"fajr"}',
        );

        AppRouter.consumeBootLaunchPlan();

        expect(AppRouter.bootLaunchPlanApplied, isFalse);
        expect(
          AppRouter.pendingColdStartLocation,
          const PrayerNotificationStatusRoute().location,
        );
        expect(AppRouter.pendingStartupNotificationLaunch, isTrue);
      },
    );

    test('resetForTesting clears boot launch state for test isolation', () {
      AppRouter.applyBootLaunchPlan(
        targetLocation: const HomeRoute().location,
        notificationLocation: const PrayerNotificationStatusRoute().location,
        notificationExtra: '{"prayer_key":"fajr"}',
        timedOut: true,
      );
      AppRouter.setInitialLaunchLocation(const LoginRoute().location);

      AppRouter.resetForTesting();

      expect(AppRouter.bootLaunchPlanApplied, isFalse);
      expect(AppRouter.bootLaunchTimedOut, isFalse);
      expect(AppRouter.initialLaunchLocation, isNull);
      expect(AppRouter.pendingColdStartLocation, isNull);
      expect(AppRouter.pendingColdStartExtra, isNull);
      expect(AppRouter.pendingStartupNotificationLaunch, isFalse);
      expect(AppRouter.disableStateRestoration, isFalse);
      expect(
        AppRouter.resolveInitialLocation(),
        const SplashRoute().location,
      );
    });
  });
}
