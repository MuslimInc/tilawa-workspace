import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/home.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_current_location_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_location_name_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_prayer_times_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/save_prayer_settings_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Composition root for the Home dashboard tab.
class HomeScreenScope extends StatelessWidget {
  const HomeScreenScope({
    super.key,
    required this.onOpenReciters,
    required this.onOpenPrayer,
    required this.onOpenAthkar,
    required this.onOpenSettings,
    this.child,
  });

  final VoidCallback onOpenReciters;
  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenAthkar;
  final VoidCallback onOpenSettings;

  /// When set (e.g. in widget tests), replaces [HomeScreen].
  final Widget? child;

  static HomeDashboardBloc _createHomeDashboardBloc(String localeIdentifier) {
    return HomeDashboardBloc(
      GetHomeDashboardUseCase(
        HomeDashboardRepositoryImpl(
          getCurrentUser: getIt<GetCurrentUserUseCase>(),
          loadPrayerSettings: getIt<LoadPrayerSettingsUseCase>(),
          getCurrentLocation: getIt<GetCurrentLocationUseCase>(),
          getLocationName: getIt<GetLocationNameUseCase>(),
          getPrayerTimes: getIt<GetPrayerTimesUseCase>(),
          savePrayerSettings: getIt<SavePrayerSettingsUseCase>(),
        ),
      ),
      getIt<NotifyPrayerLocationUpdatedUseCase>(),
    )..add(HomeDashboardStarted(localeIdentifier: localeIdentifier));
  }

  static TodayPlanBloc _createTodayPlanBloc() {
    final localDataSource = SharedPreferencesTodayPlanLocalDataSource(
      getIt<SharedPreferencesAsync>(),
    );
    final repository = TodayPlanRepositoryImpl(localDataSource);
    return TodayPlanBloc(
      GenerateTodayPlanUseCase(
        getIt<QuranReaderRepository>(),
        getIt<HistoryRepository>(),
        repository,
      ),
      SetTodayPlanTaskCompletedUseCase(repository),
      getIt<AnalyticsService>(),
    )..add(const TodayPlanStarted());
  }

  @override
  Widget build(BuildContext context) {
    final localeIdentifier = Localizations.localeOf(context).languageCode;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => _createHomeDashboardBloc(localeIdentifier),
        ),
        BlocProvider(create: (_) => _createTodayPlanBloc()),
      ],
      child: _HomeLocationSyncListener(
        child: BlocListener<LocalizationBloc, LocalizationState>(
          listener: (context, state) {
            context.read<HomeDashboardBloc>().add(
              HomeDashboardLocaleChanged(
                localeIdentifier: state.locale.languageCode,
              ),
            );
          },
          child:
              child ??
              HomeScreen(
                onOpenReciters: onOpenReciters,
                onOpenPrayer: onOpenPrayer,
                onOpenAthkar: onOpenAthkar,
                onOpenSettings: onOpenSettings,
              ),
        ),
      ),
    );
  }
}

/// Reloads the home dashboard when another tab updates the saved location.
class _HomeLocationSyncListener extends StatefulWidget {
  const _HomeLocationSyncListener({required this.child});

  final Widget child;

  @override
  State<_HomeLocationSyncListener> createState() =>
      _HomeLocationSyncListenerState();
}

class _HomeLocationSyncListenerState extends State<_HomeLocationSyncListener> {
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
    if (update.source == PrayerLocationUpdateSource.homeDashboard) {
      return;
    }
    context.read<HomeDashboardBloc>().add(
      HomeDashboardRefreshRequested(
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
