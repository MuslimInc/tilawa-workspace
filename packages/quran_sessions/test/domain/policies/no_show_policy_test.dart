import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('NoShowPolicy', () {
    final startsAt = DateTime.utc(2026, 1, 1, 10);

    test('T-N01 teacher no-show classification', () {
      final policy = NoShowPolicy(
        now: () => startsAt.add(const Duration(minutes: 20)),
      );
      final status = policy.classify(
        startsAt: startsAt,
        teacherJoined: false,
        studentJoined: true,
      );
      check(status).equals(SessionLifecycleStatus.teacherNoShow);
    });

    test('T-N02 student no-show classification', () {
      final policy = NoShowPolicy(
        now: () => startsAt.add(const Duration(minutes: 20)),
      );
      final status = policy.classify(
        startsAt: startsAt,
        teacherJoined: true,
        studentJoined: false,
      );
      check(status).equals(SessionLifecycleStatus.studentNoShow);
    });

    test('T-N03 both no-show classification', () {
      final policy = NoShowPolicy(
        now: () => startsAt.add(const Duration(minutes: 20)),
      );
      final status = policy.classify(
        startsAt: startsAt,
        teacherJoined: false,
        studentJoined: false,
      );
      check(status).equals(SessionLifecycleStatus.bothNoShow);
    });
  });
}
