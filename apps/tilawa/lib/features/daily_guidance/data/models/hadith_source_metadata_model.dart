import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/daily_guidance_enums.dart';
import '../../domain/entities/daily_guidance_item.dart';

part 'hadith_source_metadata_model.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class HadithSourceMetadataModel extends Equatable {
  final String collection;
  final String? book;
  final String? chapter;
  final String referenceNumber;
  final HadithGrading grading;
  final String gradingAuthority;
  final String? sourceEdition;

  const HadithSourceMetadataModel({
    required this.collection,
    this.book,
    this.chapter,
    required this.referenceNumber,
    required this.grading,
    required this.gradingAuthority,
    this.sourceEdition,
  });

  @override
  List<Object?> get props => [
    collection,
    book,
    chapter,
    referenceNumber,
    grading,
    gradingAuthority,
    sourceEdition,
  ];

  factory HadithSourceMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$HadithSourceMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$HadithSourceMetadataModelToJson(this);
}

extension HadithSourceMetadataModelMapper on HadithSourceMetadataModel {
  HadithSourceMetadata toEntity() {
    return HadithSourceMetadata(
      collection: collection,
      book: book,
      chapter: chapter,
      referenceNumber: referenceNumber,
      grading: grading,
      gradingAuthority: gradingAuthority,
      sourceEdition: sourceEdition,
    );
  }
}

extension HadithSourceMetadataMapper on HadithSourceMetadata {
  HadithSourceMetadataModel toModel() {
    return HadithSourceMetadataModel(
      collection: collection,
      book: book,
      chapter: chapter,
      referenceNumber: referenceNumber,
      grading: grading,
      gradingAuthority: gradingAuthority,
      sourceEdition: sourceEdition,
    );
  }
}
