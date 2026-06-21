import 'package:dartz_plus/dartz_plus.dart';

import '../../../lib/src/domain/entities/teacher_application.dart';
import '../../../lib/src/domain/failures/quran_sessions_failure.dart';
import '../../../lib/src/domain/repositories/teacher_application_repository.dart';

/// In-memory fake for [TeacherApplicationRepository].
///
/// Seed [application] before each test.
/// Set [failWith] to simulate repository failures on any write operation.
/// Set [submitFailure] to simulate a failure specifically on [submit].
class FakeTeacherApplicationRepository
    implements TeacherApplicationRepository {
  TeacherApplication? application;
  QuranSessionsFailure? failWith;
  QuranSessionsFailure? submitFailure;

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> getApplication(
    String userId,
  ) async {
    if (failWith != null) return Left(failWith!);
    final app = application;
    if (app == null) {
      return const Left(TeacherApplicationNotFoundFailure());
    }
    return Right(app);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> createDraft(
    String userId,
  ) async {
    if (failWith != null) return Left(failWith!);
    final draft = TeacherApplication(
      id: 'app_$userId',
      userId: userId,
      status: TeacherApplicationStatus.draft,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    application = draft;
    return Right(draft);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> saveDraft(
    TeacherApplication draft,
  ) async {
    if (failWith != null) return Left(failWith!);
    application = draft;
    return Right(draft);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> submit(
    TeacherApplication app,
  ) async {
    if (submitFailure != null) return Left(submitFailure!);
    if (failWith != null) return Left(failWith!);
    final submitted = app.copyWith(status: TeacherApplicationStatus.pending);
    application = submitted;
    return Right(submitted);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> approve({
    required String applicationId,
    required String reviewedBy,
  }) async {
    if (failWith != null) return Left(failWith!);
    final app = application;
    if (app == null) return const Left(NotFoundFailure('TeacherApplication'));
    final approved = app.copyWith(status: TeacherApplicationStatus.approved);
    application = approved;
    return Right(approved);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> reject({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    if (failWith != null) return Left(failWith!);
    final app = application;
    if (app == null) return const Left(NotFoundFailure('TeacherApplication'));
    final rejected = app.copyWith(status: TeacherApplicationStatus.rejected);
    application = rejected;
    return Right(rejected);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> suspend({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    if (failWith != null) return Left(failWith!);
    final app = application;
    if (app == null) return const Left(NotFoundFailure('TeacherApplication'));
    final suspended = app.copyWith(status: TeacherApplicationStatus.suspended);
    application = suspended;
    return Right(suspended);
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherApplication>> revoke({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    if (failWith != null) return Left(failWith!);
    final app = application;
    if (app == null) return const Left(NotFoundFailure('TeacherApplication'));
    final revoked = app.copyWith(status: TeacherApplicationStatus.revoked);
    application = revoked;
    return Right(revoked);
  }
}
