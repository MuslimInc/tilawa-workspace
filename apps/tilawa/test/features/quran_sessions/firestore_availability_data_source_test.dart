import 'package:checks/checks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_availability_repository.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreAvailabilityDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreAvailabilityDataSource(firestore);
  });

  test(
    'withdrawSlot deletes teacher-scoped availability doc without scan',
    () async {
      const teacherId = 'teacher1';
      const slotId = 'slot_a';
      await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .collection(FirestoreQuranSessionsPaths.availability)
          .doc(slotId)
          .set({
            'teacherId': teacherId,
            'startsAt': DateTime.utc(2026, 6, 24, 10),
            'endsAt': DateTime.utc(2026, 6, 24, 10, 30),
            'isBooked': false,
          });

      await dataSource.withdrawSlot(teacherId, slotId);

      final after = await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .collection(FirestoreQuranSessionsPaths.availability)
          .doc(slotId)
          .get();
      check(after.exists).isFalse();
    },
  );

  test('withdrawSlot rejects booked slot', () async {
    const teacherId = 'teacher1';
    const slotId = 'slot_b';
    await firestore
        .collection(FirestoreQuranSessionsPaths.teacherProfiles)
        .doc(teacherId)
        .collection(FirestoreQuranSessionsPaths.availability)
        .doc(slotId)
        .set({
          'teacherId': teacherId,
          'isBooked': true,
          'startsAt': DateTime.utc(2026, 6, 24, 11),
          'endsAt': DateTime.utc(2026, 6, 24, 11, 30),
        });

    await expectLater(
      dataSource.withdrawSlot(teacherId, slotId),
      throwsA(isA<ConflictException>()),
    );
  });

  test('withdrawSlot throws not found for wrong teacher path', () async {
    await expectLater(
      dataSource.withdrawSlot('other_teacher', 'missing_slot'),
      throwsA(isA<NotFoundException>()),
    );
  });
}
