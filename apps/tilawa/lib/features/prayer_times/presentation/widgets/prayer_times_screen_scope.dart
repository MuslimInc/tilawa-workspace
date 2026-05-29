import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/fire_prayer_test_notification_use_case.dart';

import '../../domain/services/adhan_alarm_player_interface.dart';
import '../bloc/prayer_permissions_cubit.dart';
import '../bloc/prayer_times_bloc.dart';
import '../screens/prayer_times_screen.dart';

/// Composition root for [PrayerTimesScreen] (main tab and `/prayer-times` route).
class PrayerTimesScreenScope extends StatelessWidget {
  const PrayerTimesScreenScope({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<PrayerTimesBloc>()
                ..add(const PrayerTimesEvent.loadPrayerTimes()),
        ),
        BlocProvider(
          create: (context) =>
              getIt<PrayerPermissionsCubit>()..checkCapability(),
        ),
      ],
      child: PrayerTimesScreen(
        adhanPlayer: getIt<IAdhanAlarmPlayer>(),
        fireTestNotification: getIt<FirePrayerTestNotificationUseCase>(),
      ),
    );
  }
}
