import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/presentation/widgets/offline_indicator_widget.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';

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
    final double bottomNavBarHeight = _bottomNavBarBaseHeight + bottomPadding;
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
          final ThemeData theme = Theme.of(context);
          final List<_NavDestination> destinations = _buildDestinations(
            context,
          );

          return PopScope(
            canPop: _currentIndex == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                return;
              }
              _selectTab(context, 0);
            },
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              extendBody: true,
              resizeToAvoidBottomInset: false,
              body: Builder(
                builder: (context) {
                  final double playerHeight = playerShouldShow ? 100 : 0;
                  final double contentBottomPadding =
                      bottomNavBarHeight + playerHeight;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.only(
                            bottom: contentBottomPadding,
                          ),
                          child: IndexedStack(
                            index: _currentIndex,
                            children: _screens,
                          ),
                        ),
                      ),
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
              bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.22,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          children: [
                            for (final _NavDestination destination
                                in destinations)
                              Expanded(
                                child: _BottomNavButton(
                                  icon: destination.icon,
                                  activeIcon:
                                      destination.activeIcon ??
                                      destination.icon,
                                  svgPath: destination.svgPath,
                                  label: destination.label,
                                  isSelected: destination.index != null
                                      ? _currentIndex == destination.index
                                      : false,
                                  onTap: () {
                                    if (destination.index != null) {
                                      _selectTab(context, destination.index!);
                                      return;
                                    }

                                    const QuranLastReadRoute().push(context);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
    this.index,
    required this.icon,
    this.activeIcon,
    this.svgPath,
    required this.label,
  });

  final int? index;
  final IconData icon;
  final IconData? activeIcon;
  final String? svgPath;
  final String label;
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.icon,
    required this.activeIcon,
    this.svgPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String? svgPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color activeColor = theme.primaryColor;
    final Color inactiveColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: 0.7,
    );
    final TextStyle baseLabelStyle =
        theme.textTheme.labelSmall ?? const TextStyle();

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1 : 0.95,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: svgPath != null
                        ? SvgPicture.asset(
                            svgPath!,
                            key: ValueKey('${svgPath}_$isSelected'),
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              isSelected ? activeColor : inactiveColor,
                              BlendMode.srcIn,
                            ),
                          )
                        : Icon(
                            isSelected ? activeIcon : icon,
                            key: ValueKey('${icon.hashCode}_$isSelected'),
                            size: 22,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: baseLabelStyle.copyWith(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
