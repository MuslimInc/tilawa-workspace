import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  const teacherId = 'teacher_1';
  final windowFrom = DateTime.utc(2026, 1, 10);
  final windowTo = DateTime.utc(2026, 1, 17);
  final start = DateTime.utc(2026, 1, 10, 7, 0);

  group('collectBookedStartsFromSlotLocks', () {
    test('includes hard locks inside the window', () {
      final booked = collectBookedStartsFromSlotLocks(
        [
          SlotLockSnapshot(
            slotId: GeneratedSlot.deterministicId(teacherId, start),
            teacherId: teacherId,
            lockType: 'hard',
          ),
        ],
        teacherProfileId: teacherId,
        windowStart: windowFrom,
        windowEnd: windowTo,
        now: DateTime.utc(2026, 1, 9),
      );

      check(booked.length).equals(1);
      check(
        booked.first.millisecondsSinceEpoch,
      ).equals(start.millisecondsSinceEpoch);
    });

    test('ignores expired soft locks', () {
      final booked = collectBookedStartsFromSlotLocks(
        [
          SlotLockSnapshot(
            slotId: GeneratedSlot.deterministicId(teacherId, start),
            teacherId: teacherId,
            lockType: 'soft',
            expiresAt: DateTime.utc(2026, 1, 9, 12, 0),
          ),
        ],
        teacherProfileId: teacherId,
        windowStart: windowFrom,
        windowEnd: windowTo,
        now: DateTime.utc(2026, 1, 9, 12, 1),
      );

      check(booked).isEmpty();
    });

    test('keeps active soft locks', () {
      final booked = collectBookedStartsFromSlotLocks(
        [
          SlotLockSnapshot(
            slotId: GeneratedSlot.deterministicId(teacherId, start),
            teacherId: teacherId,
            lockType: 'soft',
            expiresAt: DateTime.utc(2026, 1, 9, 12, 30),
          ),
        ],
        teacherProfileId: teacherId,
        windowStart: windowFrom,
        windowEnd: windowTo,
        now: DateTime.utc(2026, 1, 9, 12, 0),
      );

      check(booked.length).equals(1);
      check(
        booked.first.millisecondsSinceEpoch,
      ).equals(start.millisecondsSinceEpoch);
    });

    test('includes legacy owner user id locks', () {
      const profileId = 'application_abc';
      const legacyUserId = 'firebase_uid_xyz';
      final booked = collectBookedStartsFromSlotLocks(
        [
          SlotLockSnapshot(
            slotId: GeneratedSlot.deterministicId(legacyUserId, start),
            teacherId: legacyUserId,
            lockType: 'hard',
          ),
        ],
        teacherProfileId: profileId,
        alternateTeacherIds: const [legacyUserId],
        windowStart: windowFrom,
        windowEnd: windowTo,
        now: DateTime.utc(2026, 1, 9),
      );

      check(booked.length).equals(1);
    });
  });
}
