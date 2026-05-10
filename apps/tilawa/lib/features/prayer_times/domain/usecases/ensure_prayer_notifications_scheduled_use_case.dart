import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/core/services/prayer_notification_config.dart';
import 'package:tilawa_core/core.dart';

import '../entities/entities.dart';
import '../repositories/prayer_notification_schedule_repository.dart';
import '../repositories/prayer_times_repository.dart';
import '../services/prayer_notification_permission_status.dart';
import 'schedule_prayer_notifications_use_case.dart';

enum PrayerNotificationEnsureAction {
  rescheduled,
  skippedWindowSufficient,
  skippedNoSavedLocation,
  skippedNotificationsDisabled,
  skippedPermissionDenied,
}

class PrayerNotificationEnsureResult {
  const PrayerNotificationEnsureResult({
    required this.action,
    this.remainingWindow,
    this.scheduledUntil,
  });

  final PrayerNotificationEnsureAction action;
  final Duration? remainingWindow;
  final DateTime? scheduledUntil;

  bool get didReschedule =>
      action == PrayerNotificationEnsureAction.rescheduled;
}

/// Ensures the rolling prayer-notification schedule remains populated.
///
/// The use case is intentionally policy-only: it decides whether the schedule
/// window is low enough to refresh, then delegates the actual scheduling to the
/// existing [SchedulePrayerNotificationsUseCase].
class EnsurePrayerNotificationsScheduledUseCase {
  const EnsurePrayerNotificationsScheduledUseCase(
    this._scheduleRepository,
    this._permissionStatus,
    this._prayerTimesRepository,
    this._schedulePrayerNotifications,
  );

  final PrayerNotificationScheduleRepository _scheduleRepository;
  final PrayerNotificationPermissionStatus _permissionStatus;
  final PrayerTimesRepository _prayerTimesRepository;
  final SchedulePrayerNotificationsUseCase _schedulePrayerNotifications;

  Future<Either<Failure, PrayerNotificationEnsureResult>> call({
    bool forceReschedule = false,
    DateTime? now,
    Duration refreshThreshold = const Duration(
      days: PrayerNotificationConfig.watchdogRefreshThresholdDays,
    ),
  }) async {
    try {
      final DateTime resolvedNow = now ?? DateTime.now();

      final bool notificationsAllowed = await _permissionStatus
          .areNotificationsAllowed();
      if (!notificationsAllowed) {
        await _scheduleRepository.clearSnapshot();
        return const Right(
          PrayerNotificationEnsureResult(
            action: PrayerNotificationEnsureAction.skippedPermissionDenied,
          ),
        );
      }

      final PrayerSettingsEntity settings = await _prayerTimesRepository
          .loadSettings();
      final double? latitude = settings.savedLatitude;
      final double? longitude = settings.savedLongitude;
      if (latitude == null || longitude == null) {
        return const Right(
          PrayerNotificationEnsureResult(
            action: PrayerNotificationEnsureAction.skippedNoSavedLocation,
          ),
        );
      }

      if (!_hasAnyEnabledPrayerNotification(settings)) {
        await _scheduleRepository.clearSnapshot();
        return const Right(
          PrayerNotificationEnsureResult(
            action: PrayerNotificationEnsureAction.skippedNotificationsDisabled,
          ),
        );
      }

      if (!forceReschedule) {
        final PrayerNotificationScheduleSnapshot? snapshot =
            await _scheduleRepository.loadSnapshot();
        if (snapshot != null) {
          final Duration remaining = snapshot.remainingWindow(resolvedNow);
          if (!remaining.isNegative && remaining >= refreshThreshold) {
            return Right(
              PrayerNotificationEnsureResult(
                action: PrayerNotificationEnsureAction.skippedWindowSufficient,
                remainingWindow: remaining,
                scheduledUntil: snapshot.scheduledUntil,
              ),
            );
          }
        }
      }

      final Either<Failure, void> scheduleResult =
          await _schedulePrayerNotifications(
            settings: settings,
            latitude: latitude,
            longitude: longitude,
            forceReschedule: true,
          );

      return scheduleResult.fold(
        (failure) => Left(failure),
        (_) => const Right(
          PrayerNotificationEnsureResult(
            action: PrayerNotificationEnsureAction.rescheduled,
          ),
        ),
      );
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }

  bool _hasAnyEnabledPrayerNotification(PrayerSettingsEntity settings) {
    return settings.fajrNotification.enabled ||
        settings.sunriseNotification.enabled ||
        settings.dhuhrNotification.enabled ||
        settings.asrNotification.enabled ||
        settings.maghribNotification.enabled ||
        settings.ishaNotification.enabled;
  }
}
