import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

class FakeMvpTeacherRepository implements TeacherRepository {
  FakeMvpTeacherRepository(this._store);

  final QuranSessionsMvpStore _store;

  @override
  Future<Either<QuranSessionsFailure, TeacherPage>> getTeachers({
    String? specialization,
    String? language,
    String? cursor,
  }) async {
    var result = _store.teachers;
    if (specialization != null) {
      result = result
          .where((t) => t.specializations.contains(specialization))
          .toList();
    }
    if (language != null) {
      result = result.where((t) => t.languages.contains(language)).toList();
    }
    return Right(TeacherPage(teachers: result, nextCursor: null));
  }

  @override
  Future<Either<QuranSessionsFailure, QuranTeacher>> getTeacherById(
    String teacherId,
  ) async {
    final match = _store.teachers.where((t) => t.id == teacherId).firstOrNull;
    if (match == null) return const Left(NotFoundFailure('QuranTeacher'));
    return Right(match);
  }

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>>
  getAvailableSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final result = _store.slots
        .where(
          (s) =>
              s.teacherId == teacherId &&
              s.startsAt.isAfter(from) &&
              s.startsAt.isBefore(to) &&
              !s.isBooked,
        )
        .toList();
    return Right(result);
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionReview>>> getTeacherReviews(
    String teacherId, {
    String? cursor,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPrice?>> resolveTeacherPrice(
    String teacherId, {
    required String countryCode,
    required String cityId,
  }) async {
    return Right(_store.resolvePrice(teacherId, countryCode, cityId));
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
