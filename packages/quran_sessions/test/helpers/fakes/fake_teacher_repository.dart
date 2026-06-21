import 'package:dartz_plus/dartz_plus.dart';

import 'package:quran_sessions/src/domain/entities/quran_teacher.dart';
import 'package:quran_sessions/src/domain/entities/session_price.dart';
import 'package:quran_sessions/src/domain/entities/session_review.dart';
import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/repositories/teacher_repository.dart';

/// In-memory fake for [TeacherRepository].
/// Seed [teachers], [availability], and [reviews] before each test.
/// Set [priceToReturn] to override what [resolveTeacherPrice] returns
/// (default: returns the teacher's own [price] field, or null if not found).
class FakeTeacherRepository implements TeacherRepository {
  List<QuranTeacher> teachers = [];
  List<TeacherAvailability> availability = [];
  List<SessionReview> reviews = [];
  QuranSessionsFailure? failWith;
  // null means "derive from teacher.price"; set explicitly to test failures.
  SessionPrice? Function(String teacherId)? priceResolver;

  @override
  Future<Either<QuranSessionsFailure, TeacherPage>> getTeachers({
    String? specialization,
    String? language,
    String? cursor,
  }) async {
    if (failWith != null) return Left(failWith!);
    var result = teachers;
    if (specialization != null) {
      result = result
          .where((t) => t.specializations.contains(specialization))
          .toList();
    }
    return Right(TeacherPage(teachers: result, nextCursor: null));
  }

  @override
  Future<Either<QuranSessionsFailure, QuranTeacher>> getTeacherById(
    String teacherId,
  ) async {
    if (failWith != null) return Left(failWith!);
    final match = teachers.where((t) => t.id == teacherId).firstOrNull;
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
    if (failWith != null) return Left(failWith!);
    return Right(
      availability
          .where(
            (s) =>
                s.teacherId == teacherId &&
                s.startsAt.isAfter(from) &&
                s.endsAt.isBefore(to),
          )
          .toList(),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, List<SessionReview>>> getTeacherReviews(
    String teacherId, {
    String? cursor,
  }) async {
    if (failWith != null) return Left(failWith!);
    return Right(reviews.where((r) => r.teacherId == teacherId).toList());
  }

  @override
  Future<Either<QuranSessionsFailure, SessionPrice?>> resolveTeacherPrice(
    String teacherId, {
    required String countryCode,
    required String cityId,
  }) async {
    if (failWith != null) return Left(failWith!);
    if (priceResolver != null) return Right(priceResolver!(teacherId));
    final match = teachers.where((t) => t.id == teacherId).firstOrNull;
    return Right(match?.price);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
