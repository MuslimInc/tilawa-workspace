import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application.dart';
import '../entities/teacher_capability.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_application_repository.dart';
import '../repositories/teacher_profile_repository.dart';
import '../rules/teacher_profile_completeness.dart';

/// Resolves the signed-in user's teacher marketplace capability.
///
/// Loads [TeacherProfile] only when the application has reached a post-approval
/// lifecycle state so draft/pending paths stay a single query.
class GetCurrentUserTeacherCapabilityUseCase {
  const GetCurrentUserTeacherCapabilityUseCase({
    required TeacherApplicationRepository applicationRepository,
    required TeacherProfileRepository profileRepository,
  }) : _applications = applicationRepository,
       _profiles = profileRepository;

  final TeacherApplicationRepository _applications;
  final TeacherProfileRepository _profiles;

  Future<Either<QuranSessionsFailure, TeacherCapability>> call(
    String userId,
  ) async {
    final applicationResult = await _applications.getApplication(userId);

    if (applicationResult.isLeft()) {
      final failure = applicationResult.fold((f) => f, (_) => null)!;
      if (failure is TeacherApplicationNotFoundFailure) {
        return const Right(
          TeacherCapability(state: TeacherCapabilityState.none),
        );
      }
      return Left(failure);
    }

    final application = applicationResult.fold((_) => null, (app) => app)!;

    if (!_needsProfile(application.status)) {
      return Right(
        TeacherCapabilityResolver.resolve(application: application),
      );
    }

    final profileResult = await _profiles.getProfileByUserId(userId);
    final profile = profileResult.fold(
      (_) => null,
      TeacherProfileCompleteness.withComputedVisibility,
    );

    return Right(
      TeacherCapabilityResolver.resolve(
        application: application,
        profile: profile,
      ),
    );
  }

  static bool _needsProfile(TeacherApplicationStatus status) =>
      status == TeacherApplicationStatus.approved ||
      status == TeacherApplicationStatus.suspended ||
      status == TeacherApplicationStatus.revoked;
}
