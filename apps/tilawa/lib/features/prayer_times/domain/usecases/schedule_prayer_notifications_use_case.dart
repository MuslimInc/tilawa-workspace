import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../../../../core/services/prayer_notification_config.dart';
import '../entities/entities.dart';
import '../repositories/prayer_times_repository.dart';
import '../services/prayer_adhan_notification_service_interface.dart';

/// Schedules prayer notifications across the configured day window using the
/// repository's [PrayerTimesRepository.getPrayerTimesForRange] for the next
/// [PrayerNotificationConfig.scheduleDaysAhead] days.
///
/// Pass `forceReschedule: true` from user-driven triggers (settings change,
/// location change) so the service bypasses its same-day fingerprint dedup
/// guard. Cold-start / boot triggers should pass `false` to honour dedup.
@injectable
class SchedulePrayerNotificationsUseCase {
  const SchedulePrayerNotificationsUseCase(this._service, this._repository);

  final IPrayerAdhanNotificationService _service;
  final PrayerTimesRepository _repository;

  Future<Either<Failure, void>> call({
    required PrayerSettingsEntity settings,
    required double latitude,
    required double longitude,
    bool forceReschedule = false,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startDate = DateTime(now.year, now.month, now.day);
      final DateTime endDate = startDate.add(
        Duration(days: PrayerNotificationConfig.scheduleDaysAhead - 1),
      );

      final List<PrayerTimeEntity> days = await _repository
          .getPrayerTimesForRange(
            latitude: latitude,
            longitude: longitude,
            startDate: startDate,
            endDate: endDate,
            settings: settings,
          );

      if (days.isEmpty) {
        return Left(
          Failure.unexpectedError('No prayer times available for scheduling'),
        );
      }

      await _service.schedulePrayerNotifications(
        settings: settings,
        prayerTimesForDays: days,
        forceReschedule: forceReschedule,
      );

      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
