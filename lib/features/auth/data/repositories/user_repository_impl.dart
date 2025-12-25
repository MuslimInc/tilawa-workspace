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
}
