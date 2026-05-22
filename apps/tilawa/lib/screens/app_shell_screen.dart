import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_blocked_flow.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../core/utils/toast_utils.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import '../features/qibla/presentation/bloc/qibla_bloc.dart';
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

class _AppShellScreenState extends State<AppShellScreen> {
  static const Duration _deferredPrayerTimesLoadDelay = Duration(
    milliseconds: 600,
  );

  final ValueNotifier<bool> _phoneBottomNavVisible = ValueNotifier<bool>(true);

  bool _prayerTimesLoadScheduled = false;
  int _lastHandledIndex = 0;
  late final MainScreenCubit _mainScreenCubit;

  @override
  void initState() {
    super.initState();
    _mainScreenCubit = MainScreenCubit();
  }

  @override
  void dispose() {
    try {
      context.read<QuranPlayerChromeNotifier>().clearShellChrome();
    } catch (_) {}
    _mainScreenCubit.close();
    _phoneBottomNavVisible.dispose();
    super.dispose();
  }

  void _handleTabSideEffects(BuildContext context, int previous, int next) {
    final PrayerTimesBloc prayerTimesBloc = context.read<PrayerTimesBloc>();
    final QiblaBloc qiblaBloc = context.read<QiblaBloc>();
    final AppReviewFlowGuard flowGuard = getIt<AppReviewFlowGuard>();
    final AppReviewTriggerManager reviewTrigger =
        getIt<AppReviewTriggerManager>();

    _syncSacredTabFlow(flowGuard, next);

    if (previous == 1 && next != 1) {
      qiblaBloc.add(const StopQiblaStream());
      unawaited(
        reviewTrigger.recordSignal(AppReviewSignal.prayerTimesTabVisited),
      );
      if (next == 0) {
        unawaited(
          reviewTrigger.tryPromptIfEligible(
            AppReviewPromptMoment.leftPrayerTimesTab,
          ),
        );
      }
    }

    if (previous == 2 && next == 0) {
      unawaited(
        reviewTrigger.tryPromptIfEligible(
          AppReviewPromptMoment.returnedToRecitersTab,
        ),
      );
    }

    if (next != 1) {
      return;
    }

    if (!_prayerTimesLoadScheduled) {
      _prayerTimesLoadScheduled = true;
      Future<void>.delayed(_deferredPrayerTimesLoadDelay, () {
        if (!mounted || prayerTimesBloc.isClosed) return;
        prayerTimesBloc.add(const PrayerTimesEvent.loadPrayerTimes());
      });
    }
  }

  void _syncSacredTabFlow(AppReviewFlowGuard guard, int tabIndex) {
    guard.syncMainShellTab(tabIndex);
  }

