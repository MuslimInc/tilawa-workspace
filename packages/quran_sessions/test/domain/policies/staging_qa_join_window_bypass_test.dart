import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('staging QA join window bypass', () {
    test('allows Maestro teacher and student uids on staging', () {
      check(
        isQaJoinWindowBypassEligible(
          userId: stagingQaTeacherUid,
          distribution: 'staging',
        ),
      ).isTrue();
      check(
        isQaJoinWindowBypassEligible(
          userId: stagingQaStudentUid,
          distribution: 'staging',
        ),
      ).isTrue();
    });

    test('rejects non-QA uid on staging', () {
      check(
        isQaJoinWindowBypassEligible(
          userId: 'student_random',
          distribution: 'staging',
        ),
      ).isFalse();
    });

    test('rejects QA uid on play_production', () {
      check(
        isQaJoinWindowBypassEligible(
          userId: stagingQaStudentUid,
          distribution: 'play_production',
        ),
      ).isFalse();
    });

    test('rejects QA uid on production distribution', () {
      check(
        isQaJoinWindowBypassEligible(
          userId: stagingQaStudentUid,
          distribution: 'production',
        ),
      ).isFalse();
    });
  });
}
