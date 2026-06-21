import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../entities/teacher_profile.dart';
import '../entities/teacher_verification_status.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';
import '../repositories/teacher_profile_repository.dart';

/// Admin use case: approves a pending [TeacherApplication] and creates the
/// corresponding public [TeacherProfile].
///
/// This is the only path by which a [TeacherProfile] is created.
class ApproveTeacherApplicationUseCase {
  const ApproveTeacherApplicationUseCase({
    required TeacherApplicationRepository applicationRepository,
    required TeacherProfileRepository profileRepository,
  }) : _applications = applicationRepository,
       _profiles = profileRepository;

  final TeacherApplicationRepository _applications;
  final TeacherProfileRepository _profiles;

  Future<Either<QuranSessionsFailure, TeacherProfile>> call({
    required String applicationId,
    required String reviewedBy,
  }) async {
    final approveResult = await _applications.approve(
      applicationId: applicationId,
      reviewedBy: reviewedBy,
    );

    if (approveResult.isLeft) {
      return approveResult.map((_) => throw StateError('unreachable'));
    }
    final application = approveResult.fold(
      (_) => throw StateError(''),
      (a) => a,
    );
    final now = DateTime.now();
    final profile = TeacherProfile(
      id: application.id,
      userId: application.userId,
      displayName: '',
      publicBio: application.bio,
      verificationStatus: TeacherVerificationStatus.verified,
      teachingLanguages: application.teachingLanguages,
      specializations: application.specializations,
      averageRating: 0,
      reviewCount: 0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    return _profiles.createProfile(profile);
  }
}