  List<_NavDestination> _buildDestinations(
    BuildContext context,
    MainScreenState state,
  ) {
    return [
      _NavDestination(
        index: 0,
        icon: FluentIcons.person_24_regular,
        activeIcon: FluentIcons.person_24_filled,
        label: context.l10n.reciters,
        identifier: 'reciters_tab',
      ),
      _NavDestination(
        index: 1,
        icon: FluentIcons.clock_24_regular,
        activeIcon: FluentIcons.clock_24_filled,
        label: context.l10n.prayerTimes,
        identifier: 'prayer_times_tab',
      ),
      _NavDestination(
        label: context.l10n.quran,
        icon: Icons.menu_book_rounded,
        identifier: 'quran_last_read_nav',
      ),
      _NavDestination(
        index: 2,
        icon: FluentIcons.book_open_24_regular,
        activeIcon: FluentIcons.book_open_24_filled,
        svgPath: state.isStartupUiWarm ? 'assets/icons/athkar_icon.svg' : null,
        label: context.l10n.athkar,
      ),
      _NavDestination(
        index: 3,
        icon: FluentIcons.settings_24_regular,
        activeIcon: FluentIcons.settings_24_filled,
        label: context.l10n.settings,
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

  void _navigateToShellTab(BuildContext context, int tabIndex) {
    final String location = QuranPlayerRoutePolicy.currentMatchedLocation();
    final bool onMainShell = QuranPlayerRoutePolicy.isMainShell(location);

    if (!onMainShell) {
      try {
        const HomeRoute().go(context);
      } catch (_) {
        AppRouter.router.go(const HomeRoute().location);
      }
    }

    _mainScreenCubit.selectTab(tabIndex, force: !onMainShell);
  }

  void _onDestinationSelected(
    BuildContext context,
    int index,
    List<_NavDestination> destinations,
  ) {
    final _NavDestination destination = destinations[index];
    if (destination.index == null) {
      const QuranLastReadRoute().push(context);
      return;
    }

    _navigateToShellTab(context, destination.index!);
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('AppShellScreen');
    return MultiBlocProvider(
      providers: [
        BlocProvider<MainScreenCubit>.value(value: _mainScreenCubit),
        BlocProvider<PrayerPermissionsCubit>(
          create: (_) => getIt<PrayerPermissionsCubit>()..checkCapability(),
        ),
        BlocProvider<PrayerTimesBloc>(
          lazy: true,
          create: (_) => getIt<PrayerTimesBloc>(),
        ),
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
                state,
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
                phoneBottomNavVisible: _phoneBottomNavVisible,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    _onDestinationSelected(context, index, navDestinations),
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
  static String? _shellPlayerDebugSignature;

  const _AppShellChrome({
    required this.state,
    required this.adaptiveDestinations,
    required this.navDestinations,
    required this.bottomNavBarHeight,
    required this.isKeyboardOpen,
    required this.phoneBottomNavVisible,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final MainScreenState state;
  final List<TilawaNavDestination> adaptiveDestinations;
  final List<_NavDestination> navDestinations;
  final double bottomNavBarHeight;
  final bool isKeyboardOpen;
  final ValueNotifier<bool> phoneBottomNavVisible;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = QuranPlayerRoutePolicy.currentMatchedLocation();

    context.read<QuranPlayerChromeNotifier>().updateShellChrome(
      QuranPlayerShellChrome(
        bottomNavBarHeight: bottomNavBarHeight,
        isKeyboardOpen: isKeyboardOpen,
        isAudioBindingDeferred: state.isAudioBindingDeferred,
        hostAbsorbsBottomSafeArea: context.isNarrow,
        phoneBottomNavBarVisible: phoneBottomNavVisible,
      ),
    );
    final bool showPlayer =
        QuranPlayerRoutePolicy.shouldShowPlayer(location) &&
        !AppShellRoutePolicy.isAthkarContext(location);

    final bool playerShouldShow = showPlayer &&
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

    final AudioPlayerState audioSnapshot =
        context.read<AudioPlayerBloc>().state;
    if (showPlayer && context.isNarrow) {
      final String shellSig = <String>[
        'route=$location',
        'playerHeight=$playerHeight',
        'playerShouldShow=$playerShouldShow',
        'bindingDeferred=${state.isAudioBindingDeferred}',
        'kb=$isKeyboardOpen',
        'status=${audioSnapshot.status}',
        'audio=${audioSnapshot.currentAudio?.id ?? 'null'}',
        'dismissed=${audioSnapshot.dismissedAudioId}',
        'shouldShowBottom=${audioSnapshot.shouldShowBottomPlayer}',
      ].join('|');
      if (_shellPlayerDebugSignature != shellSig) {
        _shellPlayerDebugSignature = shellSig;
        final String line = jsonEncode(<String, dynamic>{
          'sessionId': 'd8f2b1',
          'runId': 'pre-fix-2',
          'hypothesisId': 'H8',
          'location': 'app_shell_screen.dart:_AppShellChrome.build',
          'message': playerHeight > 0
              ? 'Shell reserves mini-player slot'
              : 'Shell mini-player slot height zero',
          'data': <String, dynamic>{
            'route': location,
            'narrow': true,
            'playerHeight': playerHeight,
            'playerShouldShow': playerShouldShow,
            'isAudioBindingDeferred': state.isAudioBindingDeferred,
            'isKeyboardOpen': isKeyboardOpen,
            'status': audioSnapshot.status.toString(),
            'currentAudioId': audioSnapshot.currentAudio?.id,
            'dismissedAudioId': audioSnapshot.dismissedAudioId,
            'shouldShowBottomPlayer': audioSnapshot.shouldShowBottomPlayer,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        debugPrint('DBG_D8F2B1 $line');
      }
    }

    final Widget shellChild = state.isShellActivated ? child : const SizedBox.shrink();

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
      child: ListenableBuilder(
        listenable: phoneBottomNavVisible,
        builder: (context, _) {
          final bool policyShowsNav =
              AppShellRoutePolicy.showsBottomNavigation(location);
          final bool isAthkar =
              AppShellRoutePolicy.isAthkarContext(location);
          final bool navVisible =
              policyShowsNav && !isAthkar && phoneBottomNavVisible.value;

          final bool narrow = context.isNarrow;
          final Widget? shellFooterPlayer = showPlayer &&
                  playerHeight > 0 &&
                  narrow
              ? SizedBox(
                  height: playerHeight + overlayBleedBuffer,
                  child: QuranPlayerWidget(
                    key: const ValueKey<String>('app_shell_quran_player'),
                    embeddedInShellFooter: true,
                    isKeyboardOpen: isKeyboardOpen,
                    phoneBottomNavBarVisible: phoneBottomNavVisible,
                    hostAbsorbsBottomSafeArea: true,
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
                phoneBottomNavigationBarVisible: _BoolListenable(navVisible),
                phoneFooterAboveNav: shellFooterPlayer,
                bottomPlayer: MainBottomOverlay(
                  isOfflineIndicatorReady: state.isOfflineIndicatorReady,
                ),
                child: shellChild,
              ),
              if (showPlayer && !narrow)
                Positioned.fill(
                  child: QuranPlayerWidget(
                    key: const ValueKey<String>('app_shell_quran_player'),
                    bottomNavBarHeight: bottomNavBarHeight,
                    isKeyboardOpen: isKeyboardOpen,
                    phoneBottomNavBarVisible: phoneBottomNavVisible,
                    hostAbsorbsBottomSafeArea: false,
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

/// [ValueListenable] wrapper for a single bool recomputed on parent rebuilds.
class _BoolListenable implements ValueListenable<bool> {
  _BoolListenable(this.value);

  @override
  final bool value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
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
