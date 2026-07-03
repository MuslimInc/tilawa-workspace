import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/email_registration_draft.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  static const String _quranSessionsProfileField = 'quranSessionsProfile';

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
  Future<void> ensureQuranSessionsProfileShell(String userId) async {
    final DocumentReference<Map<String, dynamic>> userRef = _firestore
        .collection('users')
        .doc(userId);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await userRef.get();
    final Map<String, dynamic> data = snapshot.data() ?? const {};
    if (data.containsKey(_quranSessionsProfileField)) {
      return;
    }

    final DateTime now = DateTime.now();
    await userRef.set({
      _quranSessionsProfileField: {
        'role': 'student',
        'accountStatus': 'active',
        'profileCompleted': false,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveCompleteEmailRegistration({
    required UserEntity user,
    required EmailRegistrationDraft draft,
  }) async {
    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> userRef = _firestore
        .collection('users')
        .doc(user.id);

    await userRef.set({
      'email': user.email,
      'displayName': draft.displayName.trim(),
      'photoUrl': user.photoUrl,
      'lastSignInTime': FieldValue.serverTimestamp(),
      'createdAt': user.createdAt.toIso8601String(),
      'authProvider': 'emailPassword',
      if (draft.preferredLanguageCode != null)
        'languageCode': draft.preferredLanguageCode,
      _quranSessionsProfileField: {
        'role': 'student',
        'accountStatus': 'active',
        'profileCompleted': true,
        'displayName': draft.displayName.trim(),
        'gender': draft.gender,
        'dateOfBirth': draft.dateOfBirth?.toIso8601String(),
        'countryCode': draft.countryCode,
        'countryName': draft.countryName,
        'cityId': draft.cityId,
        'cityName': draft.cityName,
        'currencyCode': draft.currencyCode,
        'timezone': draft.timezone,
        if (draft.learningGoals.isNotEmpty)
          'learningGoals': draft.learningGoals,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
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
