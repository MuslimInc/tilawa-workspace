import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

void main() {
  group('QuranSessionsFeatureConfig', () {
    test(
      'showEmptyStateTeacherEntry requires apply enabled and discoverability',
      () {
        const enabled = QuranSessionsFeatureConfig(
          teacherApplicationEnabled: true,
          teacherApplicationDiscoverability:
              TeacherApplicationDiscoverability.profileAndEmptyState,
        );
        check(enabled.showEmptyStateTeacherEntry).isTrue();
        check(enabled.showProfileTeacherEntry).isTrue();

        const profileOnly = QuranSessionsFeatureConfig(
          teacherApplicationEnabled: true,
          teacherApplicationDiscoverability:
              TeacherApplicationDiscoverability.profileOnly,
        );
        check(profileOnly.showEmptyStateTeacherEntry).isFalse();
        check(profileOnly.showProfileTeacherEntry).isTrue();

        const disabled = QuranSessionsFeatureConfig(
          teacherApplicationEnabled: false,
        );
        check(disabled.showProfileTeacherEntry).isFalse();

        const killSwitch = QuranSessionsFeatureConfig(
          quranSessionsEnabled: false,
          teacherApplicationEnabled: true,
          teacherApplicationDiscoverability:
              TeacherApplicationDiscoverability.profileAndEmptyState,
        );
        check(killSwitch.showProfileTeacherEntry).isFalse();
        check(killSwitch.showEmptyStateTeacherEntry).isFalse();
      },
    );
  });

  group('TeacherApplication eligibility helpers', () {
    test('canStartOrContinueApply excludes pending and approved', () {
      final pending = TeacherApplication(
        id: '1',
        userId: 'u',
        status: TeacherApplicationStatus.pending,
        createdAt: _t,
        updatedAt: _t,
      );
      check(pending.canStartOrContinueApply).isFalse();
      check(pending.canAccessTeacherDashboard).isFalse();

      final approved = TeacherApplication(
        id: '1',
        userId: 'u',
        status: TeacherApplicationStatus.approved,
        createdAt: _t,
        updatedAt: _t,
      );
      check(approved.canStartOrContinueApply).isFalse();
      check(approved.canAccessTeacherDashboard).isTrue();
    });
  });
}

final DateTime _t = DateTime(2026, 1, 1);
