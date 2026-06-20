import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/teacher_availability.dart';
import '../../domain/failures/quran_sessions_failure.dart';

/// Abstracts the source of teacher availability data.
///
/// The default implementation reads from the remote API via [TeacherRepository].
/// A calendar-sync implementation could read from Google Calendar, etc.
abstract interface class AvailabilityProvider {
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> getSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  });

  /// Called by the teacher dashboard to publish new availability.
  Future<Either<QuranSessionsFailure, void>> publishSlot(
    TeacherAvailability slot,
  );

  /// Removes a published slot (no active booking must exist).
  Future<Either<QuranSessionsFailure, void>> withdrawSlot(String slotId);
}
