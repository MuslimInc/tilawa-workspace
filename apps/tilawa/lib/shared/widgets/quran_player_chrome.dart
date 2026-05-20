import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../router/app_router.dart';
import '../../router/shell_route_location.dart';

/// Layout chrome published by [AppShellScreen] for the mini-player.
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

/// Queue sheet surface; keep in sync with [_PlayerQueueSheet] and expanded-player
/// system chrome overrides.
Color quranPlayerQueueSheetColor(ColorScheme colorScheme) =>
    colorScheme.surfaceContainer;

/// Publishes app-shell chrome while [AppShellScreen] is mounted.
class QuranPlayerChromeNotifier extends ChangeNotifier {
  QuranPlayerShellChrome? _shellChrome;
  Color? _systemNavigationBarColorOverride;
  bool _notifyScheduled = false;

  QuranPlayerShellChrome? get shellChrome => _shellChrome;

  /// While the expanded player overlay is open, matches the queue sheet so the
  /// edge-to-edge gesture strip does not show the default white bottom nav.
  Color? get systemNavigationBarColorOverride =>
      _systemNavigationBarColorOverride;

  /// Updates shell layout chrome for the global player.
  ///
  /// [AppShellScreen] publishes from [build]; listeners are notified after the
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

  void setSystemNavigationBarColorOverride(Color color) {
    if (_systemNavigationBarColorOverride == color) {
      return;
    }
    _systemNavigationBarColorOverride = color;
    notifyListeners();
  }

  void clearSystemNavigationBarColorOverride() {
    if (_systemNavigationBarColorOverride == null) {
      return;
    }
    _systemNavigationBarColorOverride = null;
    notifyListeners();
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

  /// Whether [location] is under the app navigation shell (bottom nav).
  static bool isInAppShell(String location) =>
      AppShellRoutePolicy.showsBottomNavigation(location) ||
      isMainShell(location);

  /// Top-of-stack route (e.g. `/history`), including shell pushes.
  ///
  /// Drills through [ShellRouteMatch] / [ImperativeRouteMatch] so policy code
  /// sees `/history`, not only the shell root `/`.
  static String currentMatchedLocation() =>
      ShellRouteLocation.activeMatchedLocation();
}

/// Bottom navigation visibility for [AppShellScreen].
abstract final class AppShellRoutePolicy {
  static const List<String> _noBottomNavPrefixes = <String>[
    '/quran-reader',
    '/quran-last-read',
    '/athkar',
    '/splash',
    '/onboarding',
    '/login',
    '/share/',
  ];

  static bool showsBottomNavigation(String location) {
    for (final String prefix in _noBottomNavPrefixes) {
      if (location.startsWith(prefix)) {
        return false;
      }
    }
    return true;
  }

  /// Immersive Athkar sub-routes (details, tasbeeh) hide shell chrome.
  ///
  /// [AthkarCategoriesScreen] on the main Athkar tab keeps bottom navigation.
  static bool isAthkarContext(String location) {
    if (location == '/athkar/tasbeeh') {
      return true;
    }
    return location.startsWith('/athkar/') && location != '/athkar';
  }

  /// Whether the expanded player may hide the phone bottom bar.
  ///
  /// Always false: bottom nav stays visible on every shell screen while the
  /// player is expanded.
  static bool shouldHideBottomNavWhenPlayerExpanded(String location) => false;

  /// Highlights a main-shell tab for pushed routes inside the shell.
  static int? navIndexForLocation(String location) {
    if (location == '/' || location.isEmpty) {
      return null;
    }
    if (location.startsWith('/reciter') ||
        location.startsWith('/downloads') ||
        location.startsWith('/favorites') ||
        location.startsWith('/bookmarks') ||
        location.startsWith('/history')) {
      return 0;
    }
    if (location.startsWith('/prayer') || location == '/qibla') {
      return 1;
    }
    if (location.startsWith('/settings') || location == '/premium') {
      return 3;
    }
    return null;
  }
}

/// Bottom spacing for the [QuranPlayerWidget] in [AppShellScreen].
abstract final class QuranPlayerLayoutInsets {
  /// Prefer the navigator subtree for [MediaQuery].
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
        shellTokens.bottomNavVerticalMargin;
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

  /// Bottom offset for the collapsed mini player.
  static double miniPlayerBottomInset({
    required BuildContext context,
    required double hostBottomNavBarHeight,
    required bool hostAbsorbsBottomSafeArea,
    required bool phoneNavVisible,
    String? routePath,
  }) {
    final String location =
        routePath ?? QuranPlayerRoutePolicy.currentMatchedLocation();

    double shellReserve = hostBottomNavBarHeight;
    if (QuranPlayerRoutePolicy.isInAppShell(location)) {
      final QuranPlayerShellChrome? chrome = context
          .read<QuranPlayerChromeNotifier>()
          .shellChrome;
      if (chrome != null && chrome.bottomNavBarHeight > 0) {
        shellReserve = chrome.bottomNavBarHeight;
      }
    }

    final double navColumn = phoneNavVisible ? shellReserve : 0;
    if (navColumn > 0) {
      return navColumn + Theme.of(context).tokens.spaceSmall;
    }
    if (hostAbsorbsBottomSafeArea && hostBottomNavBarHeight <= 0) {
      return 0;
    }
    return offShellBottomInset(context);
  }
}
