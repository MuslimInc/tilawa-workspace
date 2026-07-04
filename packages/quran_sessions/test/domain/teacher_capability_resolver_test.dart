import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/teacher_application.dart';
import 'package:quran_sessions/src/domain/entities/teacher_capability.dart';
import 'package:quran_sessions/src/domain/entities/teacher_profile.dart';
import 'package:quran_sessions/src/domain/entities/teacher_verification_status.dart';
import 'package:quran_sessions/src/domain/rules/teacher_profile_completeness.dart';

TeacherApplication _application(TeacherApplicationStatus status) =>
    TeacherApplication(
      id: 'app_1',
      userId: 'user_1',
      status: status,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

TeacherProfile _profile({
  bool isActive = true,
  String displayName = 'Ustad Ahmad',
  String? publicBio = 'Experienced teacher',
  TeacherVerificationStatus verificationStatus =
      TeacherVerificationStatus.verified,
  List<String> teachingLanguages = const ['ar'],
  List<String> specializations = const ['tajweed'],
}) => TeacherProfileCompleteness.withComputedVisibility(
  TeacherProfile(
    id: 'app_1',
    userId: 'user_1',
    displayName: displayName,
    publicBio: publicBio,
    verificationStatus: verificationStatus,
    teachingLanguages: teachingLanguages,
    specializations: specializations,
    averageRating: 0,
    reviewCount: 0,
    isActive: isActive,
    profileCompleteness: TeacherProfileCompletenessStatus.incomplete,
    isPubliclyVisible: false,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  ),
);

void main() {
  group('TeacherCapabilityResolver', () {
    test('maps no application to none', () {
      final capability = TeacherCapabilityResolver.resolve();

      check(capability.state).equals(TeacherCapabilityState.none);
      check(capability.showsVerifiedTeacherBadge).isFalse();
      check(capability.canAccessTeacherDashboard).isFalse();
    });

    test('maps draft and pending without profile lookup', () {
      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.draft),
        ).state,
      ).equals(TeacherCapabilityState.draft);

      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.pending),
        ).state,
      ).equals(TeacherCapabilityState.pending);
    });

    test('maps rejected application', () {
      final capability = TeacherCapabilityResolver.resolve(
        application: _application(TeacherApplicationStatus.rejected),
      );

      check(capability.state).equals(TeacherCapabilityState.rejected);
      check(capability.canStartOrContinueApply).isTrue();
      check(capability.canAccessTeacherDashboard).isFalse();
    });

    test('maps approved active profile when public profile complete', () {
      final capability = TeacherCapabilityResolver.resolve(
        application: _application(TeacherApplicationStatus.approved),
        profile: _profile(),
      );

      check(capability.state).equals(TeacherCapabilityState.approvedActive);
      check(capability.showsVerifiedTeacherBadge).isTrue();
      check(capability.canAccessTeacherDashboard).isTrue();
    });

    test('maps approved incomplete when profile missing or incomplete', () {
      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.approved),
        ).state,
      ).equals(TeacherCapabilityState.approvedIncompleteProfile);

      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.approved),
          profile: _profile(publicBio: ''),
        ).state,
      ).equals(TeacherCapabilityState.approvedIncompleteProfile);

      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.approved),
          profile: _profile(displayName: '  '),
        ).state,
      ).equals(TeacherCapabilityState.approvedIncompleteProfile);
    });

    test('maps approved incomplete for placeholder display name', () {
      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.approved),
          profile: _profile(displayName: 'Quran Teacher'),
        ).state,
      ).equals(TeacherCapabilityState.approvedIncompleteProfile);
    });

    test('maps approved inactive when fields complete but inactive', () {
      final capability = TeacherCapabilityResolver.resolve(
        application: _application(TeacherApplicationStatus.approved),
        profile: _profile(isActive: false),
      );

      check(capability.state).equals(TeacherCapabilityState.approvedInactive);
      check(capability.routesApprovedInactiveToTeacherFlows).isTrue();
      check(capability.shouldShowApplicationStatus).isFalse();
      check(capability.canAccessTeacherDashboard).isTrue();
    });

    test('maps approved incomplete when verification pending', () {
      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.approved),
          profile: _profile(
            verificationStatus: TeacherVerificationStatus.pending,
          ),
        ).state,
      ).equals(TeacherCapabilityState.approvedIncompleteProfile);
    });

    test('maps suspended and revoked without dashboard access', () {
      for (final status in [
        TeacherApplicationStatus.suspended,
        TeacherApplicationStatus.revoked,
      ]) {
        final capability = TeacherCapabilityResolver.resolve(
          application: _application(status),
          profile: _profile(),
        );

        check(capability.canAccessTeacherDashboard).isFalse();
        check(capability.showsVerifiedTeacherBadge).isFalse();
      }

      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.suspended),
        ).state,
      ).equals(TeacherCapabilityState.suspended);

      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.revoked),
        ).state,
      ).equals(TeacherCapabilityState.revoked);
    });

    test('hasTeacherMarketplaceRole excludes student-only states', () {
      check(
        const TeacherCapability(
          state: TeacherCapabilityState.none,
        ).hasTeacherMarketplaceRole,
      ).isFalse();
      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.pending),
        ).hasTeacherMarketplaceRole,
      ).isFalse();

      check(
        TeacherCapabilityResolver.resolve(
          application: _application(TeacherApplicationStatus.approved),
          profile: _profile(),
        ).hasTeacherMarketplaceRole,
      ).isTrue();
    });
  });
}
