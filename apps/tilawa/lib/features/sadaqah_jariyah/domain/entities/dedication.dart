import 'package:equatable/equatable.dart';

import '../enums/dedication_relation.dart';
import '../enums/dedication_status.dart';

class Dedication extends Equatable {
  const Dedication({
    required this.id,
    required this.displayName,
    required this.slug,
    required this.status,
    required this.isFounding,
    required this.isFeatured,
    required this.sortOrder,
    this.relation,
    this.relationOther,
    this.note,
    this.photoStoragePath,
    this.publishedAt,
  });

  final String id;
  final String displayName;
  final String slug;
  final DedicationRelation? relation;
  final String? relationOther;
  final String? note;
  final String? photoStoragePath;
  final DedicationStatus status;
  final bool isFounding;
  final bool isFeatured;
  final int sortOrder;
  final DateTime? publishedAt;

  @override
  List<Object?> get props => [
    id,
    displayName,
    slug,
    relation,
    relationOther,
    note,
    photoStoragePath,
    status,
    isFounding,
    isFeatured,
    sortOrder,
    publishedAt,
  ];
}
