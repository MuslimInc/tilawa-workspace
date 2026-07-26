import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../domain/entities/sadaqah_jariyah_config.dart';
import '../mappers/sadaqah_jariyah_config_mapper.dart';

abstract class SadaqahJariyahConfigRemoteDataSource {
  Future<SadaqahJariyahConfig> getConfig();
}

@LazySingleton(as: SadaqahJariyahConfigRemoteDataSource)
class FirestoreSadaqahJariyahConfigRemoteDataSource
    implements SadaqahJariyahConfigRemoteDataSource {
  FirestoreSadaqahJariyahConfigRemoteDataSource(this._firestore);

  static const String collectionName = 'app_config';
  static const String documentId = 'sadaqah_jariyah';

  final FirebaseFirestore _firestore;

  @override
  Future<SadaqahJariyahConfig> getConfig() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection(collectionName)
          .doc(documentId)
          .get();
      if (!doc.exists || doc.data() == null) {
        return const SadaqahJariyahConfig();
      }
      return mapSadaqahJariyahConfig(doc.data());
    } on Object catch (e) {
      logger.d(
        '[SadaqahJariyahConfig] Failed to read Firestore config: $e. '
        'Using defaults.',
      );
      return const SadaqahJariyahConfig();
    }
  }
}
