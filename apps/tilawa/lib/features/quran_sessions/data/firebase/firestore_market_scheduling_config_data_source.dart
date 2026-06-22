import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreMarketSchedulingConfigDataSource
    implements MarketSchedulingConfigRemoteDataSource {
  FirestoreMarketSchedulingConfigDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _globalRef => _firestore
      .collection(FirestoreQuranSessionsPaths.platformConfig)
      .doc(FirestoreQuranSessionsPaths.globalPolicyDoc);

  @override
  Future<MarketSchedulingConfigDto> getGlobal() async {
    try {
      final snapshot = await _globalRef.get();
      final data = snapshot.data() ?? const {};
      final scheduling = data['scheduling'] as Map<String, dynamic>?;
      return marketSchedulingConfigDtoFromMap(scheduling);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<MarketSchedulingConfigDto?> getMarketOverride(
    String countryCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreQuranSessionsPaths.marketConfigs)
          .doc(countryCode)
          .get();
      if (!snapshot.exists) return null;
      final scheduling =
          snapshot.data()?['scheduling'] as Map<String, dynamic>?;
      if (scheduling == null || scheduling.isEmpty) return null;
      return marketSchedulingConfigDtoFromMap(scheduling);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}
