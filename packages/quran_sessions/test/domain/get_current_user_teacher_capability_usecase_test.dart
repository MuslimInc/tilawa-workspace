import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/teacher_application.dart';
import 'package:quran_sessions/src/domain/entities/teacher_capability.dart';
import 'package:quran_sessions/src/domain/entities/teacher_profile.dart';
import 'package:quran_sessions/src/domain/entities/teacher_verification_status.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/rules/teacher_profile_completeness.dart';
import 'package:quran_sessions/src/domain/usecases/approve_teacher_application_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_current_user_teacher_capability_usecase.dart';

import '../helpers/fakes/fake_teacher_application_repository.dart';
import '../helpers/fakes/fake_teacher_profile_repository.dart';

class _RecordingTeacherProfileRepository extends FakeTeacherProfileRepository {
  TeacherProfile? createdProfile;

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> createProfile(
    TeacherProfile profile,
  ) async {
    createdProfile = profile;
    return Right(profile);
  }
}

class _ConfigurableTeacherProfileRepository
    extends FakeTeacherProfileRepository {
  _ConfigurableTeacherProfileRepository(this.profile);

  final TeacherProfile? profile;

  @override
  Future<Either<QuranSessionsFailure, TeacherProfile>> getProfileByUserId(
    String userId,
  ) async {
    final current = profile;
    if (current == null || current.userId != userId) {
      return const Left(TeacherProfileNotApprovedFailure());
    }
    return Right(current);
  }
}

TeacherApplication _pendingApplication() => TeacherApplication(
  id: 'app_1',
  userId: 'user_1',
  status: TeacherApplicationStatus.pending,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

TeacherProfile _activeProfile() =>
    TeacherProfileCompleteness.withComputedVisibility(
      TeacherProfile(
        id: 'app_1',
        userId: 'user_1',
        displayName: 'Teacher One',
        publicBio: 'Bio',
        verificationStatus: TeacherVerificationStatus.verified,
        teachingLanguages: const ['ar'],
        specializations: const ['tajweed'],
        averageRating: 0,
        reviewCount: 0,
        isActive: true,
        profileCompleteness: TeacherProfileCompletenessStatus.incomplete,
        isPubliclyVisible: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );

void main() {
  group('GetCurrentUserTeacherCapabilityUseCase', () {
    late FakeTeacherApplicationRepository applicationRepo;
    late _ConfigurableTeacherProfileRepository profileRepo;
    late GetCurrentUserTeacherCapabilityUseCase useCase;

    setUp(() {
      applicationRepo = FakeTeacherApplicationRepository();
      profileRepo = _ConfigurableTeacherProfileRepository(null);
      useCase = GetCurrentUserTeacherCapabilityUseCase(
        applicationRepository: applicationRepo,
        profileRepository: profileRepo,
      );
    });

    test('returns none when application missing', () async {
      final result = await useCase('user_1');

      check(result.isRight()).isTrue();
      result.fold(
        (_) => fail('expected success'),
        (capability) =>
            check(capability.state).equals(TeacherCapabilityState.none),
      );
    });

    test('returns pending without profile query', () async {
      applicationRepo.application = _pendingApplication();

      final result = await useCase('user_1');

      result.fold(
        (_) => fail('expected success'),
        (capability) =>
            check(capability.state).equals(TeacherCapabilityState.pending),
      );
    });

    test(
      'returns approvedActive when profile is active and verified',
      () async {
        applicationRepo.application = _pendingApplication().copyWith(
          status: TeacherApplicationStatus.approved,
        );
        profileRepo = _ConfigurableTeacherProfileRepository(_activeProfile());
        useCase = GetCurrentUserTeacherCapabilityUseCase(
          applicationRepository: applicationRepo,
          profileRepository: profileRepo,
        );

        final result = await useCase('user_1');

        result.fold(
          (_) => fail('expected success'),
          (capability) => check(
            capability.state,
          ).equals(TeacherCapabilityState.approvedActive),
        );
      },
    );

    test('returns suspended without dashboard access', () async {
      applicationRepo.application = _pendingApplication().copyWith(
        status: TeacherApplicationStatus.suspended,
      );
      profileRepo = _ConfigurableTeacherProfileRepository(_activeProfile());
      useCase = GetCurrentUserTeacherCapabilityUseCase(
        applicationRepository: applicationRepo,
        profileRepository: profileRepo,
      );

      final result = await useCase('user_1');

      result.fold(
        (_) => fail('expected success'),
        (capability) {
          check(capability.state).equals(TeacherCapabilityState.suspended);
          check(capability.canAccessTeacherDashboard).isFalse();
        },
      );
    });
  });

  group('ApproveTeacherApplicationUseCase', () {
    test('copies publicDisplayName to TeacherProfile.displayName', () async {
      final applicationRepo = FakeTeacherApplicationRepository();
      final profileRepo = _RecordingTeacherProfileRepository();

      applicationRepo.application = TeacherApplication(
        id: 'app_1',
        userId: 'user_1',
        status: TeacherApplicationStatus.pending,
        publicDisplayName: 'Ustad Ahmad Ali',
        teachingLanguages: const ['ar'],
        specializations: const ['tajweed'],
        bio: 'Private application bio',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final useCase = ApproveTeacherApplicationUseCase(
        applicationRepository: applicationRepo,
        profileRepository: profileRepo,
      );

      final result = await useCase(
        applicationId: 'app_1',
        reviewedBy: 'admin_1',
      );

      check(result.isRight()).isTrue();
      check(profileRepo.createdProfile!.displayName).equals('Ustad Ahmad Ali');
      check(profileRepo.createdProfile!.publicBio).equals(
        'Private application bio',
      );
    });

    test('does not use bio as displayName', () async {
      final applicationRepo = FakeTeacherApplicationRepository();
      final profileRepo = _RecordingTeacherProfileRepository();

      applicationRepo.application = TeacherApplication(
        id: 'app_1',
        userId: 'user_1',
        status: TeacherApplicationStatus.pending,
        publicDisplayName: 'Sheikh Omar',
        teachingLanguages: const ['ar'],
        specializations: const ['tajweed'],
        bio: 'Long biography that must not become the display name',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final useCase = ApproveTeacherApplicationUseCase(
        applicationRepository: applicationRepo,
        profileRepository: profileRepo,
      );

      await useCase(applicationId: 'app_1', reviewedBy: 'admin_1');

      check(profileRepo.createdProfile!.displayName).equals('Sheikh Omar');
      check(
        profileRepo.createdProfile!.displayName ==
            profileRepo.createdProfile!.publicBio,
      ).isFalse();
    });

    test('stores computed visibility on newly approved profile', () async {
      final applicationRepo = FakeTeacherApplicationRepository();
      final profileRepo = _RecordingTeacherProfileRepository();

      applicationRepo.application = TeacherApplication(
        id: 'app_1',
        userId: 'user_1',
        status: TeacherApplicationStatus.pending,
        publicDisplayName: 'Sheikh Omar',
        teachingLanguages: const ['ar'],
        specializations: const ['tajweed'],
        bio: 'Bio',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final useCase = ApproveTeacherApplicationUseCase(
        applicationRepository: applicationRepo,
        profileRepository: profileRepo,
      );

      await useCase(applicationId: 'app_1', reviewedBy: 'admin_1');

      check(
        profileRepo.createdProfile!.profileCompleteness,
      ).equals(TeacherProfileCompletenessStatus.complete);
      check(profileRepo.createdProfile!.isPubliclyVisible).isTrue();
    });
  });
}
