import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveUserData(UserEntity user) async {
    final DocumentReference<Map<String, dynamic>> userRef = _firestore
        .collection('users')
        .doc(user.id);

    // Check if user exists to avoid overwriting existing data that we might not have locally
    // Or we can merge. For now, let's use set with SetOptions(merge: true) to update/create
    await userRef.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'lastSignInTime': FieldValue.serverTimestamp(),
      'createdAt': user.createdAt.toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveDeviceToken(String userId, String token) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(token)
        .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
  }

  @override
  Future<void> deleteDeviceToken(String userId, String token) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(token)
        .delete();
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
