import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../router/app_router.dart';

abstract class NavigationService {
  Future<void> push(String location, {Object? extra});
  String? getCurrentLocation();
}

@LazySingleton(as: NavigationService)
class NavigationServiceImpl implements NavigationService {
  @override
  Future<void> push(String location, {Object? extra}) async {
    // We use the static router instance
    await AppRouter.router.push(location, extra: extra);
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
