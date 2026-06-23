import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

TeacherProfile _profile({required String id, required String userId}) =>
    TeacherProfile(
      id: id,
      userId: userId,
      displayName: 'Teacher',
      verificationStatus: TeacherVerificationStatus.verified,
      teachingLanguages: const ['ar'],
      specializations: const ['tajweed'],
      averageRating: 0,
      reviewCount: 0,
      isActive: true,
      profileCompleteness: TeacherProfileCompletenessStatus.complete,
      isPubliclyVisible: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

TeacherApplication _application({required String id, required String userId}) =>
    TeacherApplication(
      id: id,
      userId: userId,
      status: TeacherApplicationStatus.approved,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  group('TeacherCapability.teacherProfileId', () {
    test('prefers profile id over auth user id', () {
      const profileId = 'application_abc';
      const userId = 'firebase_uid_xyz';
      final capability = TeacherCapability(
        state: TeacherCapabilityState.approvedActive,
        application: _application(id: profileId, userId: userId),
        profile: _profile(id: profileId, userId: userId),
      );

      check(capability.teacherProfileId).equals(profileId);
    });

    test('falls back to application id when profile missing', () {
      const profileId = 'application_abc';
      const userId = 'firebase_uid_xyz';
      final capability = TeacherCapability(
        state: TeacherCapabilityState.approvedInactive,
        application: _application(id: profileId, userId: userId),
      );

      check(capability.teacherProfileId).equals(profileId);
    });
  });
}
