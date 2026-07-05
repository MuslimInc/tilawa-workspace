import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';

class _StaticAvailabilityUseCase extends GetTeacherAvailabilityUseCase {
  _StaticAvailabilityUseCase(this.slots)
    : super(
        scheduleRepository: FakeScheduleRepository(),
        bookedSlotLocks: FakeBookedSlotLockRepository(),
      );

  final Map<String, List<TeacherAvailability>> slots;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
    WeeklySchedule? preloadedSchedule,
  }) async {
    return Right(slots[teacherId] ?? const []);
  }
}

/// Seeds [TeacherListBloc] with a fixed state and ignores incoming events.
class TeacherListTestBloc extends TeacherListBloc {
  TeacherListTestBloc(TeacherListState seed)
    : super(
        GetTeachersUseCase(FakeTeacherRepository()),
        _StaticAvailabilityUseCase(const {}),
      ) {
    emit(seed);
  }

  @override
  void add(TeacherListEvent event) {}
}
