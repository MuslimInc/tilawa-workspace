import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/shell_route_location.dart';

/// Navigation contract for the expanded Quran player overlay route.
///
/// Prefer [QuranPlayerPresentationEntry.openExpanded] at call sites; this
/// interface is for the controller and tests.
abstract interface class QuranPlayerNavigation {
  /// Whether `/player` is currently on the root navigation stack.
  bool get isExpandedRouteOnStack;

  /// Pushes the typed overlay route. Completes when the route is popped.
  Future<void> pushExpanded();

  /// Pops the overlay route when present.
  void popExpanded();
}

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
    final BuildContext? context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    await const QuranPlayerExpandedRoute().push<void>(context);
  }

  @override
  void popExpanded() {
    final BuildContext? context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    if (context.canPop()) {
      context.pop();
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
