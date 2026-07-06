import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/quran_sessions_platform_config.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestorePlatformConfigDataSource {
  FirestorePlatformConfigDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _globalRef => _firestore
      .collection(FirestoreQuranSessionsPaths.platformConfig)
      .doc(FirestoreQuranSessionsPaths.globalPolicyDoc);

  Future<QuranSessionsPlatformConfig?> getGlobalConfig() async {
    try {
      final snapshot = await _globalRef.get();
      if (!snapshot.exists) {
        return null;
      }
      return QuranSessionsPlatformConfig.fromJson(
        Map<String, Object?>.from(snapshot.data() ?? const {}),
      );
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}
