import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa/features/auth/domain/services/session_epoch_provider.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_booking_repository.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_market_config_repository.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_user_profile_repository.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_teacher_application_repository.dart';

class _FakePayloadBuilder extends CallableSessionPayloadBuilder {
  _FakePayloadBuilder() : super(_FakeEpochProvider());
}

class _FakeEpochProvider implements SessionEpochProvider {
  @override
  Future<int> getSessionEpoch() async => 0;
}

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
        const authUid = 'auth_uid_from_provider';
        final dto = await dataSource.getOrCreateProfile(authUid);

        check(dto.userId).equals(authUid);
        check(dto.role).equals('student');
        check(dto.gender).isNull();

        final doc = await firestore
            .collection(FirestoreQuranSessionsPaths.users)
            .doc(authUid)
            .get();
        check(doc.exists).isTrue();
        check(doc.id).equals(authUid);
        check(
          doc.data()![FirestoreQuranSessionsPaths.quranSessionsProfileField],
        ).isNotNull();
      },
    );

    test('login sync merge does not create duplicate user docs', () async {
      const authUid = 'auth_uid_merge';
      await dataSource.getOrCreateProfile(authUid);
      await dataSource.getOrCreateProfile(authUid);

      final snapshot = await firestore
          .collection(FirestoreQuranSessionsPaths.users)
          .get();
      check(snapshot.docs.length).equals(1);
      check(snapshot.docs.single.id).equals(authUid);
    });

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
    test(
      'delegates booking mutations to callable functions',
      () async {
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
          FirebaseFunctions.instanceFor(region: 'us-central1'),
          _FakePayloadBuilder(),
        );

        expect(
          () => dataSource.createBooking(
            teacherId: teacherId,
            slotId: slotId,
            requestedCallTypeId: 'externalMeeting',
          ),
          throwsA(isA<HttpException>()),
        );
      },
      skip: 'Create/cancel/reschedule now validated in Cloud Functions tests.',
    );
  });

  group('FirestoreMarketConfigDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreMarketConfigDataSource dataSource;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      dataSource = FirestoreMarketConfigDataSource(firestore);
      await FirestoreMarketConfigSeeder(firestore).seedDefaultCatalog();
    });

    test('getSupportedCountries returns enabled countries', () async {
      final countries = await dataSource.getSupportedCountries();

      // The seeded catalog defines EG/SA/AE, but only EG is enabled for this
      // release — the data source must filter to enabled markets.
      check(countries.map((c) => c.countryCode).toList()).deepEquals(['EG']);
    });

    test('getCitiesByCountryCode returns enabled cities for EG', () async {
      final cities = await dataSource.getCitiesByCountryCode('EG');

      check(cities.length).equals(10);
      check(cities.first.cityId).equals('cairo');
    });

    test('getMarketConfig loads country doc by code', () async {
      final config = await dataSource.getMarketConfig('EG');

      check(config.countryCode).equals('EG');
      check(config.cities).isNotEmpty();
    });

    test('getCityConfig loads city doc by deterministic id', () async {
      final city = await dataSource.getCityConfig('EG', 'cairo');

      check(city.cityId).equals('cairo');
      check(city.cityName).equals('القاهرة');
    });

    test('disabled city is excluded from list query', () async {
      await firestore
          .collection(FirestoreQuranSessionsPaths.marketConfigs)
          .doc('EG')
          .collection(FirestoreQuranSessionsPaths.cities)
          .doc('disabled_city')
          .set({
            'cityId': 'disabled_city',
            'cityNameAr': 'مدينة معطلة',
            'isEnabled': false,
            'sortOrder': 999,
          });

      final cities = await dataSource.getCitiesByCountryCode('EG');

      check(cities.any((c) => c.cityId == 'disabled_city')).isFalse();
    });

    test('missing country throws NotFoundException', () {
      expect(
        () => dataSource.getCitiesByCountryCode('XX'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('missing city throws NotFoundException', () {
      expect(
        () => dataSource.getCityConfig('EG', 'unknown'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('FirestoreTeacherApplicationDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreTeacherApplicationDataSource dataSource;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      dataSource = FirestoreTeacherApplicationDataSource(firestore);
      await firestore
          .collection(FirestoreQuranSessionsPaths.teacherApplications)
          .doc('app_owner')
          .set({
            'userId': 'uid_owner',
            'status': 'pending',
            'teachingLanguages': <String>[],
            'specializations': <String>[],
            'createdAt': Timestamp.fromDate(DateTime.utc(2024, 1, 1)),
            'updatedAt': Timestamp.fromDate(DateTime.utc(2024, 1, 2)),
          });
    });

    test('loads application by userId for owner lookup query', () async {
      final dto = await dataSource.getByUserId('uid_owner');

      check(dto.userId).equals('uid_owner');
      check(dto.status).equals('pending');
    });
  });
}
