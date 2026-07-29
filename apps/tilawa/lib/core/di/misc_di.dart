import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/app_info_service_impl.dart';
import 'package:tilawa/core/services/athkar_notification_service.dart';
import 'package:tilawa/core/services/firebase_analytics_service.dart';
import 'package:tilawa/core/services/firebase_performance_service.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_dispatcher.dart';
import 'package:tilawa/core/services/sentry_application_metrics_service.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/application_metrics_service.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';
import 'package:tilawa_core/services/interfaces/athkar_notification_service_interface.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';

/// Manual GetIt registrations for `misc`.
class MiscDi {
  MiscDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<AppInfoService>(
      AppInfoServiceImpl.new,
    );
    getIt.registerLazySingletonIfAbsent<ApplicationMetricsService>(
      SentryApplicationMetricsService.new,
    );
    getIt.registerLazySingletonIfAbsent<PerformanceMonitoringService>(
      () => FirebasePerformanceService(getIt<FirebasePerformance>()),
    );
    getIt.registerLazySingletonIfAbsent<INotificationDispatcher>(
      NotificationDispatcher.new,
    );
    getIt.registerLazySingletonIfAbsent<AnalyticsService>(
      () => FirebaseAnalyticsService(getIt<FirebaseAnalytics>()),
    );
    getIt.registerLazySingletonIfAbsent<IAthkarNotificationService>(
      () => AthkarNotificationService(
        getIt<SharedPreferencesAsync>(),
        getIt<INotificationDispatcher>(),
        getIt<AnalyticsService>(),
        getIt<NavigationService>(),
        getIt<PrayerTimesRepository>(),
      ),
    );
  }
}
