import 'package:equatable/equatable.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa/features/shell/application/shell_tab_coordinator.dart';
import 'package:tilawa/features/shell/presentation/shell_tab_effect_dispatcher.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../core/utils/toast_utils.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/reciters/presentation/tour/reciters_tour_targets.dart';
import '../features/tour_guide/presentation/widgets/tour_target.dart';
import '../router/app_router.dart';
import '../router/app_router_config.dart';
import '../shared/widgets/quran_player_chrome.dart';
import '../shared/widgets/quran_player_widget.dart';
import 'cubit/main_screen_cubit.dart';
import 'cubit/main_screen_state.dart';
import 'widgets/main_bottom_overlay.dart';

/// Persistent shell with bottom navigation and the Quran mini-player.
///
/// [child] is the active [GoRouter] shell route (home tabs or a pushed screen).
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key, required this.child});

  final Widget child;

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

/// Route-owned bottom-nav visibility for [TilawaAdaptiveShell].
///
/// Only [AppShellRoutePolicy] updates this value so child widgets (including
/// the Quran player) cannot leave the bar hidden after leaving `/`.
final class _RouteBoundBottomNavVisibility extends ValueNotifier<bool> {
  _RouteBoundBottomNavVisibility() : super(true);

  void syncForLocation(String location) {
    final bool next = AppShellRoutePolicy.isPhoneBottomNavigationVisible(
      location,
    );
    if (value == next) {
      return;
    }
    value = next;
  }
}

class _AppShellScreenState extends State<AppShellScreen> {
  final _RouteBoundBottomNavVisibility _bottomNavVisibility =
      _RouteBoundBottomNavVisibility();

  late final ShellTabCoordinator _shellTabCoordinator;
  int _lastHandledIndex = 0;
  late final MainScreenCubit _mainScreenCubit;
  DateTime? _lastRecitersNavTap;
  QuranPlayerChromeNotifier? _chromeNotifier;

  static const Duration _recitersNavDoubleTapWindow = Duration(
    milliseconds: 400,
  );

  @override
  void initState() {
    super.initState();
    _shellTabCoordinator = ShellTabCoordinator();
    _mainScreenCubit = MainScreenCubit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ancestor lookups are unsafe in dispose(); cache the notifier here.
    _chromeNotifier = context.read<QuranPlayerChromeNotifier>();
  }

  @override
  void dispose() {
    _chromeNotifier?.clearShellChrome();
    _mainScreenCubit.close();
    _bottomNavVisibility.dispose();
    super.dispose();
  }

  void _handleTabSideEffects(BuildContext context, int previous, int next) {
    dispatchShellTabEffects(
      context,
      _shellTabCoordinator.onTabChanged(
        previousIndex: previous,
        nextIndex: next,
      ),
      isMounted: () => mounted,
    );
  }

  bool _isRecitersTabActive(MainScreenState state) {
    return state.currentIndex == 0 && _isOnMainShell();
  }

  List<_NavDestination> _buildDestinations(BuildContext context) {
    return [
      _NavDestination(
        index: 0,
        icon: FluentIcons.person_24_regular,
        activeIcon: FluentIcons.person_24_filled,
        label: context.l10n.bottomNavReciters,
        identifier: 'reciters_tab',
      ),
      _NavDestination(
        index: 1,
        icon: FluentIcons.clock_24_regular,
        activeIcon: FluentIcons.clock_24_filled,
        label: context.l10n.bottomNavPrayer,
        identifier: 'prayer_times_tab',
      ),
      _NavDestination(
        label: context.l10n.bottomNavQuran,
        icon: Icons.menu_book_rounded,
        identifier: 'quran_last_read_nav',
      ),
      _NavDestination(
        index: 2,
        icon: FluentIcons.book_open_24_regular,
        activeIcon: FluentIcons.book_open_24_filled,
        svgPath: 'assets/icons/athkar_icon.svg',
        label: context.l10n.bottomNavAthkar,
      ),
      _NavDestination(
        index: 3,
        icon: FluentIcons.settings_24_regular,
        activeIcon: FluentIcons.settings_24_filled,
        label: context.l10n.bottomNavSettings,
        identifier: 'settings_tab',
      ),
    ];
  }

  int _selectedNavIndex(
    String location,
    MainScreenState state,
    List<_NavDestination> destinations,
  ) {
    final int? mapped = AppShellRoutePolicy.navIndexForLocation(location);
    if (mapped != null) {
      return destinations.indexWhere((d) => d.index == mapped);
    }
    return destinations.indexWhere((d) => d.index == state.currentIndex);
  }

  bool _isOnMainShell() {
    return QuranPlayerRoutePolicy.isMainShell(
      QuranPlayerRoutePolicy.currentMatchedLocation(),
    );
  }

