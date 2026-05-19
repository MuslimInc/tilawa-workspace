import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../router/app_router.dart';

/// Layout chrome published by [MainScreen] for the global mini-player on `/`.
@immutable
class QuranPlayerShellChrome {
  const QuranPlayerShellChrome({
    required this.bottomNavBarHeight,
    required this.isKeyboardOpen,
    required this.isAudioBindingDeferred,
    required this.hostAbsorbsBottomSafeArea,
    this.phoneBottomNavBarVisible,
  });

  final double bottomNavBarHeight;
  final bool isKeyboardOpen;
  final bool isAudioBindingDeferred;
  final bool hostAbsorbsBottomSafeArea;
  final ValueNotifier<bool>? phoneBottomNavBarVisible;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuranPlayerShellChrome &&
            bottomNavBarHeight == other.bottomNavBarHeight &&
            isKeyboardOpen == other.isKeyboardOpen &&
            isAudioBindingDeferred == other.isAudioBindingDeferred &&
            hostAbsorbsBottomSafeArea == other.hostAbsorbsBottomSafeArea &&
            phoneBottomNavBarVisible == other.phoneBottomNavBarVisible;
  }

  @override
  int get hashCode => Object.hash(
    bottomNavBarHeight,
    isKeyboardOpen,
    isAudioBindingDeferred,
    hostAbsorbsBottomSafeArea,
    phoneBottomNavBarVisible,
  );
}

/// Publishes main-shell chrome while [MainScreen] is mounted.
class QuranPlayerChromeNotifier extends ChangeNotifier {
  QuranPlayerShellChrome? _shellChrome;
  bool _notifyScheduled = false;

  QuranPlayerShellChrome? get shellChrome => _shellChrome;

  /// Updates shell layout chrome for the global player.
  ///
  /// [MainScreen] publishes from [build]; listeners are notified after the
  /// frame so [Provider] does not mark dependents dirty during build.
  void updateShellChrome(QuranPlayerShellChrome? chrome) {
    if (_shellChrome == chrome) {
      return;
    }
    _shellChrome = chrome;
    _scheduleNotifyListeners();
  }

  void clearShellChrome() {
    updateShellChrome(null);
  }

  void _scheduleNotifyListeners() {
    if (_notifyScheduled) {
      return;
    }
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }
}

/// Routes where the global bottom player must not appear.
abstract final class QuranPlayerRoutePolicy {
  static const List<String> _hiddenPrefixes = <String>[
    '/quran-reader',
    '/quran-last-read',
    '/splash',
    '/onboarding',
    '/login',
    '/share/',
  ];

  static bool shouldShowPlayer(String location) {
    for (final String prefix in _hiddenPrefixes) {
      if (location.startsWith(prefix)) {
        return false;
      }
    }
    return true;
  }

  static bool isMainShell(String location) =>
      location == '/' || location.isEmpty;

  /// Top-of-stack route (e.g. `/reciter/1`), not [Uri.path] alone (`/`).
  ///
  /// [GoRouter]'s [RouteMatchList.uri] reflects the stack root; use
  /// [RouteMatch.matchedLocation] for the visible screen.
  static String currentMatchedLocation() {
    try {
      final List<RouteMatchBase> matches =
          AppRouter.router.routerDelegate.currentConfiguration.matches;
      if (matches.isEmpty) {
        return '/';
      }
      return matches.last.matchedLocation;
    } catch (_) {
      return '/';
    }
  }
}

/// Bottom spacing for the global [QuranPlayerWidget] overlay.
abstract final class QuranPlayerLayoutInsets {
  /// Prefer the navigator subtree for [MediaQuery] (overlay sits above routes).
  static BuildContext mediaQueryContext(BuildContext context) =>
      AppRouter.navigatorKey.currentContext ?? context;

  /// Height from the screen bottom through the phone shell bottom nav, plus a
  /// small gap so the mini player sits just above the bar.
  static double phoneShellBottomReserve(BuildContext context) {
    final TilawaAdaptiveShellTokens shellTokens = Theme.of(
      context,
    ).componentTokens.adaptiveShell;
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final double rowHeight = shellTokens.phoneBottomNavLayoutHeight(textScaler);
    return rowHeight +
        context.systemBottomSafeArea +
        shellTokens.bottomNavVerticalMargin +
        Theme.of(context).tokens.spaceSmall;
  }

  /// Bottom inset on routes without the shell nav (e.g. `/reciter/:id`).
  static double offShellBottomInset(BuildContext context) {
    final BuildContext mq = mediaQueryContext(context);
    final double safe = mq.systemBottomSafeArea;
    if (safe > 0) {
      return safe + Theme.of(mq).tokens.spaceTiny;
    }
    return Theme.of(mq).tokens.spaceSmall;
  }

  /// Whether a modal route (sheet, dialog) covers the screen bottom.
  static bool shouldHideMiniPlayerForModal(BuildContext context) {
    final ModalRoute<dynamic>? route = ModalRoute.of(mediaQueryContext(context));
    if (route == null || !route.isActive) {
      return false;
    }
    final Color? barrier = route.barrierColor;
    return barrier != null && barrier.a > 0;
  }

  /// Bottom offset for the collapsed mini player.
  static double miniPlayerBottomInset({
    required BuildContext context,
    required double hostBottomNavBarHeight,
    required bool hostAbsorbsBottomSafeArea,
    required bool phoneNavVisible,
    String? routePath,
  }) {
    final String location = routePath ?? QuranPlayerRoutePolicy.currentMatchedLocation();

    double shellReserve = hostBottomNavBarHeight;
    if (QuranPlayerRoutePolicy.isMainShell(location)) {
      final QuranPlayerShellChrome? chrome = context
          .read<QuranPlayerChromeNotifier>()
          .shellChrome;
      if (chrome != null && chrome.bottomNavBarHeight > 0) {
        shellReserve = chrome.bottomNavBarHeight;
      }
    }

    final double navColumn = phoneNavVisible ? shellReserve : 0;
    if (navColumn > 0) {
      return navColumn;
    }
    if (hostAbsorbsBottomSafeArea && hostBottomNavBarHeight <= 0) {
      return 0;
    }
    return offShellBottomInset(context);
  }
}
