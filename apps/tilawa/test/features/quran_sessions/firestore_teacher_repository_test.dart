import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_teacher_application_repository.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_teacher_repository.dart';

void main() {
  group('FirestoreTeacherApplicationDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreTeacherApplicationDataSource dataSource;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      dataSource = FirestoreTeacherApplicationDataSource(firestore);
    });

    test('persists publicDisplayName on draft save', () async {
      final draft = TeacherApplicationDto(
        id: 'app_1',
        userId: 'uid_owner',
        status: 'draft',
        publicDisplayName: 'Ustad Ahmad',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 2),
      );

      await dataSource.saveDraft(draft);

      final doc = await firestore
          .collection(FirestoreQuranSessionsPaths.teacherApplications)
          .doc('app_1')
          .get();
      check(doc.data()!['publicDisplayName']).equals('Ustad Ahmad');
    });
  });

  group('FirestoreTeacherDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreTeacherDataSource dataSource;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      dataSource = FirestoreTeacherDataSource(firestore);
    });

    Future<void> seedProfile({
      required String id,
      required String displayName,
      required bool isPubliclyVisible,
      String profileCompleteness = 'complete',
      List<String> specializations = const ['tajweed'],
      List<String> languages = const ['ar'],
    }) async {
      await firestore
          .collection(FirestoreQuranSessionsPaths.teacherProfiles)
          .doc(id)
          .set({
            'userId': 'user_$id',
            'displayName': displayName,
            'publicBio': 'Bio for $displayName',
            'verificationStatus': 'verified',
            'teachingLanguages': languages,
            'specializations': specializations,
            'averageRating': 0,
            'reviewCount': 0,
            'isActive': true,
            'profileCompleteness': profileCompleteness,
            'isPubliclyVisible': isPubliclyVisible,
            'createdAt': Timestamp.fromDate(DateTime.utc(2024, 1, 1)),
            'updatedAt': Timestamp.fromDate(DateTime.utc(2024, 1, 2)),
          });
    }

    test('excludes incomplete profiles from teacher list query', () async {
      await seedProfile(
        id: 'visible_teacher',
        displayName: 'Visible Teacher',
        isPubliclyVisible: true,
      );
      await seedProfile(
        id: 'hidden_teacher',
        displayName: 'Hidden Teacher',
        isPubliclyVisible: false,
        profileCompleteness: 'incomplete',
      );

      final page = await dataSource.getTeachers();

      check(
        page.teachers.map((t) => t.id).toList(),
      ).deepEquals(['visible_teacher']);
    });

    test('includes approved complete teachers in list query', () async {
      await seedProfile(
        id: 'complete_teacher',
        displayName: 'Complete Teacher',
        isPubliclyVisible: true,
      );

      final page = await dataSource.getTeachers();

      check(page.teachers).length.equals(1);
      check(page.teachers.first.displayName).equals('Complete Teacher');
    });

    test(
      'filters specialization via server array-contains query',
      () async {
        await seedProfile(
          id: 'tajweed_teacher',
          displayName: 'Tajweed Teacher',
          isPubliclyVisible: true,
          specializations: ['tajweed'],
        );
        await seedProfile(
          id: 'hifz_teacher',
          displayName: 'Hifz Teacher',
          isPubliclyVisible: true,
          specializations: ['hifz'],
        );

        final page = await dataSource.getTeachers(specialization: 'hifz');

        check(
          page.teachers.map((t) => t.id).toList(),
        ).deepEquals(['hifz_teacher']);
      },
    );

    test('filters language via server array-contains query', () async {
      await seedProfile(
        id: 'arabic_teacher',
        displayName: 'Arabic Teacher',
        isPubliclyVisible: true,
        languages: ['ar'],
      );
      await seedProfile(
        id: 'english_teacher',
        displayName: 'English Teacher',
        isPubliclyVisible: true,
        languages: ['en'],
      );

      final page = await dataSource.getTeachers(language: 'ar');

      check(
        page.teachers.map((t) => t.id).toList(),
      ).deepEquals(['arabic_teacher']);
    });
  });
}
