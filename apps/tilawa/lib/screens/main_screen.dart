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
import '../features/qibla/presentation/screens/qibla_screen.dart';
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
    const RecitersScreen(),
    const PrayerTimesScreen(),
    const AthkarCategoriesScreen(),
    const QiblaScreen(),
    const SettingsScreen(),
  ];

  void _handleTabSideEffects(BuildContext context, int index) {
    final PrayerTimesBloc prayerTimesBloc = context.read<PrayerTimesBloc>();
    prayerTimesBloc.setCountdownActive(index == 1);

    if (index == 3) {
      context.read<QiblaBloc>().add(const CheckLocationService());
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
            ..setCountdownActive(_currentIndex == 1),
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
              // floatingActionButton: kDebugMode
              //     ? FloatingActionButton(
              //         heroTag: null,
              //         onPressed: () {
              //           /// TODO: implement push notification
              //           final IAthkarNotificationService notificationService =
              //               getIt<IAthkarNotificationService>();
              //           notificationService.scheduleDebugAthkarNotification(
              //             isMorning: true,
              //           );
              //         },
              //         child: const Icon(Icons.play_arrow),
              //       )
              //     : null,
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
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20.r,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Theme(
                      data: theme.copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: BottomNavigationBar(
                        currentIndex: _currentIndex,
                        onTap: (index) {
                          if (!shouldHandleBottomNavTap(
                            currentIndex: _currentIndex,
                            tappedIndex: index,
                          )) {
                            return;
                          }

                          setState(() {
                            _currentIndex = index;
                          });
                          _handleTabSideEffects(context, index);
                        },
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        selectedItemColor: theme.primaryColor,
                        unselectedItemColor: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                        selectedLabelStyle: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        items: [
                          BottomNavigationBarItem(
                            icon: Icon(
                              FluentIcons.person_24_regular,
                              size: 24.sp,
                            ),
                            activeIcon: Icon(
                              FluentIcons.person_24_filled,
                              size: 24.sp,
                            ),
                            label: context.l10n.reciters,
                            tooltip: context.l10n.reciters,
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(
                              FluentIcons.clock_24_regular,
                              size: 24.sp,
                            ),
                            activeIcon: Icon(
                              FluentIcons.clock_24_filled,
                              size: 24.sp,
                            ),
                            label: context.l10n.prayerTimes,
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(
                              FluentIcons.book_open_24_regular,
                              size: 24.sp,
                            ),
                            activeIcon: Icon(
                              FluentIcons.book_open_24_filled,
                              size: 24.sp,
                            ),
                            label: context.l10n.athkar,
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.explore_outlined, size: 24.sp),
                            activeIcon: Icon(Icons.explore, size: 24.sp),
                            label: context.l10n.qibla,
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(
                              FluentIcons.settings_24_regular,
                              size: 24.sp,
                            ),
                            activeIcon: Icon(
                              FluentIcons.settings_24_filled,
                              size: 24.sp,
                            ),
                            label: context.l10n.settings,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
