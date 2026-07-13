import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
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
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Composition root for the Home dashboard tab.
class HomeScreenScope extends StatelessWidget {
  const HomeScreenScope({
    super.key,
    required this.onOpenPrayer,
    this.child,
  });

  final VoidCallback onOpenPrayer;

  /// When set (e.g. in widget tests), replaces [HomeScreen].
  final Widget? child;

  static HomeDashboardBloc _createHomeDashboardBloc() {
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
    );
  }

  static void _deferToNextFrame(VoidCallback action) {
    SchedulerBinding.instance.addPostFrameCallback((_) => action());
  }

  static TodayPlanBloc _createTodayPlanBloc() {
    final localDataSource = SharedPreferencesTodayPlanLocalDataSource(
      getIt<SharedPreferencesAsync>(),
    );
    final repository = TodayPlanRepositoryImpl(localDataSource);
    final GetKhatmaTodayTargetUseCase? getKhatmaTodayTarget =
        isSmartKhatmaEnabled()
        ? SmartKhatmaDependencies.getTodayTarget(
            SmartKhatmaDependencies.repository(),
          )
        : null;
    return TodayPlanBloc(
      GenerateTodayPlanUseCase(
        getIt<QuranReaderRepository>(),
        getIt<HistoryRepository>(),
        repository,
        getIt<HiveReadiness>(),
        getKhatmaTodayTarget,
      ),
      SetTodayPlanTaskCompletedUseCase(repository),
      getIt<AnalyticsService>(),
    )..add(const TodayPlanStarted());
  }

  @override
  Widget build(BuildContext context) {
    final Widget homeContent = _HomeLocalizationListener(
      child: child ?? HomeScreen(onOpenPrayer: onOpenPrayer),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => _createHomeDashboardBloc(),
        ),
        BlocProvider(
          create: (_) {
            final HomeListeningResumeCubit cubit =
                getIt<HomeListeningResumeCubit>();
            _deferToNextFrame(cubit.load);
            return cubit;
          },
        ),
        if (isSmartKhatmaEnabled())
          BlocProvider(create: (_) => SmartKhatmaDependencies.bloc()),
        if (isTodayPlanEnabled())
          BlocProvider(create: (_) => _createTodayPlanBloc()),
      ],
      child: _HomeLocationSyncListener(
        child: _HomeAuthSyncListener(
          child: isSmartKhatmaEnabled() && isTodayPlanEnabled()
              ? _HomeKhatmaPlanSyncListener(child: homeContent)
              : homeContent,
        ),
      ),
    );
  }
}

class _HomeLocalizationListener extends StatelessWidget {
  const _HomeLocalizationListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocalizationBloc, LocalizationState>(
      listener: (context, state) {
        context.read<HomeDashboardBloc>().add(
          HomeDashboardLocaleChanged(
            localeIdentifier: state.locale.languageCode,
          ),
        );
      },
      child: child,
    );
  }
}

class _HomeKhatmaPlanSyncListener extends StatelessWidget {
  const _HomeKhatmaPlanSyncListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<KhatmaPlanBloc, KhatmaPlanState>(
      listenWhen: (previous, current) {
        if (current is! KhatmaPlanLoaded) {
          return false;
        }
        if (previous is! KhatmaPlanLoaded) {
          return true;
        }
        return previous.plan?.id != current.plan?.id ||
            previous.todayTarget?.pages != current.todayTarget?.pages ||
            previous.plan?.confirmedCompletedThroughPage !=
                current.plan?.confirmedCompletedThroughPage;
      },
      listener: (context, state) {
        context.read<TodayPlanBloc>().add(const TodayPlanSourceChanged());
      },
      child: child,
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

/// Reloads the home dashboard when the signed-in profile changes.
class _HomeAuthSyncListener extends StatelessWidget {
  const _HomeAuthSyncListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          _profileSnapshot(previous) != _profileSnapshot(current),
      listener: (context, state) {
        context.read<HomeDashboardBloc>().add(
          HomeDashboardRefreshRequested(
            localeIdentifier: Localizations.localeOf(context).languageCode,
          ),
        );
      },
      child: child,
    );
  }

  static String? _profileSnapshot(AuthState state) {
    final UserEntity? user = state.mapOrNull(
      authenticated: (value) => value.user,
    );
    if (user == null) {
      return null;
    }
    return '${user.id}|${user.displayName}|${user.photoUrl ?? ''}';
  }
}
