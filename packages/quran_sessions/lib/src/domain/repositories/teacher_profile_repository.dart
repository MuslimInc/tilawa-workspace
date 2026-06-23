import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_profile.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class TeacherProfileRepository {
  /// Returns the public [TeacherProfile] for [userId].
  /// Returns [TeacherProfileNotApprovedFailure] if no approved profile exists.
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileByUserId(
    String userId,
  );

  /// Returns the public [TeacherProfile] by its profile [id].
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileById(
    String id,
  );

  /// Creates a [TeacherProfile] after a [TeacherApplication] is approved.
  /// Called internally by the approval flow — not directly by student-facing
  /// code.
  Future<Either<QuranSessionsFailure, TeacherProfile>> createProfile(
    TeacherProfile profile,
  );

  /// Updates mutable public fields (bio, avatar, active status, etc.).
  Future<Either<QuranSessionsFailure, TeacherProfile>> updateProfile(
    TeacherProfile profile,
  );

  /// Updates only client-writable public marketplace fields.
  ///
  /// Omits server-owned trust fields (`profileCompleteness`,
  /// `isPubliclyVisible`, `verificationStatus`, etc.) so Firestore rules allow
  /// verified owners to save from the app.
  Future<Either<QuranSessionsFailure, TeacherProfile>> updatePublicProfile(
    TeacherProfile profile,
  );

  /// Deactivates the profile without revoking the underlying application.
  Future<Either<QuranSessionsFailure, TeacherProfile>> deactivate(String id);

  /// Reactivates a previously deactivated profile.
  Future<Either<QuranSessionsFailure, TeacherProfile>> reactivate(String id);
}
