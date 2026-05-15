import 'package:equatable/equatable.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_cubit.dart';
import 'package:tilawa/features/audio_player/presentation/cubit/player_background_state.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../core/utils/toast_utils.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import '../features/qibla/presentation/bloc/qibla_bloc.dart';
import '../router/app_router_config.dart';
import 'cubit/main_screen_cubit.dart';
import 'cubit/main_screen_state.dart';
import 'widgets/main_bottom_overlay.dart';
import 'widgets/main_tab_viewport.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Duration _deferredPrayerTimesLoadDelay = Duration(
    milliseconds: 600,
  );

  final ValueNotifier<bool> _compactBottomNavVisible = ValueNotifier<bool>(
    true,
  );

  bool _prayerTimesLoadScheduled = false;
  int _lastHandledIndex = 0;

  @override
  void dispose() {
    _compactBottomNavVisible.dispose();
    super.dispose();
  }

  void _handleTabSideEffects(BuildContext context, int previous, int next) {
    final PrayerTimesBloc prayerTimesBloc = context.read<PrayerTimesBloc>();
    final QiblaBloc qiblaBloc = context.read<QiblaBloc>();

    if (previous == 1 && next != 1) {
      qiblaBloc.add(const StopQiblaStream());
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
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('MainScreen');
    return MultiBlocProvider(
      providers: [
        BlocProvider<MainScreenCubit>(create: (_) => MainScreenCubit()),
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
            ToastUtils.showErrorToast(state.failure.localizedMessage(context));
          }
        },
        child: BlocListener<MainScreenCubit, MainScreenState>(
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
              if (!state.isShellActivated) {
                return const _MainShellPlaceholderScaffold();
              }

              final bool isKeyboardOpen = context.isKeyboardVisible;
              final adaptiveShellTokens = Theme.of(
                context,
              ).componentTokens.adaptiveShell;
              final textScaler = MediaQuery.textScalerOf(context);
              final double estimatedBottomNavInnerWidth =
                  MediaQuery.sizeOf(context).width -
                  2 * adaptiveShellTokens.bottomNavHorizontalMargin -
                  2 * adaptiveShellTokens.bottomNavBorderWidth;
              final bool compactIconOnlyBottomNav =
                  context.isCompact &&
                  estimatedBottomNavInnerWidth <
                      TilawaBreakpoints.compactBottomNavAllLabelsMinInnerWidth;
              final double compactNavRowHeight = compactIconOnlyBottomNav
                  ? adaptiveShellTokens.compactBottomNavIconOnlyLayoutHeight(
                      textScaler,
                    )
                  : adaptiveShellTokens.compactBottomNavLayoutHeight(
                      textScaler,
                    );
              final double compactNavContentGap = compactIconOnlyBottomNav
                  ? context.tokens.spaceLarge
                  : context.tokens.spaceExtraLarge;
              // Total visual footprint of the floating bottom nav bar =
              // row height + safe-area bottom + vertical margin + a visual gap
              // so overlapping widgets sit clearly above the bar.
              final double compactNavTopMargin = compactIconOnlyBottomNav
                  ? adaptiveShellTokens.bottomNavIconOnlyVerticalMargin
                  : adaptiveShellTokens.bottomNavVerticalMargin;
              final double bottomNavBarHeight = context.isCompact
                  ? (compactNavRowHeight +
                        context.systemBottomSafeArea +
                        compactNavTopMargin +
                        compactNavContentGap)
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

              return PopScope(
                canPop: state.currentIndex == 0,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  context.read<MainScreenCubit>().selectTab(0);
                },
                child: _MainShellContent(
                  state: state,
                  adaptiveDestinations: adaptiveDestinations,
                  navDestinations: navDestinations,
                  bottomNavBarHeight: bottomNavBarHeight,
                  isKeyboardOpen: isKeyboardOpen,
                  compactBottomNavVisible: _compactBottomNavVisible,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Isolated widget so that [AudioPlayerBloc] position updates only rebuild
/// the content area (player height) rather than the entire shell scaffold.
class _MainShellContent extends StatelessWidget {
  const _MainShellContent({
    required this.state,
    required this.adaptiveDestinations,
    required this.navDestinations,
    required this.bottomNavBarHeight,
    required this.isKeyboardOpen,
    required this.compactBottomNavVisible,
  });

  final MainScreenState state;
  final List<TilawaNavDestination> adaptiveDestinations;
  final List<_NavDestination> navDestinations;
  final double bottomNavBarHeight;
  final bool isKeyboardOpen;
  final ValueNotifier<bool> compactBottomNavVisible;

  @override
  Widget build(BuildContext context) {
    final bool playerShouldShow = state.isAudioBindingDeferred
        ? false
        : context.select((AudioPlayerBloc bloc) {
            final AudioPlayerState audioState = bloc.state;
            return audioState.shouldShowBottomPlayer &&
                audioState.currentAudio != null;
          });

    final double playerHeight = playerShouldShow && !isKeyboardOpen
        ? context.tokens.playerCollapsedHeight
        : 0;
    final double overlayBleedBuffer =
        (playerShouldShow && !isKeyboardOpen && !context.isCompact)
        ? context.tokens.spaceSmall
        : 0;
    final double contentBottomPadding = isKeyboardOpen
        ? 0
        : context.isCompact
        ? (playerShouldShow ? playerHeight + overlayBleedBuffer : 0)
        : bottomNavBarHeight + playerHeight + overlayBleedBuffer;

    return TilawaAdaptiveShell(
      destinations: adaptiveDestinations,
      selectedIndex: navDestinations.indexWhere(
        (d) => d.index == state.currentIndex,
      ),
      onDestinationSelected: (index) {
        if (navDestinations[index].index == null) {
          const QuranLastReadRoute().push(context);
          return;
        }
        context.read<MainScreenCubit>().selectTab(
          navDestinations[index].index!,
        );
      },
      compactBottomNavigationBarVisible: compactBottomNavVisible,
      bottomPlayer: MainBottomOverlay(
        bottomNavBarHeight: context.isCompact ? 0 : bottomNavBarHeight,
        isKeyboardOpen: isKeyboardOpen,
        isAudioBindingDeferred: state.isAudioBindingDeferred,
        isOfflineIndicatorReady: state.isOfflineIndicatorReady,
        compactBottomNavBarVisible: compactBottomNavVisible,
        hostAbsorbsBottomSafeArea: context.isCompact,
      ),
      child: state.isInitialTabMounted
          ? MainTabViewport(
              currentIndex: state.currentIndex,
              builtTabIndexes: state.builtTabIndexes,
              contentBottomPadding: contentBottomPadding,
            )
          : TilawaShellPadding(
              padding: contentBottomPadding,
              child: const _MainShellPlaceholder(),
            ),
    );
  }
}

class _MainShellPlaceholder extends StatelessWidget {
  const _MainShellPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(child: ColoredBox(color: Colors.transparent));
  }
}

class _MainShellPlaceholderScaffold extends StatelessWidget {
  const _MainShellPlaceholderScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      resizeToAvoidBottomInset: false,
      body: _MainShellPlaceholder(),
    );
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
