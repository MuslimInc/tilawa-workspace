import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/settings/presentation/cubit/teacher_application_access_cubit.dart';

void main() {
  group('SettingsTeachingVisibility', () {
    test('shows section for approved active teacher', () {
      const capability = TeacherCapability(
        state: TeacherCapabilityState.approvedActive,
      );
      final show = SettingsTeachingVisibility.shouldShowSection(
        capabilityLoaded: true,
        capability: capability,
      );
      check(show).isTrue();
    });

    test('hides section for student with none capability', () {
      const capability = TeacherCapability(state: TeacherCapabilityState.none);
      final show = SettingsTeachingVisibility.shouldShowSection(
        capabilityLoaded: true,
        capability: capability,
      );
      check(show).isFalse();
    });

    test('hides apply entry for pending application', () {
      const capability = TeacherCapability(
        state: TeacherCapabilityState.pending,
      );
      final show = SettingsTeachingVisibility.shouldShowSection(
        capabilityLoaded: true,
        capability: capability,
      );
      check(show).isFalse();
    });

    test('fails closed while capability unresolved', () {
      final show = SettingsTeachingVisibility.shouldShowSection(
        capabilityLoaded: false,
        capability: null,
      );
      check(show).isFalse();
    });
  });
}
