import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/data/repositories/user_repository_impl.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';

void main() {
  late UserRepositoryImpl userRepository;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userRepository = UserRepositoryImpl(fakeFirestore);
  });

  group('UserRepositoryImpl', () {
    final tUser = UserEntity(
      id: '123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'http://example.com/photo.jpg',
      createdAt: DateTime.now(),
    );

    test('saveUserData should save user data to firestore', () async {
      // Act
      await userRepository.saveUserData(tUser);

      // Assert
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await fakeFirestore.collection('users').doc(tUser.id).get();
      expect(docSnapshot.exists, true);
      expect(docSnapshot.data()!['email'], tUser.email);
      expect(docSnapshot.data()!['displayName'], tUser.displayName);
      expect(docSnapshot.data()!['photoUrl'], tUser.photoUrl);
      expect(docSnapshot.data()!['lastSignInTime'], isNotNull);
    });

    test('saveUserData should merge with existing data', () async {
      // Arrange
      await fakeFirestore.collection('users').doc(tUser.id).set({
        'email': 'old@example.com',
        'existingField': 'value',
      });

      // Act
      await userRepository.saveUserData(tUser);

      // Assert
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await fakeFirestore.collection('users').doc(tUser.id).get();
      expect(docSnapshot.data()!['email'], tUser.email);
      expect(docSnapshot.data()!['existingField'], 'value');
    });

    test(
      'saveDeviceToken should save token to fcm_tokens sub-collection',
      () async {
        // Act
        await userRepository.saveDeviceToken('user_123', 'token_abc');

        // Assert
        final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
            await fakeFirestore
                .collection('users')
                .doc('user_123')
                .collection('fcm_tokens')
                .doc('token_abc')
                .get();
        expect(docSnapshot.exists, true);
        expect(docSnapshot.data()!['token'], 'token_abc');
        expect(
          docSnapshot.data()!['platform'],
          Platform.isAndroid ? 'android' : 'ios',
        );
      },
    );
  });
}
