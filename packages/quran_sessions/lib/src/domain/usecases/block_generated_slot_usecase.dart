import 'package:dartz_plus/dartz_plus.dart';
import 'package:timezone/timezone.dart' as tz;

import '../entities/availability_override.dart';
import '../entities/local_time.dart';
import '../entities/time_range.dart';
import '../entities/weekday.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/schedule_repository.dart';
import '../services/day_interval_editor.dart';

/// Blocks one generated slot by saving a dated override for that calendar day.
class BlockGeneratedSlotUseCase {
  const BlockGeneratedSlotUseCase(this._scheduleRepository);

  final ScheduleRepository _scheduleRepository;

  Future<Either<QuranSessionsFailure, void>> call({
    required String teacherId,
    required DateTime slotStartUtc,
    required DateTime slotEndUtc,
  }) async {
    final scheduleResult = await _scheduleRepository.getSchedule(teacherId);
    if (scheduleResult.isLeft()) {
      return scheduleResult.map((_) => throw StateError('unreachable'));
    }
    final schedule = scheduleResult.fold((_) => null, (value) => value);
    if (schedule == null) {
      return const Left(NotFoundFailure('WeeklySchedule'));
    }

    final location = tz.getLocation(schedule.timezone);
    final localStart = tz.TZDateTime.from(slotStartUtc.toUtc(), location);
    final calendarDate = DateTime(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    final dateKey =
        '${calendarDate.year.toString().padLeft(4, '0')}-'
        '${calendarDate.month.toString().padLeft(2, '0')}-'
        '${calendarDate.day.toString().padLeft(2, '0')}';

    final overridesResult = await _scheduleRepository.getOverrides(teacherId);
    if (overridesResult.isLeft()) {
      return overridesResult.map((_) => throw StateError('unreachable'));
    }
    final overrides = overridesResult.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );
    AvailabilityOverride? existingOverride;
    for (final override in overrides) {
      if (override.dateKey == dateKey) {
        existingOverride = override;
        break;
      }
    }

    final baseIntervals = switch (existingOverride?.type) {
      OverrideType.custom => existingOverride!.intervals,
      OverrideType.unavailable => const <TimeRange>[],
      null => schedule.rangesFor(Weekday.fromDateTime(localStart)),
    };

    final durationMinutes = slotEndUtc
        .toUtc()
        .difference(slotStartUtc.toUtc())
        .inMinutes;
    final hole = localTimeRange(
      start: LocalTime(localStart.hour, localStart.minute),
      durationMinutes: durationMinutes,
    );
    final remaining = subtractInterval(baseIntervals, hole);

    final override = remaining.isEmpty
        ? AvailabilityOverride(
            date: calendarDate,
            type: OverrideType.unavailable,
            reason: 'blocked_slot',
          )
        : AvailabilityOverride(
            date: calendarDate,
            type: OverrideType.custom,
            intervals: remaining,
            reason: 'blocked_slot',
          );

    return _scheduleRepository.saveOverride(teacherId, override);
  }
}
