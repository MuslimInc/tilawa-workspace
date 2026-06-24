import 'package:checks/checks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_booked_slot_lock_data_source.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreBookedSlotLockDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreBookedSlotLockDataSource(firestore);
  });

  test('getLocksForTeacher returns locks in slotId window', () async {
    const teacherId = 'teacher1';
    final inWindow = GeneratedSlot.deterministicId(
      teacherId,
      DateTime.utc(2026, 6, 24, 10),
    );
    final outWindow = GeneratedSlot.deterministicId(
      teacherId,
      DateTime.utc(2026, 7, 24, 10),
    );
    final locks = firestore.collection(FirestoreQuranSessionsPaths.slotLocks);
    await locks.doc(inWindow).set({
      'slotId': inWindow,
      'teacherId': teacherId,
      'lockType': 'hard',
    });
    await locks.doc(outWindow).set({
      'slotId': outWindow,
      'teacherId': teacherId,
      'lockType': 'hard',
    });

    final result = await dataSource.getLocksForTeacher(
      teacherId,
      windowStart: DateTime.utc(2026, 6, 24),
      windowEnd: DateTime.utc(2026, 6, 25),
    );

    check(result).length.equals(1);
    check(result.single.slotId).equals(inWindow);
  });

  test('getLockBySlotId reads single lock document', () async {
    const slotId = 'teacher1_20260624T1000Z';
    await firestore
        .collection(FirestoreQuranSessionsPaths.slotLocks)
        .doc(slotId)
        .set({
          'slotId': slotId,
          'teacherId': 'teacher1',
          'lockType': 'hard',
        });

    final lock = await dataSource.getLockBySlotId(slotId);
    check(lock).isNotNull();
    check(lock!.slotId).equals(slotId);
  });
}
