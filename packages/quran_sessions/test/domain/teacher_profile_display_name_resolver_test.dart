import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/teacher_profile_display_name_resolver.dart';

void main() {
  group('TeacherProfileDisplayNameResolver', () {
    test('prefers application display name over user display name', () {
      check(
        TeacherProfileDisplayNameResolver.resolve(
          userDisplayName: 'Auth Name',
          applicationDisplayName: 'Application Name',
        ),
      ).equals('Application Name');
    });

    test('falls back to user display name when application name missing', () {
      check(
        TeacherProfileDisplayNameResolver.resolve(
          userDisplayName: 'Auth Name',
        ),
      ).equals('Auth Name');
    });

    test('returns empty string instead of placeholder fallback', () {
      check(
        TeacherProfileDisplayNameResolver.resolve(
          userDisplayName: '   ',
          applicationDisplayName: '',
        ),
      ).equals('');
    });

    test('resolveStored trims without placeholder backfill', () {
      check(
        TeacherProfileDisplayNameResolver.resolveStored(
          displayName: '  Ustad Ahmad  ',
        ),
      ).equals('Ustad Ahmad');
    });

    test('bio is not used as display name source', () {
      check(
        TeacherProfileDisplayNameResolver.resolve(
          applicationDisplayName: null,
          userDisplayName: null,
        ),
      ).equals('');
    });
  });
}
