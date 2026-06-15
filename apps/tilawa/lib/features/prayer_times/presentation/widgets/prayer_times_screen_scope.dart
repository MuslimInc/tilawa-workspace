import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/fire_prayer_test_notification_use_case.dart';

import '../../domain/services/adhan_alarm_player_interface.dart';
import '../bloc/prayer_permissions_cubit.dart';
import '../bloc/prayer_times_bloc.dart';
import '../screens/prayer_times_screen.dart';

/// Composition root for [PrayerTimesScreen] (main tab and `/prayer-times` route).
class PrayerTimesScreenScope extends StatelessWidget {
  const PrayerTimesScreenScope({super.key, this.child});

  /// When set (e.g. in widget tests), replaces [PrayerTimesScreen].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final localeIdentifier = Localizations.localeOf(context).languageCode;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<PrayerTimesBloc>()
            ..add(
              PrayerTimesEvent.loadPrayerTimes(
                requestLocationPermission: true,
                localeIdentifier: localeIdentifier,
              ),
            ),
        ),
        BlocProvider(
          create: (context) => getIt<PrayerPermissionsCubit>(),
        ),
      ],
      child: _PrayerLocationSyncListener(
        child: BlocListener<LocalizationBloc, LocalizationState>(
          listener: (context, state) {
            context.read<PrayerTimesBloc>().add(
              PrayerTimesEvent.loadPrayerTimes(
                localeIdentifier: state.locale.languageCode,
              ),
            );
          },
          child:
              child ??
              PrayerTimesScreen(
                adhanPlayer: getIt<IAdhanAlarmPlayer>(),
                fireTestNotification:
                    getIt<FirePrayerTestNotificationUseCase>(),
              ),
        ),
      ),
    );
  }
}

/// Reloads prayer times when another tab updates the saved scheduling location.
class _PrayerLocationSyncListener extends StatefulWidget {
  const _PrayerLocationSyncListener({required this.child});

  final Widget child;

  @override
  State<_PrayerLocationSyncListener> createState() =>
      _PrayerLocationSyncListenerState();
}

class _PrayerLocationSyncListenerState
    extends State<_PrayerLocationSyncListener> {
  StreamSubscription<PrayerLocationUpdate>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = getIt<PrayerLocationUpdateNotifier>().stream.listen(
      _onLocationUpdated,
    );
  }

  void _onLocationUpdated(PrayerLocationUpdate update) {
    if (!mounted) {
      return;
    }
    if (update.source == PrayerLocationUpdateSource.prayerTimesTab) {
      return;
    }
    context.read<PrayerTimesBloc>().add(
      PrayerTimesEvent.loadPrayerTimes(
        forceReschedule: true,
        localeIdentifier: update.localeIdentifier,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
