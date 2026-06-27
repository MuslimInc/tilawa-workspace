import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/navigation/navigation_source.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/deep_link_resolver.dart';

void main() {
  setUp(AppRouter.resetForTesting);
  tearDown(AppRouter.resetForTesting);

  test('consumePendingNotificationLaunchState clears pending cold start', () {
    AppRouter.setPendingColdStartRoute(
      AthkarDetailsRoute(
        categoryId: DeepLinkResolver.athkarMorningCategoryId,
        categoryName: DeepLinkResolver.athkarMorningCategoryName,
        source: NavigationSource.notification.wireValue,
      ).location,
    );
    AppRouter.pendingStartupNotificationLaunch = true;
    AppRouter.disableStateRestoration = true;

    AppRouter.consumePendingNotificationLaunchState();

    expect(AppRouter.pendingColdStartLocation, isNull);
    expect(AppRouter.pendingColdStartExtra, isNull);
    expect(AppRouter.pendingStartupNotificationLaunch, isFalse);
    expect(AppRouter.disableStateRestoration, isFalse);
    expect(AppRouter.pendingFcmMessage, isNull);
    expect(AppRouter.pendingLocalNotificationResponse, isNull);
    expect(AppRouter.lastProcessedNotificationPayload, isNull);
  });
}
