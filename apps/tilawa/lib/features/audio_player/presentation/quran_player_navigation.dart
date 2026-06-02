import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/navigation/quran_player_navigation.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/shell_route_location.dart';

export 'package:tilawa/core/navigation/quran_player_navigation.dart';

@LazySingleton(as: QuranPlayerNavigation)
class GoRouterQuranPlayerNavigation implements QuranPlayerNavigation {
  @override
  bool get isExpandedRouteOnStack {
    final GoRouter? router = _router;
    if (router == null) {
      return false;
    }
    return ShellRouteLocation.matchedLocationStack(
      router.routerDelegate.currentConfiguration,
    ).contains('/player');
  }

  @override
  Future<void> pushExpanded() async {
    // Push via the GoRouter instance (root navigator) so /player always lands
    // on the root stack regardless of which navigator owns the current context.
    final GoRouter? router = _router;
    if (router == null) {
      return;
    }
    await router.push<void>(const QuranPlayerExpandedRoute().location);
  }

  @override
  void popExpanded() {
    final GoRouter? router = _router;
    if (router == null) {
      return;
    }
    if (router.canPop()) {
      router.pop();
    }
  }

  GoRouter? get _router {
    try {
      return AppRouter.router;
    } catch (_) {
      return null;
    }
  }
}
