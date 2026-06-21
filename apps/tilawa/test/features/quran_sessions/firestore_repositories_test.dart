import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_booking_repository.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_user_profile_repository.dart';

class _FakeAuthSessionProvider implements AuthSessionProvider {
  _FakeAuthSessionProvider(this._uid);

  final String _uid;

  @override
  String? get currentUserId => _uid;

  @override
  Stream<String?> watchUserId() => Stream.value(_uid);
}

void main() {
  group('FirestoreUserProfileDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreUserProfileDataSource dataSource;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      dataSource = FirestoreUserProfileDataSource(firestore);
    });

    test(
      'creates quranSessionsProfile shell when user doc is missing',
      () async {
        final dto = await dataSource.getOrCreateProfile('uid_test');

        check(dto.userId).equals('uid_test');
        check(dto.role).equals('student');
        check(dto.gender).isNull();

        final doc = await firestore
            .collection(FirestoreQuranSessionsPaths.users)
            .doc('uid_test')
            .get();
        check(doc.exists).isTrue();
        check(
          doc.data()![FirestoreQuranSessionsPaths.quranSessionsProfileField],
        ).isNotNull();
      },
    );

    test('persists completed profile fields', () async {
      await dataSource.getOrCreateProfile('uid_test');
      final updated = await dataSource.updateProfile(
        UserProfileDto(
          userId: 'uid_test',
          role: 'student',
          accountStatus: 'active',
          gender: 'male',
          dateOfBirth: DateTime.utc(2000, 1, 1),
          countryCode: 'EG',
          countryName: 'مصر',
          cityId: 'cairo',
          cityName: 'القاهرة',
          currencyCode: 'EGP',
          timezone: 'Africa/Cairo',
        ),
      );

      check(updated.gender).equals('male');
      check(updated.countryCode).equals('EG');
    });
  });

  group('FirestoreBookingDataSource', () {
    test('prevents double booking in a transaction', () async {
      final firestore = FakeFirebaseFirestore();
      const teacherId = 'teacher_1';
      const slotId = 'slot_1';
      await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(teacherId)
          .collection(FirestoreQuranSessionsPaths.availability)
          .doc(slotId)
          .set({
            'startsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1, 10)),
            'endsAt': Timestamp.fromDate(DateTime.utc(2026, 7, 1, 11)),
            'isBooked': false,
          });

      final dataSource = FirestoreBookingDataSource(
        firestore,
        _FakeAuthSessionProvider('student_uid'),
      );

      await dataSource.createBooking(
        teacherId: teacherId,
        slotId: slotId,
        requestedCallTypeId: 'externalMeeting',
      );

      expect(
        () => dataSource.createBooking(
          teacherId: teacherId,
          slotId: slotId,
          requestedCallTypeId: 'externalMeeting',
        ),
        throwsA(isA<ConflictException>()),
      );
    });
  });
}
