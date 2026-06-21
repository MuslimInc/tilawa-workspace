import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/src/domain/entities/teacher_application.dart';
import 'package:quran_sessions/src/domain/entities/teacher_capability.dart';
import 'package:quran_sessions/src/presentation/teacher_capability/teacher_capability_presentation.dart';

TeacherCapability _capability(
  TeacherCapabilityState state,
) => TeacherCapability(
  state: state,
  application: state == TeacherCapabilityState.none
      ? null
      : TeacherApplication(
          id: 'app_1',
          userId: 'user_1',
          status: switch (state) {
            TeacherCapabilityState.draft => TeacherApplicationStatus.draft,
            TeacherCapabilityState.pending => TeacherApplicationStatus.pending,
            TeacherCapabilityState.rejected =>
              TeacherApplicationStatus.rejected,
            TeacherCapabilityState.approvedActive ||
            TeacherCapabilityState.approvedIncompleteProfile ||
            TeacherCapabilityState.approvedInactive =>
              TeacherApplicationStatus.approved,
            TeacherCapabilityState.suspended =>
              TeacherApplicationStatus.suspended,
            TeacherCapabilityState.revoked => TeacherApplicationStatus.revoked,
            TeacherCapabilityState.none => TeacherApplicationStatus.none,
          },
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
);

void main() {
  late QuranSessionsLocalizations en;

  setUp(() async {
    en = await QuranSessionsLocalizations.delegate.load(const Locale('en'));
  });

  group('TeacherCapability presentation', () {
    test('approved active teacher sees dashboard CTA not apply', () {
      final capability = _capability(TeacherCapabilityState.approvedActive);

      check(
        capability.teachingSectionActionTitle(en),
      ).equals(en.teacherDashboard);
      check(
        capability.navigationTarget,
      ).equals(TeacherCapabilityNavigationTarget.teacherDashboard);
      check(capability.showsVerifiedTeacherBadge).isTrue();
    });

    test('approved incomplete teacher completes profile not dashboard', () {
      final capability = _capability(
        TeacherCapabilityState.approvedIncompleteProfile,
      );

      check(
        capability.teachingSectionActionTitle(en),
      ).equals(en.completeTeacherProfile);
      check(capability.navigationTarget).equals(
        TeacherCapabilityNavigationTarget.completeTeacherProfile,
      );
      check(capability.canAccessTeacherDashboard).isFalse();
    });

    test('pending teacher sees view status not dashboard', () {
      final capability = _capability(TeacherCapabilityState.pending);

      check(
        capability.teachingSectionActionTitle(en),
      ).equals(en.teachingOnMemuslimViewStatus);
      check(
        capability.navigationTarget,
      ).equals(TeacherCapabilityNavigationTarget.applicationStatus);
      check(capability.showsVerifiedTeacherBadge).isFalse();
    });

    test(
      'rejected teacher sees view status with reapply subtitle when allowed',
      () {
        final capability = _capability(TeacherCapabilityState.rejected);

        check(
          capability.teachingSectionActionTitle(en),
        ).equals(en.teachingOnMemuslimViewStatus);
        check(
          capability.teachingSectionSubtitle(en),
        ).equals(en.teachingOnMemuslimReapplySubtitle);
      },
    );

    test('suspended teacher cannot access dashboard', () {
      final capability = _capability(TeacherCapabilityState.suspended);

      check(capability.canAccessTeacherDashboard).isFalse();
      check(
        capability.statusBadgeLabel(en),
      ).equals(en.teacherCapabilityStatusSuspended);
    });

    test('none state offers apply action only', () {
      final capability = _capability(TeacherCapabilityState.none);

      check(
        capability.teachingSectionActionTitle(en),
      ).equals(en.teachingOnMemuslimApply);
      check(
        capability.navigationTarget,
      ).equals(TeacherCapabilityNavigationTarget.apply);
    });
  });
}
