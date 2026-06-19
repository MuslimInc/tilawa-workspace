import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../router/app_router.dart';
import '../../router/app_router_config.dart';
import '../../router/shell_route_location.dart';
import '../../screens/app_shell_nav_destinations.dart';
import '../../screens/cubit/main_screen_cubit.dart';

/// Layout chrome published by [AppShellScreen] for the mini-player.
@immutable
class QuranPlayerShellChrome {
  const QuranPlayerShellChrome({
    required this.bottomNavBarHeight,
    required this.isKeyboardOpen,
    required this.isAudioBindingDeferred,
    required this.hostAbsorbsBottomSafeArea,
  });

  final double bottomNavBarHeight;
  final bool isKeyboardOpen;
  final bool isAudioBindingDeferred;
  final bool hostAbsorbsBottomSafeArea;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuranPlayerShellChrome &&
            bottomNavBarHeight == other.bottomNavBarHeight &&
            isKeyboardOpen == other.isKeyboardOpen &&
            isAudioBindingDeferred == other.isAudioBindingDeferred &&
            hostAbsorbsBottomSafeArea == other.hostAbsorbsBottomSafeArea;
  }

  @override
  int get hashCode => Object.hash(
    bottomNavBarHeight,
    isKeyboardOpen,
    isAudioBindingDeferred,
    hostAbsorbsBottomSafeArea,
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
    _scheduleNotifyListeners();
  }

  void clearSystemNavigationBarColorOverride() {
    if (_systemNavigationBarColorOverride == null) {
      return;
    }
    _systemNavigationBarColorOverride = null;
    _scheduleNotifyListeners();
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
    '/language-welcome',
    '/onboarding',
    '/login',
    '/prayer-alerts-permissions',
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
      AppShellRoutePolicy.isInsideAppShell(location);

  /// Top-of-stack route (e.g. `/history`), including shell pushes.
  ///
  /// Drills through [ShellRouteMatch] / [ImperativeRouteMatch] so policy code
  /// sees `/history`, not only the shell root `/`.
  static String currentMatchedLocation() =>
      ShellRouteLocation.activeMatchedLocation();
}

/// Bottom navigation visibility for [AppShellScreen].
abstract final class AppShellRoutePolicy {
  /// Routes declared outside [TypedShellRoute] (full-screen, no shell chrome).
  static const List<String> _outsideAppShellPrefixes = <String>[
    '/quran-reader',
    '/quran-last-read',
    '/splash',
    '/language-welcome',
    '/onboarding',
    '/login',
    '/prayer-alerts-permissions',
    '/share/',
    '/athkar',
    '/player',
  ];

  /// Bottom navigation is only shown on the main tab shell (`/`).
  static bool showsBottomNavigation(String location) {
    return QuranPlayerRoutePolicy.isMainShell(location);
  }

