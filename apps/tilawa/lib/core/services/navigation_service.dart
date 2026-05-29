import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../navigation/notification_destination.dart';
import '../../router/app_router.dart';

/// Single navigation API for notification / deep-link driven navigation.
///
/// This is the one place that decides cold-start vs warm navigation, so every
/// notification path (Athkar, prayer Adhan, downloads, FCM, splash) routes
/// consistently. Callers resolve a [NotificationDestination] (via
/// `DeepLinkResolver`) and hand it here; the proven stack-shaping and
/// de-duplication live in [AppRouter].
abstract class NavigationService {
  Future<void> push(String location, {Object? extra});

  /// Navigates to a notification destination, choosing cold-start vs warm
  /// automatically based on whether the app is still consuming a launch.
  void navigateToNotification(String location, {Object? extra});

  /// Navigates a fully-resolved [NotificationDestination]. Preferred entry
  /// point — carries source attribution end to end.
  void routeToDestination(NotificationDestination destination);

  String? getCurrentLocation();
}

@LazySingleton(as: NavigationService)
class NavigationServiceImpl implements NavigationService {
  @override
  Future<void> push(String location, {Object? extra}) async {
    await AppRouter.router.push(location, extra: extra);
  }

  @override
  void navigateToNotification(String location, {Object? extra}) {
    if (_isConsumingColdStartLaunch) {
      AppRouter.navigateFromColdStart(location, extra: extra);
    } else {
      AppRouter.navigateToNotification(location, extra: extra);
    }
  }

  @override
  void routeToDestination(NotificationDestination destination) {
    navigateToNotification(destination.location, extra: destination.extra);
  }

  /// True while the app is still consuming a notification cold-start launch.
  /// After the first frame consumes the pending launch (see `tilawa_app.dart`),
  /// this is false and taps take the warm path — matching the previous inline
  /// check in the download navigator.
  bool get _isConsumingColdStartLaunch =>
      AppRouter.disableStateRestoration &&
      AppRouter.pendingColdStartLocation != null;

  @override
  String? getCurrentLocation() {
    // Accessing the current location from GoRouter
    // Note: This relies on the current configuration of the router delegate
    try {
      final List<RouteMatchBase> matches =
          AppRouter.router.routerDelegate.currentConfiguration.matches;
      if (matches.isNotEmpty) {
        return matches.last.matchedLocation;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
