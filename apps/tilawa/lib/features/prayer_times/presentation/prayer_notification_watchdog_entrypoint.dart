import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/services/android_adhan_alarm_player.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/notification_dispatcher.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/core/services/prayer_adhan_notification_service.dart';
import 'package:tilawa/features/prayer_times/data/datasources/location_datasource.dart';
import 'package:tilawa/features/prayer_times/data/datasources/prayer_settings_datasource.dart';
import 'package:tilawa/features/prayer_times/data/repositories/prayer_notification_schedule_repository_impl.dart';
import 'package:tilawa/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:tilawa/features/prayer_times/data/services/prayer_notification_permission_status_impl.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/ensure_prayer_notifications_scheduled_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/schedule_prayer_notifications_use_case.dart';
import 'package:tilawa_core/services/analytics_service.dart';

const MethodChannel _watchdogBackgroundChannel = MethodChannel(
  'com.tilawa.app/prayer_watchdog_background',
);

Future<void> handlePrayerNotificationWatchdogEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  bool success = true;
  bool retryable = false;
  String message = 'ok';
  String action = 'unknown';

  try {
    logger.d('[PrayerWatchdog] Background entrypoint started');

    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final NotificationPermissionService permissionService =
        NotificationPermissionService(prefs);
    final AndroidAdhanAlarmPlayer adhanPlayer = AndroidAdhanAlarmPlayer();
    final PrayerTimesRepository repository = PrayerTimesRepositoryImpl(
      PrayerSettingsDataSourceImpl(prefs),
      const _WatchdogLocationDataSource(),
    );
    final PrayerAdhanNotificationService notificationService =
        PrayerAdhanNotificationService(
          prefs,
          NotificationDispatcher(),
          const _NoopNavigationService(),
          const _NoopAnalyticsService(),
          adhanPlayer,
          permissionService,
        );
    final EnsurePrayerNotificationsScheduledUseCase ensureScheduled =
        EnsurePrayerNotificationsScheduledUseCase(
          PrayerNotificationScheduleRepositoryImpl(prefs),
          PrayerNotificationPermissionStatusImpl(permissionService),
          repository,
          SchedulePrayerNotificationsUseCase(notificationService, repository),
          adhanPlayer,
        );

    bool forceReschedule = false;
    try {
      forceReschedule = await adhanPlayer.consumeNeedsRescheduleAfterBoot();
    } catch (e) {
      logger.w('[PrayerWatchdog] Boot/timezone force flag probe failed: $e');
    }

    final result = await ensureScheduled(forceReschedule: forceReschedule);
    await result.fold(
      (failure) async {
        success = false;
        retryable = true;
        message = failure.message ?? failure.toString();
      },
      (ensureResult) async {
        action = ensureResult.action.name;
        logger.d(
          '[PrayerWatchdog] Completed with action=$action '
          'remaining=${ensureResult.remainingWindow} '
          'until=${ensureResult.scheduledUntil}',
        );
      },
    );
  } catch (e, stackTrace) {
    success = false;
    retryable = true;
    message = e.toString();
    logger.e(
      '[PrayerWatchdog] Background entrypoint failed: $e',
      error: e,
      stackTrace: stackTrace,
    );
  } finally {
    try {
      await _watchdogBackgroundChannel.invokeMethod<void>('watchdogComplete', {
        'success': success,
        'retryable': retryable,
        'message': message,
        'action': action,
      });
    } catch (e) {
      logger.e('[PrayerWatchdog] Failed to report completion: $e');
    }
  }
}

class _WatchdogLocationDataSource implements LocationDataSource {
  const _WatchdogLocationDataSource();

  @override
  Future<LocationResult> getCurrentLocation({bool forceRefresh = false}) async {
    return LocationResult.error('Location lookup is disabled in watchdog');
  }

  @override
  Future<String?> getCountryCode(double latitude, double longitude) async {
    return null;
  }

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> isLocationServiceEnabled() async => false;

  @override
  Future<bool> requestPermission() async => false;
}

class _NoopNavigationService implements NavigationService {
  const _NoopNavigationService();

  @override
  String? getCurrentLocation() => null;

  @override
  void navigateToNotification(String location, {Object? extra}) {}

  @override
  void routeToDestination(NotificationDestination destination) {}

  @override
  Future<void> push(String location, {Object? extra}) async {}
}

class _NoopAnalyticsService implements AnalyticsService {
  const _NoopAnalyticsService();

  @override
  Future<void> logAthkarNotificationOpen(
    int categoryId,
    String categoryName,
  ) async {}

  @override
  Future<void> logAthkarReadStart(
    int categoryId,
    String categoryName, {
    required String source,
  }) async {}

  @override
  Future<void> logAudioPause(String audioId) async {}

  @override
  Future<void> logAudioPlay(
    String audioId, {
    String? audioName,
    String? artist,
    String? surahName,
    String? reciterName,
    String? moshafName,
    String? surahId,
    String? reciterId,
  }) async {}

  @override
  Future<void> logAudioSeek(String audioId, int position) async {}

  @override
  Future<void> logAudioStop(String audioId) async {}

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logFavorite(String itemId, {String? itemType}) async {}

  @override
  Future<void> logLogin({String? loginMethod}) async {}

  @override
  Future<void> logPurchase(
    String transactionId, {
    double? value,
    String? currency,
    String? itemId,
  }) async {}

  @override
  Future<void> logRating(
    int rating, {
    String? itemId,
    String? itemType,
  }) async {}

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {}

  @override
  Future<void> logSearch(String searchTerm, {int? resultCount}) async {}

  @override
  Future<void> logShare(String contentType, {String? itemId}) async {}

  @override
  Future<void> logSignUp({String? signUpMethod}) async {}

  @override
  Future<void> logSubscriptionCancel(
    String subscriptionId, {
    String? planId,
  }) async {}

  @override
  Future<void> logSubscriptionStart(
    String subscriptionId, {
    String? planId,
    double? value,
    String? currency,
  }) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}
}
