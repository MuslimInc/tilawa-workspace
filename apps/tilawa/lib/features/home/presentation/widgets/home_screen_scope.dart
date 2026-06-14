import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/home.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_current_location_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_prayer_times_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
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

  static HomeDashboardBloc _createHomeDashboardBloc() {
    return HomeDashboardBloc(
      GetHomeDashboardUseCase(
        HomeDashboardRepositoryImpl(
          getCurrentUser: getIt<GetCurrentUserUseCase>(),
          loadPrayerSettings: getIt<LoadPrayerSettingsUseCase>(),
          getCurrentLocation: getIt<GetCurrentLocationUseCase>(),
          getPrayerTimes: getIt<GetPrayerTimesUseCase>(),
        ),
      ),
    )..add(const HomeDashboardStarted());
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => _createHomeDashboardBloc()),
        BlocProvider(create: (_) => _createTodayPlanBloc()),
      ],
      child:
          child ??
          HomeScreen(
            onOpenReciters: onOpenReciters,
            onOpenPrayer: onOpenPrayer,
            onOpenAthkar: onOpenAthkar,
            onOpenSettings: onOpenSettings,
          ),
    );
  }
}
