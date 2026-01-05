import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/data/datasources/reciters_favorites_datasource.dart';

void main() {
  late RecitersFavoritesDataSourceImpl dataSource;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = RecitersFavoritesDataSourceImpl(fakeFirestore);
  });

  const tUserId = 'user123';
  const tReciterId = 1;

  group('addFavoriteReciter', () {
    test('should add a reciter to favorites in Firestore', () async {
      // Act
      await dataSource.addFavoriteReciter(
        userId: tUserId,
        reciterId: tReciterId,
        reciterName: 'Test Reciter',
      );

      // Assert
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await fakeFirestore
              .collection('users')
              .doc(tUserId)
              .collection('favorites')
              .doc('reciters')
              .collection('items')
              .doc(tReciterId.toString())
              .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()?['id'], tReciterId);
      expect(snapshot.data()?['name'], 'Test Reciter');
    });
  });

  group('removeFavoriteReciter', () {
    test('should remove a reciter from favorites in Firestore', () async {
      // Arrange
      await dataSource.addFavoriteReciter(
        userId: tUserId,
        reciterId: tReciterId,
        reciterName: 'Test Reciter',
      );

      // Act
      await dataSource.removeFavoriteReciter(
        userId: tUserId,
        reciterId: tReciterId,
      );

      // Assert
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await fakeFirestore
              .collection('users')
              .doc(tUserId)
              .collection('favorites')
              .doc('reciters')
              .collection('items')
              .doc(tReciterId.toString())
              .get();

      expect(snapshot.exists, false);
    });
  });

  group('getFavoriteReciterIds', () {
    test('should return a list of favorite reciter IDs', () async {
      // Arrange
      await dataSource.addFavoriteReciter(
        userId: tUserId,
        reciterId: 1,
        reciterName: 'Reciter 1',
      );
      await dataSource.addFavoriteReciter(
        userId: tUserId,
        reciterId: 2,
        reciterName: 'Reciter 2',
      );

      // Act
      final List<String> result = await dataSource.getFavoriteReciterIds(
        userId: tUserId,
      );

      // Assert
      expect(result.length, 2);
      expect(result, containsAll(['1', '2']));
    });

    test('should return an empty list if no favorites exist', () async {
      // Act
      final List<String> result = await dataSource.getFavoriteReciterIds(
        userId: tUserId,
      );

      // Assert
      expect(result, isEmpty);
    });
  });
}
