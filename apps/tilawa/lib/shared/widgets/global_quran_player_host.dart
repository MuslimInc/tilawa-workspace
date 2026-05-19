import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../router/app_router.dart';
import 'quran_player_chrome.dart';
import 'quran_player_widget.dart';

/// Hosts a single app-wide [QuranPlayerWidget] via the root navigator [Overlay].
///
/// [MaterialApp.builder] sits above the navigator, so the player is inserted as
/// an [OverlayEntry] on [AppRouter.navigatorKey] instead of a [Stack] sibling.
class GlobalQuranPlayerHost extends StatefulWidget {
  const GlobalQuranPlayerHost({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalQuranPlayerHost> createState() => _GlobalQuranPlayerHostState();
}

class _GlobalQuranPlayerHostState extends State<GlobalQuranPlayerHost> {
  late final GoRouter _router;
  late final VoidCallback _onRouteChanged;
  OverlayEntry? _playerEntry;
  bool _chromeListenerAttached = false;
  bool _syncScheduled = false;

  double _bottomNavBarHeight = 0;
  bool _isKeyboardOpen = false;
  bool _hostAbsorbsBottomSafeArea = false;
  ValueNotifier<bool>? _phoneBottomNavBarVisible;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router;
    _onRouteChanged = _scheduleSync;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _router.routerDelegate.addListener(_onRouteChanged);
      _scheduleSync();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chromeListenerAttached) {
      return;
    }
    _chromeListenerAttached = true;
    context.read<QuranPlayerChromeNotifier>().addListener(_scheduleSync);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    if (_chromeListenerAttached) {
      context.read<QuranPlayerChromeNotifier>().removeListener(_scheduleSync);
    }
    _removePlayerEntry();
    super.dispose();
  }

  void _scheduleSync() {
    if (_syncScheduled || !mounted) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) {
        _syncOverlayEntry();
      }
    });
  }

  String get _currentLocation => QuranPlayerRoutePolicy.currentMatchedLocation();

  void _syncOverlayEntry() {
    final OverlayState? overlay = AppRouter.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      _scheduleSync();
      return;
    }

    final String location = _currentLocation;
    if (!QuranPlayerRoutePolicy.shouldShowPlayer(location)) {
      _removePlayerEntry();
      return;
    }

    final QuranPlayerChromeNotifier chromeNotifier = context
        .read<QuranPlayerChromeNotifier>();
    final bool onMainShell = QuranPlayerRoutePolicy.isMainShell(location);
    final QuranPlayerShellChrome? shellChrome = chromeNotifier.shellChrome;

    if (onMainShell && shellChrome != null && shellChrome.isAudioBindingDeferred) {
      _removePlayerEntry();
      return;
    }

    final BuildContext mqContext =
        QuranPlayerLayoutInsets.mediaQueryContext(context);
    _isKeyboardOpen = onMainShell && shellChrome != null
        ? shellChrome.isKeyboardOpen
        : MediaQuery.viewInsetsOf(mqContext).bottom > 0;
    if (onMainShell && shellChrome != null) {
      _bottomNavBarHeight = shellChrome.bottomNavBarHeight;
      _hostAbsorbsBottomSafeArea = shellChrome.hostAbsorbsBottomSafeArea;
    } else {
      _bottomNavBarHeight = 0;
      _hostAbsorbsBottomSafeArea = false;
    }
    _phoneBottomNavBarVisible = onMainShell && shellChrome != null
        ? shellChrome.phoneBottomNavBarVisible
        : null;

    if (_playerEntry == null) {
      _playerEntry = OverlayEntry(builder: _buildPlayerOverlay);
      overlay.insert(_playerEntry!);
    } else {
      _playerEntry!.markNeedsBuild();
    }
  }

  Widget _buildPlayerOverlay(BuildContext context) {
    return Positioned.fill(
      child: ListenableBuilder(
        listenable: context.read<QuranPlayerChromeNotifier>(),
        builder: (context, _) {
          final String location =
              QuranPlayerRoutePolicy.currentMatchedLocation();
          final bool onMainShell = QuranPlayerRoutePolicy.isMainShell(location);
          final QuranPlayerShellChrome? shell = context
              .read<QuranPlayerChromeNotifier>()
              .shellChrome;
          final double bottomNavBarHeight = onMainShell && shell != null
              ? shell.bottomNavBarHeight
              : _bottomNavBarHeight;

          return QuranPlayerWidget(
            key: const ValueKey<String>('global_quran_player'),
            bottomNavBarHeight: bottomNavBarHeight,
            isKeyboardOpen: _isKeyboardOpen,
            phoneBottomNavBarVisible: _phoneBottomNavBarVisible,
            hostAbsorbsBottomSafeArea: _hostAbsorbsBottomSafeArea,
          );
        },
      ),
    );
  }

  void _removePlayerEntry() {
    if (_playerEntry == null) {
      return;
    }
    _playerEntry!.remove();
    _playerEntry!.dispose();
    _playerEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    _scheduleSync();
    return widget.child;
  }
}
