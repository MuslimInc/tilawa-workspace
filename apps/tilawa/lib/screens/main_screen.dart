import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/presentation/widgets/offline_indicator_widget.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';

import '../core/presentation/cubit/ui_visibility_cubit.dart';
import '../features/athkar/presentation/screens/athkar_categories_screen.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import '../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../features/qibla/presentation/bloc/qibla_bloc.dart';
import '../features/quran_reader/presentation/screens/quran_font_loader_screen.dart';
import '../features/reciters/presentation/screens/reciters_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../shared/widgets/bottom_player_widget.dart';

bool shouldHandleBottomNavTap({
  required int currentIndex,
  required int tappedIndex,
}) {
  return tappedIndex != currentIndex;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const QuranFontLoaderScreen(surahNumber: 0),
    const RecitersScreen(),
    const PrayerTimesScreen(),
    const AthkarCategoriesScreen(),
    const SettingsScreen(),
  ];

  void _handleTabSideEffects(BuildContext context, int index) {
    final PrayerTimesBloc prayerTimesBloc = context.read<PrayerTimesBloc>();
    prayerTimesBloc.setCountdownActive(index == 2);

    if (index == 5) {
      // Qibla is no longer in main nav, but if it was index 5
      // context.read<QiblaBloc>().add(const CheckLocationService());
    } else {
      context.read<QiblaBloc>().add(const StopQiblaStream());
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    if (_currentIndex == 0) {
      return const Color(0xFFF9F5EF); // Match Quran reader bg
    }
    return Theme.of(context).scaffoldBackgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<InternetStatusBloc>()),
        BlocProvider(create: (_) => getIt<QiblaBloc>()),
        BlocProvider(
          create: (_) => getIt<PrayerTimesBloc>()
            ..add(const PrayerTimesEvent.loadPrayerTimes())
            ..setCountdownActive(_currentIndex == 2),
        ),
      ],
      child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          return PopScope(
            canPop: _currentIndex == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                return;
              }
              setState(() {
                _currentIndex = 0;
              });
              _handleTabSideEffects(context, _currentIndex);
            },
            child: Scaffold(
              backgroundColor: _getBackgroundColor(context),
              extendBody: true,
              body: BlocBuilder<UiVisibilityCubit, bool>(
                builder: (context, isVisible) {
                  return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                    builder: (context, audioState) {
                      // Base height (~72h) + top/bottom padding (8h + 8h)
                      // We always reserve space if the player SHOULD be showing,
                      // even if it's currently animatng.
                      final bool playerShouldShow =
                          audioState.shouldShowBottomPlayer &&
                          audioState.currentAudio != null;
                      final double playerHeight = isVisible && playerShouldShow
                          ? 88.h
                          : 0;

                      return Stack(
                        children: [
                          // Main content layer - Using Positioned.fill to keep layout bounds stable
                          Positioned.fill(
                            child: AnimatedPadding(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: EdgeInsets.only(
                                bottom: isVisible
                                    ? (80.h + playerHeight)
                                    : (MediaQuery.viewPaddingOf(
                                            context,
                                          ).bottom +
                                          20.h),
                              ),
                              child: IndexedStack(
                                index: _currentIndex,
                                children: _screens,
                              ),
                            ),
                          ),

                          // Offline indicator overlay at the top
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: OfflineIndicatorWidget(),
                          ),

                          // Bottom Player overlay — Positioned.fill allows
                          // the player to expand to full-screen (YouTube/Spotify UX).
                          Positioned.fill(
                            child: BottomPlayerWidget(
                              bottomNavBarHeight: isVisible ? 80.h : 0,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              bottomNavigationBar: BlocBuilder<UiVisibilityCubit, bool>(
                builder: (context, isVisible) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      final offsetAnimation =
                          Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          );
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                    child: isVisible
                        ? BottomAppBar(
                            key: const ValueKey('bottom_app_bar'),
                            elevation:
                                8, // Added elevation for better separation
                            color: theme.cardColor,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: _BottomNavItem(
                                      index: 4,
                                      currentIndex: _currentIndex,
                                      icon: FluentIcons.settings_24_regular,
                                      activeIcon:
                                          FluentIcons.settings_24_filled,
                                      label: context.l10n.settings,
                                      onTap: (index) {
                                        setState(() => _currentIndex = index);
                                        _handleTabSideEffects(context, index);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _BottomNavItem(
                                      index: 3,
                                      currentIndex: _currentIndex,
                                      icon: FluentIcons.book_open_24_regular,
                                      activeIcon:
                                          FluentIcons.book_open_24_filled,
                                      svgPath: 'assets/icons/athkar_icon.svg',
                                      label: context.l10n.athkar,
                                      onTap: (index) {
                                        setState(() => _currentIndex = index);
                                        _handleTabSideEffects(context, index);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _BottomNavItem(
                                      index: 0,
                                      currentIndex: _currentIndex,
                                      icon: FluentIcons.book_24_regular,
                                      activeIcon: FluentIcons.book_24_filled,
                                      svgPath: 'assets/icons/quran_icon.svg',
                                      label: context.l10n.quran,
                                      onTap: (index) {
                                        setState(() => _currentIndex = index);
                                        _handleTabSideEffects(context, index);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _BottomNavItem(
                                      index: 2,
                                      currentIndex: _currentIndex,
                                      icon: FluentIcons.clock_24_regular,
                                      activeIcon: FluentIcons.clock_24_filled,
                                      label: context.l10n.prayerTimes,
                                      onTap: (index) {
                                        setState(() => _currentIndex = index);
                                        _handleTabSideEffects(context, index);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _BottomNavItem(
                                      index: 1,
                                      currentIndex: _currentIndex,
                                      icon: FluentIcons.person_24_regular,
                                      activeIcon: FluentIcons.person_24_filled,
                                      label: context.l10n.reciters,
                                      onTap: (index) {
                                        setState(() => _currentIndex = index);
                                        _handleTabSideEffects(context, index);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty_bar')),
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

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    this.svgPath,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String? svgPath;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath!,
                width: 24.sp,
                height: 24.sp,
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? theme.primaryColor
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                  BlendMode.srcIn,
                ),
              )
            else
              Icon(
                isSelected ? activeIcon : icon,
                size: 24.sp,
                color: isSelected
                    ? theme.primaryColor
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            SizedBox(height: 2.h), // Reduced to fix overflow
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSelected ? 10.5.sp : 9.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.primaryColor
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
