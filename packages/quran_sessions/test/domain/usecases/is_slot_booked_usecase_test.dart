import 'package:dartz_plus/dartz_plus.dart';
import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';

void main() {
  late FakeBookedSlotLockRepository locks;
  late IsSlotBookedUseCase useCase;

  setUp(() {
    locks = FakeBookedSlotLockRepository();
    useCase = IsSlotBookedUseCase(locks);
  });

  test('returns false when no lock exists for slot id', () async {
    final result = await useCase('teacher1_20260624T1000Z');
    check(result).equals(const Right(false));
  });

  test('returns true when hard lock exists for slot id', () async {
    locks.seedHardLock(
      teacherId: 'teacher1',
      startUtc: DateTime.utc(2026, 6, 24, 10),
    );
    final result = await useCase(
      GeneratedSlot.deterministicId(
        'teacher1',
        DateTime.utc(2026, 6, 24, 10),
      ),
    );
    check(result).equals(const Right(true));
  });
}
