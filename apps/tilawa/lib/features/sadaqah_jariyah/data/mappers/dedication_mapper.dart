import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/dedication.dart';
import '../../domain/enums/dedication_relation.dart';
import '../../domain/enums/dedication_status.dart';

Dedication? mapDedicationDocument(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final Map<String, dynamic>? data = doc.data();
  if (data == null) {
    return null;
  }
  final String displayName = (data['displayName'] as String?)?.trim() ?? '';
  final String slug = (data['slug'] as String?)?.trim() ?? '';
  if (displayName.isEmpty || slug.isEmpty) {
    return null;
  }
  final DedicationStatus status =
      DedicationStatus.tryParse(data['status'] as String?) ??
      DedicationStatus.draft;
  return Dedication(
    id: doc.id,
    displayName: displayName,
    slug: slug,
    relation: DedicationRelation.tryParse(data['relation'] as String?),
    relationOther: (data['relationOther'] as String?)?.trim(),
    note: (data['note'] as String?)?.trim(),
    photoStoragePath: (data['photoStoragePath'] as String?)?.trim(),
    status: status,
    isFounding: data['isFounding'] == true,
    isFeatured: data['isFeatured'] == true,
    sortOrder: _asInt(data['sortOrder']),
    publishedAt: _asDateTime(data['publishedAt']),
  );
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

DateTime? _asDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
