import '../dtos/availability_override_dto.dart';
import '../dtos/weekly_schedule_dto.dart';

/// Remote datasource contract for recurring availability. The host app provides
/// the concrete (Firestore) implementation — this package never imports
/// Firebase.
///
/// Implementations throw the typed exceptions in `remote_exception.dart`; the
/// repository maps those to [QuranSessionsFailure].
abstract interface class ScheduleRemoteDataSource {
  /// Returns the teacher's weekly schedule, or `null` if none is configured.
  Future<WeeklyScheduleDto?> getSchedule(String teacherId);

  /// Creates or replaces the teacher's weekly schedule.
  Future<void> saveSchedule(WeeklyScheduleDto schedule);

  /// Returns dated overrides for [teacherId]. When [from]/[to] are given, only
  /// overrides whose date falls in `[from, to)` (teacher-local) are returned.
  Future<List<AvailabilityOverrideDto>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  });

  /// Creates or replaces a single dated override.
  Future<void> saveOverride(String teacherId, AvailabilityOverrideDto override);

  /// Removes the override for [dateKey] (`yyyy-MM-dd`). A no-op if absent.
  Future<void> removeOverride(String teacherId, String dateKey);
}
