import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class TeacherApplicationRepository {
  /// Returns the current application for [userId], or
  /// [TeacherApplicationNotFoundFailure] if none exists.
  Future<Either<QuranSessionsFailure, TeacherApplication>> getApplication(
    String userId,
  );

  /// Creates a new application in the [TeacherApplicationStatus.draft] state.
  /// Returns [TeacherApplicationAlreadyPendingFailure] if the user already has
  /// a pending or approved application.
  Future<Either<QuranSessionsFailure, TeacherApplication>> createDraft(
    String userId,
  );

  /// Persists a [draft] application without changing its status.
  Future<Either<QuranSessionsFailure, TeacherApplication>> saveDraft(
    TeacherApplication draft,
  );

  /// Advances a [draft] application to [TeacherApplicationStatus.pending].
  ///
  /// Preconditions (enforced in use case, not here):
  /// - [TeacherApplication.hasValidPhone] is true.
  /// - [TeacherApplication.isReadyToSubmit] is true.
  Future<Either<QuranSessionsFailure, TeacherApplication>> submit(
    TeacherApplication application,
  );

  /// Admin: approves a pending application.
  Future<Either<QuranSessionsFailure, TeacherApplication>> approve({
    required String applicationId,
    required String reviewedBy,
  });

  /// Admin: rejects a pending application.
  Future<Either<QuranSessionsFailure, TeacherApplication>> reject({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  });

  /// Admin: suspends an approved application temporarily.
  Future<Either<QuranSessionsFailure, TeacherApplication>> suspend({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  });

  /// Admin: permanently revokes an approved application.
  Future<Either<QuranSessionsFailure, TeacherApplication>> revoke({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  });
}
