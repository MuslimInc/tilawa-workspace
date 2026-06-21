import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/teacher_profile.dart';
import 'package:quran_sessions/src/domain/entities/teacher_verification_status.dart';
import 'package:quran_sessions/src/domain/rules/teacher_profile_completeness.dart';

TeacherProfile _profile({
  String displayName = 'Ustad Ahmad',
  String? publicBio = 'Experienced teacher',
  bool isActive = true,
  TeacherProfileCompletenessStatus profileCompleteness =
      TeacherProfileCompletenessStatus.incomplete,
  bool isPubliclyVisible = false,
}) => TeacherProfile(
  id: 'app_1',
  userId: 'user_1',
  displayName: displayName,
  publicBio: publicBio,
  verificationStatus: TeacherVerificationStatus.verified,
  teachingLanguages: const ['ar'],
  specializations: const ['tajweed'],
  averageRating: 0,
  reviewCount: 0,
  isActive: isActive,
  profileCompleteness: profileCompleteness,
  isPubliclyVisible: isPubliclyVisible,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  group('TeacherProfileCompleteness', () {
    test('empty displayName marks profile incomplete', () {
      check(
        TeacherProfileCompleteness.forProfile(_profile(displayName: '  ')),
      ).equals(TeacherProfileCompletenessStatus.incomplete);
    });

    test('incomplete profile is not publicly visible', () {
      check(
        TeacherProfileCompleteness.isProfilePubliclyVisible(
          _profile(displayName: '  '),
        ),
      ).isFalse();
    });

    test('complete active profile is publicly visible', () {
      final complete = TeacherProfileCompleteness.withComputedVisibility(
        _profile(
          displayName: 'Ustad Ahmad',
          publicBio: 'Bio',
          isActive: true,
        ),
      );

      check(
        complete.profileCompleteness,
      ).equals(TeacherProfileCompletenessStatus.complete);
      check(complete.isPubliclyVisible).isTrue();
    });

    test('complete but inactive profile stays off marketplace', () {
      final profile = TeacherProfileCompleteness.withComputedVisibility(
        _profile(
          displayName: 'Ustad Ahmad',
          publicBio: 'Bio',
          isActive: false,
        ),
      );

      check(
        profile.profileCompleteness,
      ).equals(TeacherProfileCompletenessStatus.complete);
      check(profile.isPubliclyVisible).isFalse();
    });
  });
}
