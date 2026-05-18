import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../debug/deep_link_debug_log.dart';
import '../../router/app_router.dart';

abstract class NavigationService {
  Future<void> push(String location, {Object? extra});
  void navigateToNotification(String location, {Object? extra});
  String? getCurrentLocation();
}

@LazySingleton(as: NavigationService)
class NavigationServiceImpl implements NavigationService {
  @override
  Future<void> push(String location, {Object? extra}) async {
    // #region agent log
    DeepLinkDebugLog.log(
      'NavigationService.push',
      scenario: 'warm_push',
      hypothesisId: 'H6',
      data: <String, Object?>{
        'location': location,
        'hasExtra': extra != null,
      },
    );
    // #endregion
    await AppRouter.router.push(location, extra: extra);
    // #region agent log
    DeepLinkDebugLog.log(
      'NavigationService.push done',
      scenario: 'warm_push',
      hypothesisId: 'H6',
      data: <String, Object?>{
        'matched': AppRouter.router.routerDelegate.currentConfiguration.uri
            .toString(),
      },
    );
    // #endregion
  }

  @override
  void navigateToNotification(String location, {Object? extra}) {
    AppRouter.navigateToNotification(location, extra: extra);
  }

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
