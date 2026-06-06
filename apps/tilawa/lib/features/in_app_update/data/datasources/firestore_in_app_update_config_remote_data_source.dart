import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa/core/logging/app_logger.dart';
import '../../domain/entities/in_app_update_policy.dart';
import 'in_app_update_config_remote_data_source.dart';

@LazySingleton(as: InAppUpdateConfigRemoteDataSource)
class FirestoreInAppUpdateConfigRemoteDataSource
    implements InAppUpdateConfigRemoteDataSource {
  FirestoreInAppUpdateConfigRemoteDataSource(this._firestore);

  static const String collectionName = 'app_config';
  static const String documentId = 'in_app_update';
  static const String forceUpdateField = 'force_update';

  final FirebaseFirestore _firestore;

  @override
  Future<InAppUpdatePolicy> getPolicy() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection(collectionName)
          .doc(documentId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return const InAppUpdatePolicy();
      }

      return _mapPolicy(doc.data()!);
    } catch (e) {
      logger.d(
        '[InAppUpdateConfig] Failed to read Firestore policy: $e. '
        'Using optional updates.',
      );
      return const InAppUpdatePolicy();
    }
  }

  InAppUpdatePolicy _mapPolicy(Map<String, dynamic> json) {
    return InAppUpdatePolicy(
      forceUpdate: json[forceUpdateField] as bool? ?? false,
    );
  }
}
