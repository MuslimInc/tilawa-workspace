import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../entities/teacher_profile.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';
import '../repositories/teacher_profile_repository.dart';

/// Admin use case: temporarily suspends an approved teacher.
///
/// Both the [TeacherApplication] status and the [TeacherProfile.isActive] flag
/// are updated atomically. The teacher cannot accept new bookings while
/// suspended. Existing bookings should be handled by the admin separately.
class SuspendTeacherProfileUseCase {
  const SuspendTeacherProfileUseCase({
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
    final suspendResult = await _applications.suspend(
      applicationId: applicationId,
      reviewedBy: reviewedBy,
      reason: reason,
    );
    if (suspendResult.isLeft) {
      return suspendResult.map((_) => throw StateError('unreachable'));
    }
    return _profiles.deactivate(profileId);
  }
}
