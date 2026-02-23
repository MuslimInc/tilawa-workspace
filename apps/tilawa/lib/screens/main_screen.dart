import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
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
              body: Column(
                children: [
                  const OfflineIndicatorWidget(),
                  // Main content
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: _screens,
                    ),
                  ),

                  const BottomPlayerWidget(),
                ],
              ),
              floatingActionButton: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                    _handleTabSideEffects(context, 0);
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  shape: const CircleBorder(),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.8),
                          theme.primaryColor,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset(
                        'assets/icons/quran_icon.svg',
                        width: 28.sp,
                        height: 28.sp,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8.0,
                color: theme.cardColor,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BottomNavItem(
                        index: 4,
                        currentIndex: _currentIndex,
                        icon: FluentIcons.settings_24_regular,
                        activeIcon: FluentIcons.settings_24_filled,
                        label: context.l10n.settings,
                        onTap: (index) {
                          setState(() => _currentIndex = index);
                          _handleTabSideEffects(context, index);
                        },
                      ),
                      _BottomNavItem(
                        index: 3,
                        currentIndex: _currentIndex,
                        icon: FluentIcons.book_open_24_regular,
                        activeIcon: FluentIcons.book_open_24_filled,
                        svgPath: 'assets/icons/athkar_icon.svg',
                        label: context.l10n.athkar,
                        onTap: (index) {
                          setState(() => _currentIndex = index);
                          _handleTabSideEffects(context, index);
                        },
                      ),
                      const SizedBox(width: 40), // Space for FAB
                      _BottomNavItem(
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
                      _BottomNavItem(
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
                    ],
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