  /// Whether [location] is rendered inside [AppShellScreen] (with or without nav).
  static bool isInsideAppShell(String location) {
    for (final String prefix in _outsideAppShellPrefixes) {
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

  /// Whether the phone bottom bar should be visible for [location].
  ///
  /// Only the main tab shell (`/`) shows bottom navigation. Immersive Athkar
  /// sub-routes are excluded even when they are shell children.
  static bool isPhoneBottomNavigationVisible(String location) {
    return showsBottomNavigation(location) && !isAthkarContext(location);
  }

  /// Highlights a main-shell tab for pushed routes inside the shell.
  static int? navIndexForLocation(String location) {
    if (location == '/' || location.isEmpty) {
      return null;
    }
    if (location.startsWith('/reciter') ||
        location.startsWith('/reciters') ||
        location.startsWith('/downloads') ||
        location.startsWith('/favorites') ||
        location.startsWith('/bookmarks') ||
        location.startsWith('/history')) {
      return kAppShellRecitersTabIndex;
    }
    if (location.startsWith('/qibla')) {
      return 2;
    }
    if (location.startsWith('/settings') ||
        location == '/support' ||
        location == '/premium') {
      return kAppShellSettingsTabIndex;
    }
    return null;
  }
}

/// Bottom spacing for the [QuranPlayerWidget] in [AppShellScreen].
abstract final class QuranPlayerLayoutInsets {
  /// Prefer the navigator subtree for [MediaQuery].
  static BuildContext mediaQueryContext(BuildContext context) =>
      AppRouter.navigatorKey.currentContext ?? context;

  /// Height from the screen bottom through the phone shell bottom nav.
  static double phoneShellBottomReserve(BuildContext context) {
    final TilawaAdaptiveShellTokens shellTokens = Theme.of(
      context,
    ).componentTokens.adaptiveShell;
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final double rowHeight = shellTokens.phoneBottomNavPaintedHeight(
      textScaler,
      context.systemBottomSafeArea,
    );
    return rowHeight;
  }

  /// Bottom inset on routes without the shell nav (e.g. `/reciter/:id`).
  ///
  /// Matches [TilawaSafeAreaX.floatingBottomPadding] so FABs, lists, and the
  /// mini player share the same lift above the home indicator.
  static double offShellBottomInset(BuildContext context) {
    return mediaQueryContext(context).floatingBottomPadding;
  }

  /// Extension below the collapsed bar on wide shell layouts.
  ///
  /// YouTube Music-style: bar controls sit in [playerCollapsedHeight]; the
  /// shell background continues through the home-indicator zone only (no extra
  /// [floatingBottomPadding] buffer).
  static double wideShellFooterBottomExtension(BuildContext context) {
    return mediaQueryContext(context).systemBottomSafeArea;
  }

  /// Space reserved below the mini player inside the shell footer column.
  ///
  /// Phone: [offShellBottomInset] when the bottom bar is hidden.
  /// Wide: [wideShellFooterBottomExtension] only.
  static double phoneFooterBottomSpacing(
    BuildContext context, {
    required bool hostAbsorbsBottomSafeArea,
  }) {
    if (hostAbsorbsBottomSafeArea) {
      return 0;
    }
    final BuildContext mqContext = mediaQueryContext(context);
    if (!mqContext.isNarrow) {
      return wideShellFooterBottomExtension(context);
    }
    return offShellBottomInset(context);
  }

  /// Total height of the phone shell footer player slot (bar + bottom gap).
  static double phoneFooterSlotHeight(
    BuildContext context, {
    required double playerHeight,
    required bool hostAbsorbsBottomSafeArea,
  }) {
    return phoneMiniPlayerTopPadding(context) +
        playerHeight +
        phoneFooterBottomSpacing(
          context,
          hostAbsorbsBottomSafeArea: hostAbsorbsBottomSafeArea,
        );
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
      return navColumn;
    }
    if (hostAbsorbsBottomSafeArea && hostBottomNavBarHeight <= 0) {
      return 0;
    }
    final BuildContext mqContext = mediaQueryContext(context);
    if (!mqContext.isNarrow && QuranPlayerRoutePolicy.isInAppShell(location)) {
      return 0;
    }
    return offShellBottomInset(context);
  }

  /// Gap between the shell mini player capsule and the bottom nav pill.
  static double phoneMiniPlayerNavGap(BuildContext context) {
    return Theme.of(
      context,
    ).componentTokens.adaptiveShell.bottomNavInternalPadding;
  }

  /// Breathing room above the shell mini player capsule.
  static double phoneMiniPlayerTopPadding(BuildContext context) {
    return Theme.of(
      context,
    ).componentTokens.adaptiveShell.bottomNavInternalPadding;
  }
}

/// Shell navigation helpers for the global Quran mini player.
abstract final class QuranPlayerShellNavigation {
  /// Opens the Reciters main tab from the mini player metadata strip.
  static void openRecitersTab(BuildContext context) {
    final String location = QuranPlayerRoutePolicy.currentMatchedLocation();
    final bool onMainShell = QuranPlayerRoutePolicy.isMainShell(location);
    if (!onMainShell) {
      try {
        const HomeRoute().go(context);
      } catch (_) {
        AppRouter.router.go(const HomeRoute().location);
      }
    }
    context.read<MainScreenCubit>().selectTab(
      kAppShellRecitersTabIndex,
      force: !onMainShell,
    );
  }
}
