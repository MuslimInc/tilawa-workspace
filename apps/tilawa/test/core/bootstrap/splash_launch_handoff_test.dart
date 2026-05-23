import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';

void main() {
  tearDown(SplashLaunchHandoff.resetForNewLaunch);

  group('SplashLaunchHandoff', () {
    test('starts with splash route not painted', () {
      SplashLaunchHandoff.resetForNewLaunch();

      expect(SplashLaunchHandoff.splashRouteHasPainted.value, isFalse);
    });

    test('markSplashRoutePainted sets painted flag once', () {
      SplashLaunchHandoff.resetForNewLaunch();

      SplashLaunchHandoff.markSplashRoutePainted();
      SplashLaunchHandoff.markSplashRoutePainted();

      expect(SplashLaunchHandoff.splashRouteHasPainted.value, isTrue);
    });

    test('resetForNewLaunch clears painted flag for a new launch', () {
      SplashLaunchHandoff.markSplashRoutePainted();

      SplashLaunchHandoff.resetForNewLaunch();

      expect(SplashLaunchHandoff.splashRouteHasPainted.value, isFalse);
    });

    test('notifies listeners when painted flag changes', () {
      SplashLaunchHandoff.resetForNewLaunch();
      var notificationCount = 0;
      void listener() => notificationCount++;

      SplashLaunchHandoff.splashRouteHasPainted.addListener(listener);
      addTearDown(
        () => SplashLaunchHandoff.splashRouteHasPainted.removeListener(
          listener,
        ),
      );

      SplashLaunchHandoff.markSplashRoutePainted();

      expect(notificationCount, 1);
    });
  });
}
