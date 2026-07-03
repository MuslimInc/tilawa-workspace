import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa/features/shell/application/shell_tab_coordinator.dart';
import 'package:tilawa/features/shell/presentation/shell_tab_effect_dispatcher.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/reciters/presentation/tour/reciters_tour_targets.dart';
import '../features/tour_guide/presentation/widgets/tour_target.dart';
import '../router/app_router.dart';
import '../router/app_router_config.dart';
import '../shared/widgets/profile_avatar.dart';
import '../shared/widgets/quran_player_chrome.dart';
import '../shared/widgets/quran_player_widget.dart';
import 'app_shell_nav_destinations.dart';
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
  QuranPlayerChromeNotifier? _chromeNotifier;
  bool _isKeyboardOpen = false;
  double _bottomNavBarHeight = 0;

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
    // Cached here (rather than inside the nested BlocBuilder below) so a
    // cubit-driven rebuild never repeats a Theme/MediaQuery ancestor lookup
    // on a context that GlobalKey reparenting may have briefly deactivated.
    _isKeyboardOpen = context.isKeyboardVisible;
    _bottomNavBarHeight = QuranPlayerLayoutInsets.phoneShellBottomReserve(
      context,
    );
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

  List<AppShellNavDestination> _buildDestinations(BuildContext context) {
    return buildPhoneShellNavDestinations(context.l10n);
  }

  List<TilawaNavDestination> _mapAdaptiveDestinations(
    BuildContext context,
    List<AppShellNavDestination> destinations,
  ) {
    final AuthState authState = context.watch<AuthBloc>().state;
    final String? photoUrl = switch (authState) {
      AuthAuthenticated(:final user) => user.photoUrl,
      _ => null,
    };
    final String? displayName = switch (authState) {
      AuthAuthenticated(:final user) => user.displayName,
      _ => null,
    };
    final double profileAvatarSize = Theme.of(
      context,
    ).componentTokens.adaptiveShell.navButtonIconSize;

    return destinations.map((AppShellNavDestination d) {
      TilawaNavIconBuilder? iconBuilder;

      if (d.usesProfileAvatar) {
        iconBuilder =
            (
              BuildContext iconContext, {
              required bool isSelected,
              required Color color,
            }) {
              return ProfileNavAvatar(
                photoUrl: photoUrl,
                displayName: displayName,
                size: profileAvatarSize,
                isSelected: isSelected,
                ringColor: color,
              );
            };
      } else if (d.iconBuilder != null) {
        iconBuilder =
            (
              BuildContext iconContext, {
              required bool isSelected,
              required Color color,
            }) {
              return d.iconBuilder!(iconContext, color: color);
            };
      }

      return TilawaNavDestination(
        label: d.label,
        icon: d.icon,
        activeIcon: d.activeIcon,
        identifier: d.semanticsIdentifier,
        iconBuilder: iconBuilder,
      );
    }).toList();
  }

  int _selectedNavIndex(
    String location,
    MainScreenState state,
    List<AppShellNavDestination> destinations,
  ) {
    if (location.startsWith('/quran-index')) {
      final int quranNavIndex = destinations.indexWhere(
        (d) => d.semanticsIdentifier == 'quran_index_nav',
      );
      return quranNavIndex < 0 ? 0 : quranNavIndex;
    }
    final int? mapped = AppShellRoutePolicy.tabIndexForLocation(location);
    if (mapped != null) {
      final int mappedIndex = destinations.indexWhere(
        (d) => d.tabIndex == mapped,
      );
      return mappedIndex < 0 ? 0 : mappedIndex;
    }
    final int stateIndex = destinations.indexWhere(
      (d) => d.tabIndex == state.currentIndex,
    );
    return stateIndex < 0 ? 0 : stateIndex;
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

  void _onDestinationSelected(
    BuildContext context,
    int index,
    List<AppShellNavDestination> destinations,
  ) {
    final AppShellNavDestination destination = destinations[index];
    if (destination.isPushRoute) {
      const QuranIndexRoute().push(context);
      return;
    }

    final int tabIndex = destination.tabIndex!;
    final bool onMainShell = _isOnMainShell();

    if (onMainShell && _mainScreenCubit.state.currentIndex == tabIndex) {
      _mainScreenCubit.reselectTab(tabIndex);
      return;
    }

    _navigateToShellTab(context, tabIndex);
  }

  void _onAdjacentDestinationSelected(
    BuildContext context,
    TilawaNavAdjacentDirection direction,
    List<AppShellNavDestination> destinations,
    int currentNavIndex,
  ) {
    if (destinations.isEmpty) {
      return;
    }

    final int delta = switch (direction) {
      TilawaNavAdjacentDirection.next => 1,
      TilawaNavAdjacentDirection.previous => -1,
    };
    final int nextIndex =
        (currentNavIndex + delta + destinations.length) % destinations.length;
    _onDestinationSelected(context, nextIndex, destinations);
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
              TilawaFeedback.showToast(
                context,
                message: message,
                variant: TilawaFeedbackVariant.error,
              );
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
              final bool isKeyboardOpen = _isKeyboardOpen;
              final double bottomNavBarHeight = _bottomNavBarHeight;

              final List<AppShellNavDestination> navDestinations =
                  _buildDestinations(context);
              final List<TilawaNavDestination> adaptiveDestinations =
                  _mapAdaptiveDestinations(context, navDestinations);

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
                  navDestinations,
                ),
                onAdjacentDestinationSelected: (direction) =>
                    _onAdjacentDestinationSelected(
                      context,
                      direction,
                      navDestinations,
                      selectedIndex,
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
    required this.onAdjacentDestinationSelected,
    required this.child,
  });

  final MainScreenState state;
  final List<TilawaNavDestination> adaptiveDestinations;
  final List<AppShellNavDestination> navDestinations;
  final double bottomNavBarHeight;
  final bool isKeyboardOpen;
  final _RouteBoundBottomNavVisibility bottomNavVisibility;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<TilawaNavAdjacentDirection> onAdjacentDestinationSelected;
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
        hostAbsorbsBottomSafeArea: navVisible,
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
          final Widget? shellFooterPlayer = showMiniPlayer
              ? SizedBox(
                  height: playerHeight + footerBottomSpacing,
                  child: TourTarget(
                    targetId: RecitersTourTargets.miniPlayer,
                    child: player,
                  ),
                )
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MainBottomOverlay(
                isOfflineIndicatorReady: state.isOfflineIndicatorReady,
              ),
              Expanded(
                child: TilawaAdaptiveShell(
                  destinations: adaptiveDestinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  onAdjacentDestinationSelected: onAdjacentDestinationSelected,
                  phoneBottomNavigationBarVisible: bottomNavVisibility,
                  phoneFooterAboveNav: shellFooterPlayer,
                  bottomPlayer: const SizedBox.shrink(),
                  child: shellChild,
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
