import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_paths.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_teacher_profile_repository.dart';

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
}
