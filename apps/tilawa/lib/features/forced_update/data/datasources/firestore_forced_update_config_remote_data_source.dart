import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../domain/entities/forced_update_policy.dart';
import 'forced_update_config_remote_data_source.dart';
import 'forced_update_policy_mapper.dart';

@LazySingleton(as: ForcedUpdateConfigRemoteDataSource)
class FirestoreForcedUpdateConfigRemoteDataSource
    implements ForcedUpdateConfigRemoteDataSource {
  FirestoreForcedUpdateConfigRemoteDataSource(this._firestore);

  static const String collectionName = 'app_config';
  static const String documentId = 'in_app_update';

  final FirebaseFirestore _firestore;

  @override
  Future<ForcedUpdatePolicy> getPolicy() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection(collectionName)
          .doc(documentId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return const ForcedUpdatePolicy();
      }

      return mapForcedUpdatePolicy(doc.data()!);
    } on Object catch (e) {
      logger.d(
        '[ForcedUpdateConfig] Failed to read Firestore policy: $e. '
        'Failing open (no gate).',
      );
      return const ForcedUpdatePolicy();
    }
  }
}
