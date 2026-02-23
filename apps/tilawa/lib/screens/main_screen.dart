import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
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
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  _handleTabSideEffects(context, 0);
                },
                backgroundColor: const Color(
                  0xFF26C6DA,
                ), // Teal/Cyan color from screenshot
                elevation: 4,
                shape: const CircleBorder(),
                child: Icon(
                  FluentIcons.book_open_24_filled,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8.0,
                color: Theme.of(context).cardColor,
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
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
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