  void _ensureMainShellRoute(BuildContext context) {
    if (_isOnMainShell()) {
      return;
    }
    try {
      const HomeRoute().go(context);
    } catch (_) {
      AppRouter.router.go(const HomeRoute().location);
    }
  }

  void _navigateToShellTab(BuildContext context, int tabIndex) {
    final bool onMainShell = _isOnMainShell();
    if (!onMainShell) {
      _ensureMainShellRoute(context);
    }
    _mainScreenCubit.selectTab(tabIndex, force: !onMainShell);
  }

  void _onRecitersNavTap(BuildContext context, MainScreenState state) {
    final bool inRecitersExperience = _isRecitersTabActive(state);

    if (!inRecitersExperience) {
      _lastRecitersNavTap = null;
      if (!_isOnMainShell()) {
        _ensureMainShellRoute(context);
      }
      _mainScreenCubit.selectTab(0, force: true);
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? previousTap = _lastRecitersNavTap;
    _lastRecitersNavTap = now;

    if (previousTap != null &&
        now.difference(previousTap) <= _recitersNavDoubleTapWindow) {
      _lastRecitersNavTap = null;
      _mainScreenCubit.requestRecitersSearchFocus();
    }
  }

  void _onDestinationSelected(
    BuildContext context,
    int index,
    MainScreenState state,
    List<_NavDestination> destinations,
  ) {
    final _NavDestination destination = destinations[index];
    if (destination.index == null) {
      const QuranLastReadRoute().push(context);
      return;
    }

    if (destination.index == 0) {
      _onRecitersNavTap(context, state);
      return;
    }

    _lastRecitersNavTap = null;
    _navigateToShellTab(context, destination.index!);
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('AppShellScreen');
    return MultiBlocProvider(
      providers: [
        BlocProvider<MainScreenCubit>.value(value: _mainScreenCubit),
        BlocProvider<InternetStatusBloc>(
          lazy: true,
          create: (_) => getIt<InternetStatusBloc>(),
        ),
      ],
      child: BlocListener<PlayerBackgroundCubit, PlayerBackgroundState>(
        listenWhen: (previous, current) => current is PlayerBackgroundError,
        listener: (context, state) {
          if (state is PlayerBackgroundError) {
            final String? message = state.failure.localizedMessage(context);
            if (message != null) {
              ToastUtils.showErrorToast(message);
            }
          }
        },
        child: BlocListener<MainScreenCubit, MainScreenState>(
          listenWhen: (previous, current) =>
              previous.currentIndex != current.currentIndex,
          listener: (context, state) {
            if (state.currentIndex == _lastHandledIndex) return;
            _handleTabSideEffects(
              context,
              _lastHandledIndex,
              state.currentIndex,
            );
            _lastHandledIndex = state.currentIndex;
          },
          child: BlocBuilder<MainScreenCubit, MainScreenState>(
            builder: (context, state) {
              final bool isKeyboardOpen = context.isKeyboardVisible;
              final double bottomNavBarHeight = context.isNarrow
                  ? QuranPlayerLayoutInsets.phoneShellBottomReserve(context)
                  : context.floatingBottomPadding;

              final List<_NavDestination> navDestinations = _buildDestinations(
                context,
              );
              final List<TilawaNavDestination> adaptiveDestinations =
                  navDestinations
                      .map(
                        (d) => TilawaNavDestination(
                          label: d.label,
                          icon: d.icon,
                          activeIcon: d.activeIcon,
                          identifier: d.identifier,
                          iconBuilder: d.svgPath == null
                              ? null
                              : (
                                  context, {
                                  required isSelected,
                                  required color,
                                }) {
                                  return SvgPicture.asset(
                                    d.svgPath!,
                                    width: 22,
                                    height: 22,
                                    colorFilter: ColorFilter.mode(
                                      color,
                                      BlendMode.srcIn,
                                    ),
                                  );
                                },
                        ),
                      )
                      .toList();

              final String location =
                  QuranPlayerRoutePolicy.currentMatchedLocation();
              final int selectedIndex = _selectedNavIndex(
                location,
                state,
                navDestinations,
              );

              return _AppShellChrome(
                state: state,
                adaptiveDestinations: adaptiveDestinations,
                navDestinations: navDestinations,
                bottomNavBarHeight: bottomNavBarHeight,
                isKeyboardOpen: isKeyboardOpen,
                bottomNavVisibility: _bottomNavVisibility,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onDestinationSelected(
                  context,
                  index,
                  state,
                  navDestinations,
                ),
                child: widget.child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AppShellChrome extends StatelessWidget {
  const _AppShellChrome({
    required this.state,
    required this.adaptiveDestinations,
    required this.navDestinations,
    required this.bottomNavBarHeight,
    required this.isKeyboardOpen,
    required this.bottomNavVisibility,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final MainScreenState state;
  final List<TilawaNavDestination> adaptiveDestinations;
  final List<_NavDestination> navDestinations;
  final double bottomNavBarHeight;
  final bool isKeyboardOpen;
  final _RouteBoundBottomNavVisibility bottomNavVisibility;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = QuranPlayerRoutePolicy.currentMatchedLocation();
    bottomNavVisibility.syncForLocation(location);
    final bool navVisible = AppShellRoutePolicy.isPhoneBottomNavigationVisible(
      location,
    );

    context.read<QuranPlayerChromeNotifier>().updateShellChrome(
      QuranPlayerShellChrome(
        bottomNavBarHeight: navVisible ? bottomNavBarHeight : 0,
        isKeyboardOpen: isKeyboardOpen,
        isAudioBindingDeferred: state.isAudioBindingDeferred,
        hostAbsorbsBottomSafeArea: context.isNarrow && navVisible,
      ),
    );
    final bool showPlayer =
        QuranPlayerRoutePolicy.shouldShowPlayer(location) &&
        !AppShellRoutePolicy.isAthkarContext(location);

    final bool playerShouldShow =
        showPlayer &&
        (state.isAudioBindingDeferred
            ? false
            : context.select((AudioPlayerBloc bloc) {
                final AudioPlayerState audioState = bloc.state;
                return audioState.shouldShowBottomPlayer &&
                    audioState.currentAudio != null;
              }));

    final double playerHeight = playerShouldShow && !isKeyboardOpen
        ? context.tokens.playerCollapsedHeight
        : 0;
    final double overlayBleedBuffer =
        (playerShouldShow && !isKeyboardOpen && !context.isNarrow)
        ? context.tokens.spaceSmall
        : 0;

    // Main tab shell (`/`) defers paint until [MainScreenCubit] activates.
    // Pushed shell routes (e.g. prayer-alerts permissions) must paint
    // immediately — otherwise users see a blank/grey screen behind chrome.
    final Widget shellChild =
        QuranPlayerRoutePolicy.isMainShell(location) && !state.isShellActivated
        ? const SizedBox.shrink()
        : child;

    return PopScope(
      canPop: _canPopShell(context, location, state),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final MainScreenCubit mainScreenCubit = context.read<MainScreenCubit>();
        if (!QuranPlayerRoutePolicy.isMainShell(location)) {
          const HomeRoute().go(context);
          mainScreenCubit.selectTab(0);
          return;
        }
      },
      child: Builder(
        builder: (context) {
          final bool showMiniPlayer =
              showPlayer && playerShouldShow && !isKeyboardOpen;

          final bool narrow = context.isNarrow;
          final Widget player = QuranPlayerWidget(
            key: const ValueKey<String>('app_shell_quran_player'),
            isKeyboardOpen: isKeyboardOpen,
            hostAbsorbsBottomSafeArea: navVisible,
          );
          final double footerBottomSpacing = navVisible
              ? 0
              : QuranPlayerLayoutInsets.phoneFooterBottomSpacing(
                  context,
                  hostAbsorbsBottomSafeArea: navVisible,
                );
          final Widget? shellFooterPlayer = showMiniPlayer && narrow
              ? SizedBox(
                  height:
                      playerHeight + overlayBleedBuffer + footerBottomSpacing,
                  child: TourTarget(
                    targetId: RecitersTourTargets.miniPlayer,
                    child: player,
                  ),
                )
              : null;

          return Stack(
            fit: StackFit.expand,
            children: [
              TilawaAdaptiveShell(
                destinations: adaptiveDestinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                phoneBottomNavigationBarVisible: bottomNavVisibility,
                phoneFooterAboveNav: shellFooterPlayer,
                bottomPlayer: MainBottomOverlay(
                  isOfflineIndicatorReady: state.isOfflineIndicatorReady,
                ),
                child: shellChild,
              ),
              // Bottom-anchored with loose height: the footer mini paints an
              // opaque ColoredBox, so Positioned.fill would cover the whole
              // shell (rail included) with the player chrome color.
              if (showMiniPlayer && !narrow)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: TourTarget(
                    targetId: RecitersTourTargets.miniPlayer,
                    child: QuranPlayerWidget(
                      key: const ValueKey<String>('app_shell_quran_player'),
                      bottomNavBarHeight: bottomNavBarHeight,
                      isKeyboardOpen: isKeyboardOpen,
                      hostAbsorbsBottomSafeArea: false,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Shell never exits the app; [RecitersScreen] is the only exit point.
  bool _canPopShell(
    BuildContext context,
    String location,
    MainScreenState state,
  ) {
    return false;
  }
}

@immutable
class _NavDestination extends Equatable {
  const _NavDestination({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.svgPath,
    this.index,
    this.identifier,
  });
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? svgPath;
  final int? index;
  final String? identifier;

  @override
  List<Object?> get props => [
    label,
    icon,
    activeIcon,
    svgPath,
    index,
    identifier,
  ];
}
