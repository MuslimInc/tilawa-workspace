import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

abstract class RecitersFavoritesDataSource {
  Future<void> addFavoriteReciter({
    required String userId,
    required int reciterId,
    required String reciterName,
  });
  Future<void> removeFavoriteReciter({
    required String userId,
    required int reciterId,
  });
  Future<void> clearFavoriteReciters({required String userId});
  Future<List<String>> getFavoriteReciterIds({required String userId});
}

@LazySingleton(as: RecitersFavoritesDataSource)
class RecitersFavoritesDataSourceImpl implements RecitersFavoritesDataSource {
  RecitersFavoritesDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> addFavoriteReciter({
    required String userId,
    required int reciterId,
    required String reciterName,
  }) async {
    final DocumentReference userDoc = _firestore
        .collection('users')
        .doc(userId);
    final CollectionReference favoritesCollection = userDoc.collection(
      'favorites',
    );
    final DocumentReference reciterDoc = favoritesCollection
        .doc('reciters')
        .collection('items')
        .doc(reciterId.toString());

    await reciterDoc.set({
      'id': reciterId,
      'name': reciterName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeFavoriteReciter({
    required String userId,
    required int reciterId,
  }) async {
    final DocumentReference userDoc = _firestore
        .collection('users')
        .doc(userId);
    final CollectionReference favoritesCollection = userDoc.collection(
      'favorites',
    );
    final DocumentReference reciterDoc = favoritesCollection
        .doc('reciters')
        .collection('items')
        .doc(reciterId.toString());

    await reciterDoc.delete();
  }

  @override
  Future<void> clearFavoriteReciters({required String userId}) async {
    final CollectionReference itemsCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc('reciters')
        .collection('items');

    final QuerySnapshot snapshot = await itemsCollection.get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();
    for (final QueryDocumentSnapshot doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<List<String>> getFavoriteReciterIds({required String userId}) async {
    final DocumentReference userDoc = _firestore
        .collection('users')
        .doc(userId);
    final CollectionReference favoritesCollection = userDoc.collection(
      'favorites',
    );
    final CollectionReference itemsCollection = favoritesCollection
        .doc('reciters')
        .collection('items');

    final QuerySnapshot snapshot = await itemsCollection.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
