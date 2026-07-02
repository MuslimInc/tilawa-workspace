import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Resolves the visible route inside [AppShellRoute]'s nested navigator.
///
/// [RouteMatchList.matches].last is often the [ShellRouteMatch] (e.g. `/`),
/// not the leaf screen (e.g. `/history`) pushed on the shell stack.
abstract final class ShellRouteLocation {
  /// Active route path, or null while [RouteMatchList] has no matches yet.
  ///
  /// Reading [RouteMatchList.uri] on an empty configuration throws
  /// [StateError] (No element) during auth teardown or Android back gestures.
  static String? safeUriPath([RouteMatchList? configuration]) {
    try {
      final RouteMatchList config =
          configuration ?? AppRouter.router.routerDelegate.currentConfiguration;
      if (config.isEmpty) {
        return null;
      }
      final String path = config.uri.path;
      if (path.isNotEmpty) {
        return path;
      }
      return activeMatchedLocation(config);
    } catch (_) {
      return null;
    }
  }

  /// Active matched path for shell policy and bottom-nav routing.
  static String activeMatchedLocation([RouteMatchList? configuration]) {
    try {
      final RouteMatchList config =
          configuration ?? AppRouter.router.routerDelegate.currentConfiguration;
      return _leafMatchedLocation(config.matches);
    } catch (_) {
      return '/';
    }
  }

  /// Full stack of matched locations (root → leaf) for debugging.
  static List<String> matchedLocationStack([RouteMatchList? configuration]) {
    try {
      final RouteMatchList config =
          configuration ?? AppRouter.router.routerDelegate.currentConfiguration;
      return _collectLocations(config.matches);
    } catch (_) {
      return const <String>['/'];
    }
  }

  static String _leafMatchedLocation(List<RouteMatchBase> matches) {
    if (matches.isEmpty) {
      return '/';
    }

    RouteMatchBase last = matches.last;
    while (last is ShellRouteMatch) {
      if (last.matches.isEmpty) {
        return last.matchedLocation;
      }
      last = last.matches.last;
    }

    if (last is ImperativeRouteMatch) {
      final RouteMatchList nested = last.matches;
      final String path = nested.uri.path;
      if (path.isNotEmpty) {
        return path;
      }
      return nested.lastOrNull?.matchedLocation ?? last.matchedLocation;
    }

    return last.matchedLocation;
  }

  static List<String> _collectLocations(List<RouteMatchBase> matches) {
    final List<String> stack = <String>[];
    for (final RouteMatchBase match in matches) {
      _appendMatch(stack, match);
    }
    return stack.isEmpty ? const <String>['/'] : stack;
  }

  static void _appendMatch(List<String> stack, RouteMatchBase match) {
    if (match is ShellRouteMatch) {
      stack.add(match.matchedLocation);
      for (final RouteMatchBase child in match.matches) {
        _appendMatch(stack, child);
      }
      return;
    }
    if (match is ImperativeRouteMatch) {
      stack.addAll(_collectLocations(match.matches.matches));
      return;
    }
    stack.add(match.matchedLocation);
  }
}
