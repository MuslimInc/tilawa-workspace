import 'package:dartz_plus/dartz_plus.dart';

import '../../../lib/src/boundaries/scheduling/availability_provider.dart';
import '../../../lib/src/domain/entities/teacher_availability.dart';
import '../../../lib/src/domain/failures/quran_sessions_failure.dart';

class FakeAvailabilityProvider implements AvailabilityProvider {
  final List<TeacherAvailability> published = [];
  final List<String> withdrawn = [];
  bool shouldFail = false;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> getSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async => Right(
    published
        .where(
          (s) =>
              s.teacherId == teacherId &&
              s.startsAt.isAfter(from) &&
              s.endsAt.isBefore(to),
        )
        .toList(),
  );

  @override
  Future<Either<QuranSessionsFailure, void>> publishSlot(
    TeacherAvailability slot,
  ) async {
    if (shouldFail) return const Left(UnknownFailure());
    published.add(slot);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> withdrawSlot(
    String slotId,
  ) async {
    if (shouldFail) return const Left(UnknownFailure());
    withdrawn.add(slotId);
    published.removeWhere((s) => s.slotId == slotId);
    return const Right(null);
  }
}
