import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  const validator = BookingIntegrityValidator();
  final now = DateTime.utc(2026, 1, 1, 10);

  BookingIntegritySnapshot snapshot({
    bool slotAvailable = true,
    bool teacherActive = true,
    bool studentActive = true,
    bool marketEnabled = true,
    DateTime? startsAt,
  }) {
    return BookingIntegritySnapshot(
      slotAvailable: slotAvailable,
      teacherActive: teacherActive,
      studentActive: studentActive,
      marketEnabled: marketEnabled,
      startsAt: startsAt ?? now.add(const Duration(hours: 48)),
      minNotice: const Duration(hours: 1),
      maxAdvanceHorizon: const Duration(days: 60),
      now: () => now,
    );
  }

  group('BookingIntegrityValidator', () {
    test('T-B01 happy path passes', () {
      final result = validator.validate(snapshot());
      check(result.isRight()).isTrue();
    });

    test('T-B02 slot unavailable fails', () {
      final result = validator.validate(snapshot(slotAvailable: false));
      result.fold(
        (failure) => check(failure).isA<SlotUnavailableFailure>(),
        (_) => fail('expected Left'),
      );
    });

    test('T-B04 teacher suspended fails', () {
      final result = validator.validate(snapshot(teacherActive: false));
      check(result.isLeft()).isTrue();
    });

    test('T-B05 student suspended fails', () {
      final result = validator.validate(snapshot(studentActive: false));
      check(result.isLeft()).isTrue();
    });

    test('T-B07 below min notice fails', () {
      final result = validator.validate(
        snapshot(startsAt: now.add(const Duration(minutes: 30))),
      );
      check(result.isLeft()).isTrue();
    });

    test('T-B08 beyond horizon fails', () {
      final result = validator.validate(
        snapshot(startsAt: now.add(const Duration(days: 120))),
      );
      check(result.isLeft()).isTrue();
    });
  });
}
