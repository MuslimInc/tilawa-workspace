import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fixtures.dart' show makeSession;

void main() {
  group('QuranSession time classification', () {
    final now = DateTime.utc(2026, 6, 25, 12, 0);
    final startsAt = DateTime.utc(2026, 6, 25, 13, 0);
    final endsAt = DateTime.utc(2026, 6, 25, 13, 30);

    test('phaseAt: before startsAt → upcoming', () {
      final session = makeSession(startsAt: startsAt, endsAt: endsAt);
      check(session.phaseAt(now)).equals(QuranSessionTimePhase.upcoming);
    });

    test('phaseAt: between startsAt and endsAt → ongoing', () {
      final session = makeSession(startsAt: startsAt, endsAt: endsAt);
      check(session.phaseAt(startsAt)).equals(QuranSessionTimePhase.ongoing);
      check(
        session.phaseAt(endsAt.subtract(const Duration(minutes: 1))),
      ).equals(QuranSessionTimePhase.ongoing);
    });

    test('phaseAt: at endsAt → ongoing; after endsAt → past', () {
      final session = makeSession(startsAt: startsAt, endsAt: endsAt);
      check(session.phaseAt(endsAt)).equals(QuranSessionTimePhase.ongoing);
      check(
        session.phaseAt(endsAt.add(const Duration(minutes: 1))),
      ).equals(QuranSessionTimePhase.past);
    });

    test('ongoing session is not classified as upcoming or past', () {
      final ongoing = makeSession(
        startsAt: DateTime.now().subtract(const Duration(minutes: 5)),
        endsAt: DateTime.now().add(const Duration(minutes: 25)),
      );
      check(ongoing.isUpcoming).isFalse();
      check(ongoing.isOngoing).isTrue();
      check(ongoing.isPast).isFalse();
    });

    test('ended session is classified as past', () {
      final ended = makeSession(
        startsAt: DateTime.now().subtract(const Duration(hours: 2)),
        endsAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      check(ended.isUpcoming).isFalse();
      check(ended.isOngoing).isFalse();
      check(ended.isPast).isTrue();
    });

    test('future session is classified as upcoming', () {
      final future = makeSession(
        startsAt: DateTime.now().add(const Duration(days: 1)),
        endsAt: DateTime.now().add(const Duration(days: 1, hours: 1)),
      );
      check(future.isUpcoming).isTrue();
      check(future.isOngoing).isFalse();
      check(future.isPast).isFalse();
    });
  });
}
