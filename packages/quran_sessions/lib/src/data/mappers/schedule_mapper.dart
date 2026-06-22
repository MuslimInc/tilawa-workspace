import '../../domain/entities/availability_override.dart';
import '../../domain/entities/local_time.dart';
import '../../domain/entities/scheduling_policy.dart';
import '../../domain/entities/slot_duration.dart';
import '../../domain/entities/time_range.dart';
import '../../domain/entities/weekday.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../dtos/availability_override_dto.dart';
import '../dtos/weekly_schedule_dto.dart';

List<TimeRange> _rangesFromJson(List<Map<String, String>> raw) => raw
    .map(
      (m) => TimeRange(
        start: LocalTime.parse(m['start']!),
        end: LocalTime.parse(m['end']!),
      ),
    )
    .toList();

List<Map<String, String>> _rangesToJson(List<TimeRange> ranges) => ranges
    .map((r) => {'start': r.start.toHmm(), 'end': r.end.toHmm()})
    .toList();

extension WeeklyScheduleDtoMapper on WeeklyScheduleDto {
  WeeklySchedule toDomain() {
    final rules = <Weekday, List<TimeRange>>{};
    for (final entry in weeklyRules.entries) {
      // Unknown keys are ignored rather than throwing on a single bad day.
      final weekday = Weekday.values
          .where((w) => w.key == entry.key)
          .firstOrNull;
      if (weekday != null) {
        rules[weekday] = _rangesFromJson(entry.value);
      }
    }
    return WeeklySchedule(
      teacherId: teacherId,
      timezone: timezone,
      slotDuration: SlotDuration(slotDurationMinutes),
      rules: rules,
      policy: SchedulingPolicy(
        minNoticeMinutes: minNoticeMinutes,
        maxHorizonDays: maxHorizonDays,
        bufferBeforeMinutes: bufferBeforeMinutes,
        bufferAfterMinutes: bufferAfterMinutes,
      ),
      version: version,
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt!),
    ).detached();
  }
}

extension WeeklyScheduleDomainMapper on WeeklySchedule {
  WeeklyScheduleDto toDto() => WeeklyScheduleDto(
    teacherId: teacherId,
    timezone: timezone,
    slotDurationMinutes: slotDuration.minutes,
    minNoticeMinutes: policy.minNoticeMinutes,
    maxHorizonDays: policy.maxHorizonDays,
    bufferBeforeMinutes: policy.bufferBeforeMinutes,
    bufferAfterMinutes: policy.bufferAfterMinutes,
    weeklyRules: {
      for (final day in Weekday.values) day.key: _rangesToJson(rangesFor(day)),
    },
    version: version,
    updatedAt: updatedAt?.toUtc().toIso8601String(),
  );
}

extension AvailabilityOverrideDtoMapper on AvailabilityOverrideDto {
  AvailabilityOverride toDomain() => AvailabilityOverride(
    date: DateTime.parse(date),
    type: type == OverrideType.unavailable.name
        ? OverrideType.unavailable
        : OverrideType.custom,
    intervals: _rangesFromJson(intervals),
    reason: reason,
  );
}

extension AvailabilityOverrideDomainMapper on AvailabilityOverride {
  AvailabilityOverrideDto toDto() => AvailabilityOverrideDto(
    date: dateKey,
    type: type.name,
    intervals: _rangesToJson(intervals),
    reason: reason,
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
