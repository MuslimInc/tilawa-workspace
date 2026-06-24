import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/settings/presentation/cubit/teacher_application_access_cubit.dart';

void main() {
  group('SettingsTeachingVisibility', () {
    test('shows section for approved teacher without waiting for access', () {
      const capability = TeacherCapability(
        state: TeacherCapabilityState.approvedActive,
      );
      final show = SettingsTeachingVisibility.shouldShowSection(
        capabilityLoaded: true,
        capability: capability,
        accessResolved: false,
        canApplyAsTeacher: false,
      );
      check(show).isTrue();
    });

    test('hides section for none capability when access denies', () {
      const capability = TeacherCapability(state: TeacherCapabilityState.none);
      final show = SettingsTeachingVisibility.shouldShowSection(
        capabilityLoaded: true,
        capability: capability,
        accessResolved: true,
        canApplyAsTeacher: false,
      );
      check(show).isFalse();
    });

    test('shows apply entry when access allows and capability is none', () {
      const capability = TeacherCapability(state: TeacherCapabilityState.none);
      final show = SettingsTeachingVisibility.shouldShowSection(
        capabilityLoaded: true,
        capability: capability,
        accessResolved: true,
        canApplyAsTeacher: true,
      );
      check(show).isTrue();
    });

    test('fails closed while access unresolved for none capability', () {
      const capability = TeacherCapability(state: TeacherCapabilityState.none);
      final show = SettingsTeachingVisibility.shouldShowSection(
        capabilityLoaded: true,
        capability: capability,
        accessResolved: false,
        canApplyAsTeacher: false,
      );
      check(show).isFalse();
    });
  });
}
