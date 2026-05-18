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

    test('setPendingColdStartRoute marks startup notification launch', () {
      AppRouter.setPendingColdStartRoute(const HomeRoute().location);
      expect(AppRouter.pendingStartupNotificationLaunch, isTrue);
      expect(AppRouter.disableStateRestoration, isTrue);
    });
  });
}
