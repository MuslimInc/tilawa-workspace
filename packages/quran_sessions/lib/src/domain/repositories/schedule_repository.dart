import 'package:dartz_plus/dartz_plus.dart';

import '../entities/availability_override.dart';
import '../entities/weekly_schedule.dart';
import '../failures/quran_sessions_failure.dart';

/// Reads and writes a teacher's recurring availability rules and dated
/// overrides. Bookable slots are derived from these by [SlotGenerator] — the
/// repository never stores generated slots.
abstract interface class ScheduleRepository {
  /// The teacher's weekly schedule, or `null` if they have not configured one.
  Future<Either<QuranSessionsFailure, WeeklySchedule?>> getSchedule(
    String teacherId,
  );

  /// Persists the whole weekly schedule atomically.
  Future<Either<QuranSessionsFailure, void>> saveSchedule(
    WeeklySchedule schedule,
  );

  /// Dated overrides for [teacherId], optionally limited to `[from, to)`.
  Future<Either<QuranSessionsFailure, List<AvailabilityOverride>>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  });

  /// Creates or replaces a single dated override.
  Future<Either<QuranSessionsFailure, void>> saveOverride(
    String teacherId,
    AvailabilityOverride override,
  );

  /// Removes the override on [dateKey] (`yyyy-MM-dd`).
  Future<Either<QuranSessionsFailure, void>> removeOverride(
    String teacherId,
    String dateKey,
  );
}
