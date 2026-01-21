import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/services/user_email_service.dart';

import 'user_email_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  late UserEmailServiceImpl userEmailService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    userEmailService = UserEmailServiceImpl(mockFirestore);
  });

  group('UserEmailServiceImpl', () {
    test('getUserEmails returns list of emails when users exist', () async {
      // Arrange
      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc3 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockDoc1.data()).thenReturn({'email': 'user1@example.com'});
      when(mockDoc2.data()).thenReturn({'email': 'user2@example.com'});
      when(mockDoc3.data()).thenReturn({'email': 'user3@example.com'});

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2, mockDoc3]);

      // Act
      final List<String> result = await userEmailService.getUserEmails();

      // Assert
      expect(result, [
        'user1@example.com',
        'user2@example.com',
        'user3@example.com',
      ]);
      verify(mockFirestore.collection('users')).called(1);
      verify(mockCollection.get()).called(1);
    });

    test('getUserEmails returns empty list when no users exist', () async {
      // Arrange
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      // Act
      final List<String> result = await userEmailService.getUserEmails();

      // Assert
      expect(result, isEmpty);
      verify(mockFirestore.collection('users')).called(1);
      verify(mockCollection.get()).called(1);
    });

    test('getUserEmails filters out null and empty emails', () async {
      // Arrange
      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc3 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc4 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockDoc1.data()).thenReturn({'email': 'valid@example.com'});
      when(mockDoc2.data()).thenReturn({'email': null});
      when(mockDoc3.data()).thenReturn({'email': ''});
      when(mockDoc4.data()).thenReturn({'name': 'No email field'});

      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(
        mockQuerySnapshot.docs,
      ).thenReturn([mockDoc1, mockDoc2, mockDoc3, mockDoc4]);

      // Act
      final List<String> result = await userEmailService.getUserEmails();

      // Assert
      expect(result, ['valid@example.com']);
      verify(mockFirestore.collection('users')).called(1);
      verify(mockCollection.get()).called(1);
    });

    test('getUserEmails rethrows exception when Firestore fails', () async {
      // Arrange
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(
        mockCollection.get(),
      ).thenThrow(Exception('Firestore connection failed'));

      // Act & Assert
      expect(() => userEmailService.getUserEmails(), throwsException);
      verify(mockFirestore.collection('users')).called(1);
      verify(mockCollection.get()).called(1);
    });
  });
}
