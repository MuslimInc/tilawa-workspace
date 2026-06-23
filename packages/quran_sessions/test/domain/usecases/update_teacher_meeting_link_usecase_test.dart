import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_teacher_profile_repository.dart';

void main() {
  late FakeTeacherProfileRepository profiles;
  late UpdateTeacherMeetingLinkUseCase useCase;

  setUp(() {
    profiles = FakeTeacherProfileRepository(
      profile: TeacherProfile(
        id: 'teacher_profile_1',
        userId: 'uid_teacher',
        displayName: 'Ustad Ahmad',
        publicBio: 'Tajweed teacher',
        verificationStatus: TeacherVerificationStatus.verified,
        teachingLanguages: const ['ar'],
        specializations: const ['tajweed'],
        averageRating: 0,
        reviewCount: 0,
        isActive: true,
        profileCompleteness: TeacherProfileCompletenessStatus.complete,
        isPubliclyVisible: true,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 2),
      ),
    );
    useCase = UpdateTeacherMeetingLinkUseCase(profiles);
  });

  test('saves valid HTTPS meeting URL', () async {
    final result = await useCase(
      userId: 'uid_teacher',
      externalMeetingUrl: 'https://meet.google.com/room-1',
    );

    check(result.isRight()).isTrue();
    result.fold(
      (_) => fail('expected Right'),
      (profile) => check(
        profile.externalMeetingUrl,
      ).equals('https://meet.google.com/room-1'),
    );
  });

  test('rejects invalid meeting URL', () async {
    final result = await useCase(
      userId: 'uid_teacher',
      externalMeetingUrl: 'ftp://bad.example',
    );

    check(result.isLeft()).isTrue();
    result.fold(
      (f) => check(f).isA<ValidationFailure>(),
      (_) => fail('expected Left'),
    );
  });

  test('writes URL on profile doc id not auth userId', () async {
    const profileId = 'a1sYAAaBHg5aq1uwya0o';
    profiles = FakeTeacherProfileRepository(
      profile: TeacherProfile(
        id: profileId,
        userId: 'uid_teacher',
        displayName: 'Ustad Ahmad',
        publicBio: 'Tajweed teacher',
        verificationStatus: TeacherVerificationStatus.verified,
        teachingLanguages: const ['ar'],
        specializations: const ['tajweed'],
        averageRating: 0,
        reviewCount: 0,
        isActive: true,
        profileCompleteness: TeacherProfileCompletenessStatus.complete,
        isPubliclyVisible: true,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 2),
      ),
    );
    useCase = UpdateTeacherMeetingLinkUseCase(profiles);

    final result = await useCase(
      userId: 'uid_teacher',
      externalMeetingUrl: 'https://meet.google.com/fiy-jjux-mab',
    );

    check(result.isRight()).isTrue();
    check(profiles.lastUpdatedPublicProfile?.id).equals(profileId);
    check(profiles.lastUpdatedPublicProfile?.userId).equals('uid_teacher');
    check(profiles.lastUpdatedPublicProfile?.externalMeetingUrl)
        .equals('https://meet.google.com/fiy-jjux-mab');
  });
}
