import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/android_adhan_alarm_player.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/services/prayer_adhan_notification_service.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/data/datasources/datasources.dart';
import 'package:tilawa/features/prayer_times/data/repositories/prayer_alerts_permission_onboarding_repository_impl.dart';
import 'package:tilawa/features/prayer_times/data/repositories/prayer_notification_schedule_repository_impl.dart';
import 'package:tilawa/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:tilawa/features/prayer_times/data/services/geolocator_client.dart';
import 'package:tilawa/features/prayer_times/data/services/method_channel_prayer_notification_watchdog_scheduler.dart';
import 'package:tilawa/features/prayer_times/data/services/prayer_notification_permission_status_impl.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_alerts_permission_onboarding_repository.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_notification_schedule_repository.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_notification_permission_status.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_notification_watchdog_scheduler.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/usecases.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

/// Manual GetIt registrations for `prayer_times`.
class PrayerTimesDi {
  PrayerTimesDi._();

  static void register(GetIt getIt) {
    getIt.registerFactoryIfAbsent<ShouldRefreshPrayerTimesUseCase>(
      () => const ShouldRefreshPrayerTimesUseCase(),
    );
    getIt.registerLazySingletonIfAbsent<PrayerLocationUpdateNotifier>(
      PrayerLocationUpdateNotifier.new,
    );
    getIt.registerLazySingletonIfAbsent<PrayerSettingsDataSource>(
      () => PrayerSettingsDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GeolocatorClient>(
      GeolocatorClientImpl.new,
    );
    getIt.registerLazySingletonIfAbsent<NotifyPrayerLocationUpdatedUseCase>(
      () => NotifyPrayerLocationUpdatedUseCase(
        getIt<PrayerLocationUpdateNotifier>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<
      PrayerAlertsPermissionOnboardingRepository
    >(
      () => PrayerAlertsPermissionOnboardingRepositoryImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<PrayerNotificationWatchdogScheduler>(
      () => const MethodChannelPrayerNotificationWatchdogScheduler(),
    );
    getIt.registerLazySingletonIfAbsent<PrayerNotificationScheduleRepository>(
      () => PrayerNotificationScheduleRepositoryImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<LocationDataSource>(
      () => LocationDataSourceImpl(getIt<GeolocatorClient>()),
    );
    getIt.registerLazySingletonIfAbsent<PrayerNotificationPermissionStatus>(
      () => PrayerNotificationPermissionStatusImpl(
        getIt<NotificationPermissionService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<RequestNotificationPermissionUseCase>(
      () => RequestNotificationPermissionUseCase(
        getIt<NotificationPermissionService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<PrayerTimesRepository>(
      () => PrayerTimesRepositoryImpl(
        getIt<PrayerSettingsDataSource>(),
        getIt<LocationDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<IPrayerAdhanNotificationService>(
      () => PrayerAdhanNotificationService(
        getIt<SharedPreferencesAsync>(),
        getIt<INotificationDispatcher>(),
        getIt<NavigationService>(),
        getIt<AnalyticsService>(),
        getIt<IAdhanAlarmPlayer>(),
        getIt<NotificationPermissionService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<CheckLocationPermissionUseCase>(
      () => CheckLocationPermissionUseCase(
        getIt<PrayerTimesRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<GetCountryCodeUseCase>(
      () => GetCountryCodeUseCase(getIt<PrayerTimesRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetCurrentLocationUseCase>(
      () => GetCurrentLocationUseCase(getIt<PrayerTimesRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetLocationNameUseCase>(
      () => GetLocationNameUseCase(getIt<PrayerTimesRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetMonthlyPrayerTimesUseCase>(
      () => GetMonthlyPrayerTimesUseCase(getIt<PrayerTimesRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetPrayerTimesUseCase>(
      () => GetPrayerTimesUseCase(getIt<PrayerTimesRepository>()),
    );
    getIt.registerFactoryIfAbsent<LoadPrayerSettingsUseCase>(
      () => LoadPrayerSettingsUseCase(getIt<PrayerTimesRepository>()),
    );
    getIt.registerFactoryIfAbsent<RequestLocationPermissionUseCase>(
      () => RequestLocationPermissionUseCase(
        getIt<PrayerTimesRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SavePrayerSettingsUseCase>(
      () => SavePrayerSettingsUseCase(getIt<PrayerTimesRepository>()),
    );
    getIt.registerFactoryIfAbsent<CheckPrayerAlarmCapabilityUseCase>(
      () => CheckPrayerAlarmCapabilityUseCase(
        getIt<IPrayerAdhanNotificationService>(),
        getIt<NotificationPermissionService>(),
        getIt<IAdhanAlarmPlayer>(),
      ),
    );
    getIt.registerFactoryIfAbsent<FirePrayerTestNotificationUseCase>(
      () => FirePrayerTestNotificationUseCase(
        getIt<IPrayerAdhanNotificationService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SchedulePrayerNotificationsUseCase>(
      () => SchedulePrayerNotificationsUseCase(
        getIt<IPrayerAdhanNotificationService>(),
        getIt<PrayerTimesRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<CancelPrayerNotificationsUseCase>(
      () => CancelPrayerNotificationsUseCase(
        getIt<IPrayerAdhanNotificationService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<RequestExactAlarmPermissionUseCase>(
      () => RequestExactAlarmPermissionUseCase(
        getIt<IPrayerAdhanNotificationService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<PrayerPermissionsCubit>(
      () => PrayerPermissionsCubit(
        getIt<CheckPrayerAlarmCapabilityUseCase>(),
        getIt<CheckLocationPermissionUseCase>(),
        getIt<RequestExactAlarmPermissionUseCase>(),
        getIt<RequestNotificationPermissionUseCase>(),
        getIt<RequestLocationPermissionUseCase>(),
        getIt<AndroidAdhanAlarmPlayer>(),
      ),
    );
    getIt.registerFactoryIfAbsent<EnsurePrayerNotificationsScheduledUseCase>(
      () => EnsurePrayerNotificationsScheduledUseCase(
        getIt<PrayerNotificationScheduleRepository>(),
        getIt<PrayerNotificationPermissionStatus>(),
        getIt<PrayerTimesRepository>(),
        getIt<SchedulePrayerNotificationsUseCase>(),
        getIt<IAdhanAlarmPlayer>(),
      ),
    );
    getIt.registerFactoryIfAbsent<PrayerTimesBloc>(
      () => PrayerTimesBloc(
        getIt<GetPrayerTimesUseCase>(),
        getIt<GetMonthlyPrayerTimesUseCase>(),
        getIt<GetCurrentLocationUseCase>(),
        getIt<GetCountryCodeUseCase>(),
        getIt<GetLocationNameUseCase>(),
        getIt<SavePrayerSettingsUseCase>(),
        getIt<LoadPrayerSettingsUseCase>(),
        getIt<SchedulePrayerNotificationsUseCase>(),
        getIt<CancelPrayerNotificationsUseCase>(),
        getIt<NotifyPrayerLocationUpdatedUseCase>(),
        getIt<ShouldRefreshPrayerTimesUseCase>(),
      ),
    );
  }
}
