import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

void main() {
  group('TeacherApplicationAccessResolver', () {
    const policyAll = TeacherApplicationAccessPolicy(
      mode: TeacherApplicationAccessMode.all,
    );
    const policyNone = TeacherApplicationAccessPolicy(
      mode: TeacherApplicationAccessMode.none,
    );

    test('user override true allows regardless of policy', () {
      final allowed = TeacherApplicationAccessResolver.resolve(
        policy: policyNone,
        context: const TeacherApplicationAccessContext(
          userId: 'u1',
          userOverride: true,
        ),
      );
      check(allowed).isTrue();
    });

    test('user override false denies regardless of policy', () {
      final allowed = TeacherApplicationAccessResolver.resolve(
        policy: policyAll,
        context: const TeacherApplicationAccessContext(
          userId: 'u1',
          userOverride: false,
        ),
      );
      check(allowed).isFalse();
    });

    test('allowlist mode matches user id only', () {
      final allowed = TeacherApplicationAccessResolver.resolve(
        policy: const TeacherApplicationAccessPolicy(
          mode: TeacherApplicationAccessMode.allowlist,
          allowlistUserIds: ['u2'],
        ),
        context: const TeacherApplicationAccessContext(userId: 'u1'),
      );
      check(allowed).isFalse();
    });

    test('rules mode matches country code', () {
      final allowed = TeacherApplicationAccessResolver.resolve(
        policy: const TeacherApplicationAccessPolicy(
          mode: TeacherApplicationAccessMode.rules,
          rules: TeacherApplicationAccessRules(countryCodes: ['EG']),
        ),
        context: const TeacherApplicationAccessContext(
          userId: 'u1',
          userCountryCode: 'EG',
        ),
      );
      check(allowed).isTrue();
    });

    test('rules mode fails closed when no rule matches', () {
      final allowed = TeacherApplicationAccessResolver.resolve(
        policy: const TeacherApplicationAccessPolicy(
          mode: TeacherApplicationAccessMode.rules,
          rules: TeacherApplicationAccessRules(emails: ['a@b.com']),
        ),
        context: const TeacherApplicationAccessContext(
          userId: 'u1',
          userEmail: 'other@b.com',
        ),
      );
      check(allowed).isFalse();
    });
  });
}
