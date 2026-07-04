import 'package:dartz_plus/dartz_plus.dart';

import '../entities/availability_override.dart';
import '../entities/generated_slot.dart';
import '../entities/teacher_availability.dart';
import '../entities/weekly_schedule.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/booked_slot_lock_repository.dart';
import '../repositories/schedule_repository.dart';
import '../services/slot_generator.dart';
import '../services/teacher_availability_sort.dart';

/// Returns bookable slots for a teacher by generating them from the weekly
/// schedule, overrides, and existing sessions — not from legacy stored slots.
class GetTeacherAvailabilityUseCase {
  GetTeacherAvailabilityUseCase({
    required this._scheduleRepository,
    required this._bookedSlotLocks,
    this._slotGenerator = const SlotGenerator(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ScheduleRepository _scheduleRepository;
  final BookedSlotLockRepository _bookedSlotLocks;
  final SlotGenerator _slotGenerator;
  final DateTime Function() _now;

  /// [preloadedSchedule] skips the schedule fetch when the caller already
  /// holds the teacher's weekly schedule (e.g. the dashboard use case).
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
    WeeklySchedule? preloadedSchedule,
  }) async {
    WeeklySchedule? schedule = preloadedSchedule;
    if (schedule == null) {
      final scheduleResult = await _scheduleRepository.getSchedule(teacherId);
      if (scheduleResult.isLeft()) {
        return scheduleResult.map((_) => throw StateError('unreachable'));
      }
      schedule = scheduleResult.fold((_) => null, (value) => value);
    }
    if (schedule == null || schedule.isEmpty) {
      return const Right([]);
    }

    // Repository `to` is exclusive on calendar date keys. Extend by one local
    // day so overrides on the last day touched by [to] are still fetched.
    final overrideQueryTo = DateTime(to.year, to.month, to.day).add(
      const Duration(days: 1),
    );
    // Overrides and booked starts are independent — fetch them concurrently.
    final overridesFuture = _scheduleRepository.getOverrides(
      teacherId,
      from: from,
      to: overrideQueryTo,
    );
    final bookedStartsFuture = _bookedSlotLocks.getActiveBookedStarts(
      teacherId,
      windowStart: from,
      windowEnd: to,
      now: _now(),
    );
    final overridesResult = await overridesFuture;
    if (overridesResult.isLeft()) {
      return overridesResult.map((_) => throw StateError('unreachable'));
    }
    final overrides = overridesResult.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );

    final bookedStartsResult = await bookedStartsFuture;
    if (bookedStartsResult.isLeft()) {
      return bookedStartsResult.map((_) => throw StateError('unreachable'));
    }
    final bookedStartsUtc = bookedStartsResult.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );

    return Right(
      generateTeacherAvailability(
        schedule: schedule,
        overrides: overrides,
        bookedStartsUtc: bookedStartsUtc,
        windowStart: from,
        windowEnd: to,
        now: _now(),
        slotGenerator: _slotGenerator,
      ),
    );
  }

  /// Pure slot generation shared with the dashboard summary path, so both
  /// produce identical availability from the same sources.
  static List<TeacherAvailability> generateTeacherAvailability({
    required WeeklySchedule schedule,
    required List<AvailabilityOverride> overrides,
    required Set<DateTime> bookedStartsUtc,
    required DateTime windowStart,
    required DateTime windowEnd,
    required DateTime now,
    SlotGenerator slotGenerator = const SlotGenerator(),
  }) {
    final generated = slotGenerator.generate(
      schedule: schedule,
      overrides: overrides,
      bookedStartsUtc: bookedStartsUtc,
      windowStart: windowStart,
      windowEnd: windowEnd,
      now: now,
    );
    return sortTeacherAvailabilityByStart(
      generated.map(_toTeacherAvailability).toList(),
    );
  }

  static TeacherAvailability _toTeacherAvailability(GeneratedSlot slot) =>
      TeacherAvailability(
        slotId: slot.slotId,
        teacherId: slot.teacherId,
        startsAt: slot.startUtc,
        endsAt: slot.endUtc,
        isBooked: false,
      );
}
