import 'package:firebase_auth/firebase_auth.dart';
import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/data/repositories/user_repository_impl.dart';
import 'package:tilawa/features/auth/domain/entities/email_registration_draft.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';

import 'user_repository_impl_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User])
void main() {
  late UserRepositoryImpl userRepository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('123');
    userRepository = UserRepositoryImpl(fakeFirestore, mockFirebaseAuth);
  });

  group('UserRepositoryImpl', () {
    final tUser = UserEntity(
      id: '123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'http://example.com/photo.jpg',
      createdAt: DateTime.now(),
    );

    test('saveUserData uses auth uid as document id', () async {
      await userRepository.saveUserData(tUser);

      final docSnapshot = await fakeFirestore
          .collection('users')
          .doc(tUser.id)
          .get();
      check(docSnapshot.exists).isTrue();
      check(docSnapshot.id).equals(tUser.id);
    });

    test('saveUserData should save user data to firestore', () async {
      await userRepository.saveUserData(tUser);

      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await fakeFirestore.collection('users').doc(tUser.id).get();
      expect(docSnapshot.exists, true);
      expect(docSnapshot.data()!['email'], tUser.email);
      expect(docSnapshot.data()!['displayName'], tUser.displayName);
      expect(docSnapshot.data()!['photoUrl'], tUser.photoUrl);
      expect(docSnapshot.data()!['lastSignInTime'], isNotNull);
    });

    test('saveUserData should merge with existing data', () async {
      await fakeFirestore.collection('users').doc(tUser.id).set({
        'email': 'old@example.com',
        'existingField': 'value',
      });

      await userRepository.saveUserData(tUser);

      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await fakeFirestore.collection('users').doc(tUser.id).get();
      expect(docSnapshot.data()!['email'], tUser.email);
      expect(docSnapshot.data()!['existingField'], 'value');
    });

    test(
      'saveCompleteEmailRegistration writes profileCompleted true',
      () async {
        final EmailRegistrationDraft draft = EmailRegistrationDraft(
          displayName: 'Complete User',
          gender: 'male',
          dateOfBirth: DateTime(1990, 5, 1),
          countryCode: 'EG',
          countryName: 'Egypt',
          cityId: 'cairo',
          cityName: 'Cairo',
          currencyCode: 'EGP',
          timezone: 'Africa/Cairo',
          preferredLanguageCode: 'ar',
          learningGoals: <String>['recitation'],
        );

        await userRepository.saveCompleteEmailRegistration(
          user: tUser,
          draft: draft,
        );

        final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
            await fakeFirestore.collection('users').doc(tUser.id).get();
        final Map<String, dynamic>? profile =
            docSnapshot.data()?['quranSessionsProfile']
                as Map<String, dynamic>?;

        expect(docSnapshot.data()?['authProvider'], 'emailPassword');
        expect(profile?['profileCompleted'], true);
        expect(profile?['gender'], 'male');
        expect(profile?['cityId'], 'cairo');
      },
    );

    test(
      'ensureQuranSessionsProfileShell creates incomplete shell once',
      () async {
        await userRepository.ensureQuranSessionsProfileShell(tUser.id);

        final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
            await fakeFirestore.collection('users').doc(tUser.id).get();
        final Map<String, dynamic>? profile =
            docSnapshot.data()?['quranSessionsProfile']
                as Map<String, dynamic>?;
        expect(profile?['profileCompleted'], false);
        expect(profile?['role'], 'student');

        await userRepository.ensureQuranSessionsProfileShell(tUser.id);
        final DocumentSnapshot<Map<String, dynamic>> again = await fakeFirestore
            .collection('users')
            .doc(tUser.id)
            .get();
        expect(again.data()?['quranSessionsProfile'], profile);
      },
    );

    test(
      'syncLanguagePreference writes languageCode for signed-in user',
      () async {
        await userRepository.syncLanguagePreference('ar');

        final docSnapshot = await fakeFirestore
            .collection('users')
            .doc('123')
            .get();
        expect(docSnapshot.data()!['languageCode'], 'ar');
      },
    );

    test('syncLanguagePreference no-ops when signed out', () async {
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      await userRepository.syncLanguagePreference('ar');

      final docs = await fakeFirestore.collection('users').get();
      expect(docs.docs, isEmpty);
    });

    test(
      'deleteUserData removes user doc and legacy fcm token subcollection',
      () async {
        await userRepository.saveUserData(tUser);
        await fakeFirestore
            .collection('users')
            .doc(tUser.id)
            .collection('fcm_tokens')
            .doc('token_abc')
            .set({'token': 'token_abc'});

        await userRepository.deleteUserData(tUser.id);

        final userDoc = await fakeFirestore
            .collection('users')
            .doc(tUser.id)
            .get();
        final tokenDoc = await fakeFirestore
            .collection('users')
            .doc(tUser.id)
            .collection('fcm_tokens')
            .doc('token_abc')
            .get();

        expect(userDoc.exists, false);
        expect(tokenDoc.exists, false);
      },
    );
  });
}
