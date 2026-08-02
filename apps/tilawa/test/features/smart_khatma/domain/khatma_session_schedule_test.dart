import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/smart_khatma/domain/entities/khatma_plan.dart';
import 'package:tilawa/features/smart_khatma/domain/entities/khatma_session.dart';

void main() {
  group('KhatmaSessionSchedule', () {
    test('slices plan into durationDays sessions', () {
      final plan = _plan(durationDays: 4, startPage: 1, targetPage: 40);
      final sessions = KhatmaSessionSchedule.build(plan);
      check(sessions.length).equals(4);
      check(sessions.first.startPage).equals(1);
      check(sessions.last.endPage).equals(40);
      check(
        sessions.fold<int>(0, (sum, s) => sum + s.pageCount),
      ).equals(40);
    });

    test('classifies previous current upcoming around assignment', () {
      final plan = _plan(
        durationDays: 4,
        startPage: 1,
        targetPage: 40,
        assignmentStartPage: 11,
        assignmentEndPage: 20,
      );
      check(KhatmaSessionSchedule.previousCount(plan)).equals(1);
      check(KhatmaSessionSchedule.upcomingCount(plan)).equals(2);
      final current = KhatmaSessionSchedule.build(
        plan,
      ).where((s) => s.kind == KhatmaSessionKind.current).single;
      check(current.startPage).equals(11);
      check(current.endPage).equals(20);
    });
  });
}

KhatmaPlan _plan({
  required int durationDays,
  required int startPage,
  required int targetPage,
  int? assignmentStartPage,
  int? assignmentEndPage,
}) {
  final now = DateTime(2026, 8, 2);
  return KhatmaPlan(
    id: 'test',
    createdAt: now,
    startDate: now,
    durationDays: durationDays,
    startPage: startPage,
    targetPage: targetPage,
    assignmentDate: now,
    assignmentStartPage: assignmentStartPage ?? startPage,
    assignmentEndPage:
        assignmentEndPage ??
        startPage + ((targetPage - startPage + 1) / durationDays).ceil() - 1,
  );
}
