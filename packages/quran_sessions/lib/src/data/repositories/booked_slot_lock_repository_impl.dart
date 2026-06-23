import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/booked_slot_lock_repository.dart';
import '../../domain/repositories/teacher_profile_repository.dart';
import '../../domain/services/booked_slot_starts.dart';
import '../datasources/booked_slot_lock_remote_data_source.dart';
import '../dtos/slot_lock_dto.dart';
import 'repository_error_mapper.dart';

class BookedSlotLockRepositoryImpl implements BookedSlotLockRepository {
  const BookedSlotLockRepositoryImpl(
    this._remote, {
    this._teacherProfiles,
  });

  final BookedSlotLockRemoteDataSource _remote;
  final TeacherProfileRepository? _teacherProfiles;

  Future<String?> _legacyOwnerUserId(String teacherProfileId) async {
    final profiles = _teacherProfiles;
    if (profiles == null) return null;
    final profileResult = await profiles.getProfileById(teacherProfileId);
    return profileResult.fold((_) => null, (profile) {
      final userId = profile.userId;
      return userId == teacherProfileId ? null : userId;
    });
  }

  Future<List<SlotLockDto>> _loadLocks(String teacherProfileId) async {
    final primary = await _remote.getLocksForTeacher(teacherProfileId);
    final legacyUserId = await _legacyOwnerUserId(teacherProfileId);
    if (legacyUserId == null) return primary;
    final legacy = await _remote.getLocksForTeacher(legacyUserId);
    if (legacy.isEmpty) return primary;
    final bySlotId = <String, SlotLockDto>{
      for (final lock in primary) lock.slotId: lock,
    };
    for (final lock in legacy) {
      bySlotId.putIfAbsent(lock.slotId, () => lock);
    }
    return bySlotId.values.toList();
  }

  @override
  Future<Either<QuranSessionsFailure, Set<DateTime>>> getActiveBookedStarts(
    String teacherProfileId, {
    required DateTime windowStart,
    required DateTime windowEnd,
    DateTime? now,
  }) async {
    try {
      final legacyUserId = await _legacyOwnerUserId(teacherProfileId);
      final dtos = await _loadLocks(teacherProfileId);
      return Right(
        collectBookedStartsFromSlotLocks(
          dtos.map((dto) => dto.toSnapshot()),
          teacherProfileId: teacherProfileId,
          alternateTeacherIds: legacyUserId == null ? const [] : [legacyUserId],
          windowStart: windowStart,
          windowEnd: windowEnd,
          now: now ?? DateTime.now(),
        ),
      );
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
