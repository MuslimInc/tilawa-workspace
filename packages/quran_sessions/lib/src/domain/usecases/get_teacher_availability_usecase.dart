import 'package:dartz_plus/dartz_plus.dart';

import '../entities/generated_slot.dart';
import '../entities/teacher_availability.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/session_repository.dart';
import '../services/booked_slot_starts.dart';
import '../services/slot_generator.dart';
import '../services/teacher_availability_sort.dart';

/// Returns bookable slots for a teacher by generating them from the weekly
/// schedule, overrides, and existing sessions — not from legacy stored slots.
class GetTeacherAvailabilityUseCase {
  GetTeacherAvailabilityUseCase({
    required this._scheduleRepository,
    required this._sessionRepository,
    this._slotGenerator = const SlotGenerator(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ScheduleRepository _scheduleRepository;
  final SessionRepository _sessionRepository;
  final SlotGenerator _slotGenerator;
  final DateTime Function() _now;

  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final scheduleResult = await _scheduleRepository.getSchedule(teacherId);
    if (scheduleResult.isLeft()) {
      return scheduleResult.map((_) => throw StateError('unreachable'));
    }
    final schedule = scheduleResult.fold((_) => null, (value) => value);
    if (schedule == null || schedule.isEmpty) {
      return const Right([]);
    }

    // Repository `to` is exclusive on calendar date keys. Extend by one local
    // day so overrides on the last day touched by [to] are still fetched.
    final overrideQueryTo = DateTime(to.year, to.month, to.day).add(
      const Duration(days: 1),
    );
    final overridesResult = await _scheduleRepository.getOverrides(
      teacherId,
      from: from,
      to: overrideQueryTo,
    );
    if (overridesResult.isLeft()) {
      return overridesResult.map((_) => throw StateError('unreachable'));
    }
    final overrides = overridesResult.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );

    final sessionsResult = await _sessionRepository.getTeacherSessions(
      teacherId,
    );
    if (sessionsResult.isLeft()) {
      return sessionsResult.map((_) => throw StateError('unreachable'));
    }
    final sessions = sessionsResult.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );

    final generated = _slotGenerator.generate(
      schedule: schedule,
      overrides: overrides,
      bookedStartsUtc: collectBookedSlotStarts(
        sessions,
        windowStart: from,
        windowEnd: to,
      ),
      windowStart: from,
      windowEnd: to,
      now: _now(),
    );

    return Right(
      sortTeacherAvailabilityByStart(
        generated.map(_toTeacherAvailability).toList(),
      ),
    );
  }

  TeacherAvailability _toTeacherAvailability(GeneratedSlot slot) =>
      TeacherAvailability(
        slotId: slot.slotId,
        teacherId: slot.teacherId,
        startsAt: slot.startUtc,
        endsAt: slot.endUtc,
        isBooked: false,
      );
}
