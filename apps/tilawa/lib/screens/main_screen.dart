import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/presentation/widgets/offline_indicator_widget.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../features/athkar/presentation/screens/athkar_categories_screen.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import '../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../features/qibla/presentation/bloc/qibla_bloc.dart';
import '../features/reciters/presentation/screens/reciters_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../router/app_router_config.dart';
import '../shared/widgets/bottom_player_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const double _bottomNavBarBaseHeight = 80;

  int _currentIndex = 0;

  final List<Widget> _screens = [
    const RecitersScreen(),
    const PrayerTimesScreen(),
    const AthkarCategoriesScreen(),
    const SettingsScreen(),
  ];

  void _handleTabSideEffects(BuildContext context, int index) {
    final PrayerTimesBloc prayerTimesBloc = context.read<PrayerTimesBloc>();
    prayerTimesBloc.setCountdownActive(index == 1);
    context.read<QiblaBloc>().add(const StopQiblaStream());
  }

  void _selectTab(BuildContext context, int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    _handleTabSideEffects(context, index);
  }

  String _quranNavLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'المصحف'
        : 'Quran';
  }

  List<_NavDestination> _buildDestinations(BuildContext context) {
    return [
      _NavDestination(
        index: 3,
        icon: FluentIcons.settings_24_regular,
        activeIcon: FluentIcons.settings_24_filled,
        label: context.l10n.settings,
      ),
      _NavDestination(
        index: 2,
        icon: FluentIcons.book_open_24_regular,
        activeIcon: FluentIcons.book_open_24_filled,
        svgPath: 'assets/icons/athkar_icon.svg',
        label: context.l10n.athkar,
      ),
      _NavDestination(
        icon: Icons.menu_book_rounded,
        label: _quranNavLabel(context),
      ),
      _NavDestination(
        index: 1,
        icon: FluentIcons.clock_24_regular,
        activeIcon: FluentIcons.clock_24_filled,
        label: context.l10n.prayerTimes,
      ),
      _NavDestination(
        index: 0,
        icon: FluentIcons.person_24_regular,
        activeIcon: FluentIcons.person_24_filled,
        label: context.l10n.reciters,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final double keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;
    final double bottomNavBarHeight = context.isCompact
        ? (_bottomNavBarBaseHeight + bottomPadding)
        : 0;
    final bool playerShouldShow = context.select((AudioPlayerBloc bloc) {
      final AudioPlayerState state = bloc.state;
      return state.shouldShowBottomPlayer && state.currentAudio != null;
    });

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<InternetStatusBloc>()),
        BlocProvider(create: (_) => getIt<QiblaBloc>()),
        BlocProvider(
          create: (_) => getIt<PrayerTimesBloc>()
            ..add(const PrayerTimesEvent.loadPrayerTimes())
            ..setCountdownActive(_currentIndex == 1),
        ),
      ],
      child: Builder(
        builder: (context) {
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
                      iconBuilder: d.svgPath == null
                          ? null
                          : (context, {required isSelected, required color}) {
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
            canPop: _currentIndex == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                return;
              }
              _selectTab(context, 0);
            },
            child: TilawaAdaptiveShell(
              destinations: adaptiveDestinations,
              selectedIndex: navDestinations.indexWhere(
                (d) => d.index == _currentIndex,
              ),
              onDestinationSelected: (index) {
                if (navDestinations[index].index == null) {
                  const QuranLastReadRoute().push(context);
                  return;
                }
                _selectTab(context, navDestinations[index].index!);
              },
              bottomPlayer: Builder(
                builder: (context) {
                  return Stack(
                    children: [
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: OfflineIndicatorWidget(),
                      ),
                      Positioned.fill(
                        child: BottomPlayerWidget(
                          bottomNavBarHeight: bottomNavBarHeight,
                          isKeyboardOpen: isKeyboardOpen,
                        ),
                      ),
                    ],
                  );
                },
              ),
              child: Builder(
                builder: (context) {
                  final double playerHeight = playerShouldShow ? 100 : 0;
                  final double contentBottomPadding =
                      bottomNavBarHeight + playerHeight;

                  return Positioned.fill(
                    child: TilawaShellPadding(
                      padding: contentBottomPadding,
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _screens,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.svgPath,
    this.index,
  });
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? svgPath;
  final int? index;
}
