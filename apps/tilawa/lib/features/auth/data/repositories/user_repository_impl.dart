import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<void> saveUserData(UserEntity user) async {
    final DocumentReference<Map<String, dynamic>> userRef = _firestore
        .collection('users')
        .doc(user.id);

    await userRef.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'lastSignInTime': FieldValue.serverTimestamp(),
      'createdAt': user.createdAt.toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> syncLanguagePreference(String languageCode) async {
    final String? userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) {
      return;
    }

    await _firestore.collection('users').doc(userId).set(
      {'languageCode': languageCode},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteUserData(String userId) async {
    final DocumentReference<Map<String, dynamic>> userRef = _firestore
        .collection('users')
        .doc(userId);

    final QuerySnapshot<Map<String, dynamic>> tokensSnapshot = await userRef
        .collection('fcm_tokens')
        .get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in tokensSnapshot.docs) {
      await doc.reference.delete();
    }

    await userRef.delete();
  }
}
