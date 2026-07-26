import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/dedication.dart';
import '../../domain/enums/dedication_status.dart';
import '../mappers/dedication_mapper.dart';

abstract class DedicationsRemoteDataSource {
  Future<List<Dedication>> getPublishedDedications();
}

@LazySingleton(as: DedicationsRemoteDataSource)
class FirestoreDedicationsRemoteDataSource
    implements DedicationsRemoteDataSource {
  FirestoreDedicationsRemoteDataSource(this._firestore);

  static const String collectionName = 'dedications';

  final FirebaseFirestore _firestore;

  @override
  Future<List<Dedication>> getPublishedDedications() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection(collectionName)
        .where('status', isEqualTo: DedicationStatus.published.wireValue)
        .orderBy('sortOrder')
        .get();

    final List<Dedication> result = <Dedication>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Dedication? mapped = mapDedicationDocument(doc);
      if (mapped != null) {
        result.add(mapped);
      }
    }
    return result;
  }
}
