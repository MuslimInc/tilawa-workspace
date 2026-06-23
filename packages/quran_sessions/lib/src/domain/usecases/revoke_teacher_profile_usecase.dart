import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../entities/teacher_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';
import '../repositories/teacher_profile_repository.dart';

/// Admin use case: permanently revokes an approved teacher's profile.
///
/// Revocation is irreversible — the teacher cannot re-apply.
/// Both the [TeacherApplication] and the [TeacherProfile] are deactivated.
class RevokeTeacherProfileUseCase {
  const RevokeTeacherProfileUseCase({
    required TeacherApplicationRepository applicationRepository,
    required TeacherProfileRepository profileRepository,
  }) : _applications = applicationRepository,
       _profiles = profileRepository;

  final TeacherApplicationRepository _applications;
  final TeacherProfileRepository _profiles;

  Future<Either<QuranSessionsFailure, TeacherProfile>> call({
    required String applicationId,
    required String profileId,
    required String reviewedBy,
    required String reason,
  }) async {
    final revokeResult = await _applications.revoke(
      applicationId: applicationId,
      reviewedBy: reviewedBy,
      reason: reason,
    );
    if (revokeResult.isLeft()) {
      return revokeResult.map((_) => throw StateError('unreachable'));
    }
    return _profiles.deactivate(profileId);
  }
}
