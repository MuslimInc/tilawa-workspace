import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/in_app_update/data/datasources/firestore_in_app_update_config_remote_data_source.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_policy.dart';

import 'firestore_in_app_update_config_remote_data_source_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocument;
  late MockDocumentSnapshot<Map<String, dynamic>> mockSnapshot;
  late FirestoreInAppUpdateConfigRemoteDataSource dataSource;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocument = MockDocumentReference<Map<String, dynamic>>();
    mockSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    dataSource = FirestoreInAppUpdateConfigRemoteDataSource(mockFirestore);

    when(
      mockFirestore.collection(
        FirestoreInAppUpdateConfigRemoteDataSource.collectionName,
      ),
    ).thenReturn(mockCollection);
    when(
      mockCollection.doc(
        FirestoreInAppUpdateConfigRemoteDataSource.documentId,
      ),
    ).thenReturn(mockDocument);
    when(mockDocument.get()).thenAnswer((_) async => mockSnapshot);
  });

  group('FirestoreInAppUpdateConfigRemoteDataSource', () {
    test('returns optional policy when document is missing', () async {
      when(mockSnapshot.exists).thenReturn(false);

      final InAppUpdatePolicy policy = await dataSource.getPolicy();

      expect(policy.forceUpdate, isFalse);
    });

    test('reads force_update from Firestore document', () async {
      when(mockSnapshot.exists).thenReturn(true);
      when(mockSnapshot.data()).thenReturn({'force_update': true});

      final InAppUpdatePolicy policy = await dataSource.getPolicy();

      expect(policy.forceUpdate, isTrue);
    });

    test('returns optional policy when Firestore read fails', () async {
      when(mockDocument.get()).thenThrow(Exception('network'));

      final InAppUpdatePolicy policy = await dataSource.getPolicy();

      expect(policy.forceUpdate, isFalse);
    });
  });
}
