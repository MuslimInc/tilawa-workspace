import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_teacher_profile_repository.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';
import 'package:tilawa_core/services/performance_trace.dart';

void main() {
  group('FirestoreTeacherProfileDataSource.updatePublicProfile', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreTeacherProfileDataSource dataSource;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      dataSource = FirestoreTeacherProfileDataSource(firestore);
      await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc('app_1')
          .set({
            'userId': 'uid_teacher',
            'displayName': '',
            'publicBio': '',
            'verificationStatus': 'verified',
            'teachingLanguages': <String>[],
            'specializations': <String>[],
            'averageRating': 0,
            'reviewCount': 0,
            'isActive': true,
            'profileCompleteness': 'incomplete',
            'isPubliclyVisible': false,
            'createdAt': Timestamp.fromDate(DateTime.utc(2024, 1, 1)),
            'updatedAt': Timestamp.fromDate(DateTime.utc(2024, 1, 2)),
          });
    });

    test('writes only client-allowed public fields', () async {
      await dataSource.updatePublicProfile(
        TeacherProfileDto(
          id: 'app_1',
          userId: 'uid_teacher',
          displayName: 'Ustad Ahmad',
          publicBio: 'Tajweed specialist with 10 years experience.',
          teachingLanguages: const ['ar', 'en'],
          specializations: const ['tajweed'],
          verificationStatus: 'verified',
          averageRating: 0,
          reviewCount: 0,
          isActive: true,
          profileCompleteness: 'complete',
          isPubliclyVisible: true,
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 1, 2),
        ),
      );

      final doc = await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc('app_1')
          .get();
      final data = doc.data()!;

      check(data['displayName']).equals('Ustad Ahmad');
      check(data['publicBio']).equals(
        'Tajweed specialist with 10 years experience.',
      );
      check(
        data['teachingLanguages'] as List<dynamic>,
      ).deepEquals(['ar', 'en']);
      check(data['specializations'] as List<dynamic>).deepEquals(['tajweed']);
      check(data['profileCompleteness']).equals('incomplete');
      check(data['isPubliclyVisible']).equals(false);
      check(data['verificationStatus']).equals('verified');
    });

    test('writes externalMeetingUrl when provided', () async {
      await dataSource.updatePublicProfile(
        TeacherProfileDto(
          id: 'app_1',
          userId: 'uid_teacher',
          displayName: 'Ustad Ahmad',
          publicBio: 'Tajweed specialist.',
          teachingLanguages: const ['ar'],
          specializations: const ['tajweed'],
          verificationStatus: 'verified',
          averageRating: 0,
          reviewCount: 0,
          isActive: true,
          profileCompleteness: 'complete',
          isPubliclyVisible: true,
          externalMeetingUrl: 'https://meet.google.com/room-1',
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 1, 2),
        ),
      );

      final doc = await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc('app_1')
          .get();
      check(
        doc.data()!['externalMeetingUrl'],
      ).equals('https://meet.google.com/room-1');
    });
  });

  group('FirestoreTeacherProfileDataSource.caching', () {
    late FakeFirebaseFirestore firestore;
    late FakePerformanceMonitoringService perf;
    late FirestoreTeacherProfileDataSource dataSource;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      perf = FakePerformanceMonitoringService();
      dataSource = FirestoreTeacherProfileDataSource(firestore, perf);

      await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc('app_1')
          .set({
            'userId': 'uid_teacher',
            'displayName': 'Ahmad',
            'verificationStatus': 'verified',
            'teachingLanguages': <String>[],
            'specializations': <String>[],
            'averageRating': 0.0,
            'reviewCount': 0,
            'isActive': true,
            'profileCompleteness': 'incomplete',
            'isPubliclyVisible': false,
            'createdAt': Timestamp.fromDate(DateTime.utc(2024, 1, 1)),
            'updatedAt': Timestamp.fromDate(DateTime.utc(2024, 1, 2)),
          });
    });

    test('caches by ID and User ID concurrently', () async {
      final p1 = await dataSource.getById('app_1');
      final p2 = await dataSource.getById('app_1');
      check(p1.id).equals(p2.id);
      check(perf.traceCounts['firestore_getTeacherProfileById']).equals(1);

      // Verify that fetching by ID pre-populated the userId cache
      final p3 = await dataSource.getByUserId('uid_teacher');
      check(p3.id).equals('app_1');
      check(perf.traceCounts['firestore_getTeacherProfileByUserId']).isNull();
    });

    test('caches by User ID and pre-populates ID cache', () async {
      final p1 = await dataSource.getByUserId('uid_teacher');
      final p2 = await dataSource.getByUserId('uid_teacher');
      check(p1.id).equals(p2.id);
      check(perf.traceCounts['firestore_getTeacherProfileByUserId']).equals(1);

      // Verify that fetching by userId pre-populated the ID cache
      final p3 = await dataSource.getById('app_1');
      check(p3.userId).equals('uid_teacher');
      check(perf.traceCounts['firestore_getTeacherProfileById']).isNull();
    });

    test('invalidates cache on update operations', () async {
      await dataSource.getById('app_1');
      check(perf.traceCounts['firestore_getTeacherProfileById']).equals(1);

      // Perform an update
      await dataSource.updatePublicProfile(
        TeacherProfileDto(
          id: 'app_1',
          userId: 'uid_teacher',
          displayName: 'Ahmad Updated',
          verificationStatus: 'verified',
          teachingLanguages: const [],
          specializations: const [],
          averageRating: 0.0,
          reviewCount: 0,
          isActive: true,
          profileCompleteness: 'incomplete',
          isPubliclyVisible: false,
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 1, 2),
        ),
      );

      // Next read should fetch from Firestore again
      await dataSource.getById('app_1');
      check(perf.traceCounts['firestore_getTeacherProfileById']).equals(2);
    });

    test(
      'uses SharedPreferences to perform direct document get instead of collection query',
      () async {
        final backing = <String, String>{
          'tp_id_mapping_uid_teacher': 'app_1',
        };
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getString(any())).thenAnswer((invocation) async {
          final key = invocation.positionalArguments[0] as String;
          return backing[key];
        });
        when(() => prefs.setString(any(), any())).thenAnswer((
          invocation,
        ) async {
          final key = invocation.positionalArguments[0] as String;
          final value = invocation.positionalArguments[1] as String;
          backing[key] = value;
        });
        when(() => prefs.remove(any())).thenAnswer((invocation) async {
          final key = invocation.positionalArguments[0] as String;
          backing.remove(key);
        });

        final customDataSource = FirestoreTeacherProfileDataSource(
          firestore,
          perf,
          prefs,
        );

        final profile = await customDataSource.getByUserId('uid_teacher');
        check(profile.id).equals('app_1');

        // The trace for collection query should not be called at all
        check(perf.traceCounts['firestore_getTeacherProfileByUserId']).isNull();
        // Instead, getById is called which starts firestore_getTeacherProfileById trace
        check(perf.traceCounts['firestore_getTeacherProfileById']).equals(1);
      },
    );

    test(
      'clears stale SharedPreferences mapping and falls back to collection query if document not found',
      () async {
        final backing = <String, String>{
          'tp_id_mapping_uid_teacher': 'stale_id',
        };
        final prefs = MockSharedPreferencesAsync();
        when(() => prefs.getString(any())).thenAnswer((invocation) async {
          final key = invocation.positionalArguments[0] as String;
          return backing[key];
        });
        when(() => prefs.setString(any(), any())).thenAnswer((
          invocation,
        ) async {
          final key = invocation.positionalArguments[0] as String;
          final value = invocation.positionalArguments[1] as String;
          backing[key] = value;
        });
        when(() => prefs.remove(any())).thenAnswer((invocation) async {
          final key = invocation.positionalArguments[0] as String;
          backing.remove(key);
        });

        final customDataSource = FirestoreTeacherProfileDataSource(
          firestore,
          perf,
          prefs,
        );

        // Fetching by User ID will attempt to points read 'stale_id' which throws NotFoundException.
        // It should clear stale_id from prefs and execute the query fallback which fetches 'app_1'.
        final profile = await customDataSource.getByUserId('uid_teacher');
        check(profile.id).equals('app_1');

        // Query trace runs once
        check(
          perf.traceCounts['firestore_getTeacherProfileByUserId'],
        ).equals(1);

        // Mapping should be updated in SharedPreferences to the new resolved ID
        check(backing['tp_id_mapping_uid_teacher']).equals('app_1');
      },
    );
  });
}

class FakePerformanceMonitoringService implements PerformanceMonitoringService {
  final Map<String, int> traceCounts = {};

  @override
  Future<T> traceOperation<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    traceCounts[name] = (traceCounts[name] ?? 0) + 1;
    return operation();
  }

  @override
  PerformanceTrace? startTrace(String name) => null;

  @override
  void setEnabled(bool enabled) {}
}

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}
