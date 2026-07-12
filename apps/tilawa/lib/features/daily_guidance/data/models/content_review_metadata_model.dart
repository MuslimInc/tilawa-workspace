import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/daily_guidance_item.dart';

part 'content_review_metadata_model.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class ContentReviewMetadataModel extends Equatable {
  final String? reviewerId;
  final String? reviewAuthority;
  final DateTime? reviewedAt;
  final String? notes;
  final bool sourceValidationComplete;
  final bool translationValidationComplete;
  final bool approvedForNotification;
  final bool approvedForSharing;

  const ContentReviewMetadataModel({
    this.reviewerId,
    this.reviewAuthority,
    this.reviewedAt,
    this.notes,
    required this.sourceValidationComplete,
    required this.translationValidationComplete,
    required this.approvedForNotification,
    required this.approvedForSharing,
  });

  @override
  List<Object?> get props => [
    reviewerId,
    reviewAuthority,
    reviewedAt,
    notes,
    sourceValidationComplete,
    translationValidationComplete,
    approvedForNotification,
    approvedForSharing,
  ];

  factory ContentReviewMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$ContentReviewMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContentReviewMetadataModelToJson(this);
}

extension ContentReviewMetadataModelMapper on ContentReviewMetadataModel {
  ContentReviewMetadata toEntity() {
    return ContentReviewMetadata(
      reviewerId: reviewerId,
      reviewAuthority: reviewAuthority,
      reviewedAt: reviewedAt,
      notes: notes,
      sourceValidationComplete: sourceValidationComplete,
      translationValidationComplete: translationValidationComplete,
      approvedForNotification: approvedForNotification,
      approvedForSharing: approvedForSharing,
    );
  }
}

extension ContentReviewMetadataMapper on ContentReviewMetadata {
  ContentReviewMetadataModel toModel() {
    return ContentReviewMetadataModel(
      reviewerId: reviewerId,
      reviewAuthority: reviewAuthority,
      reviewedAt: reviewedAt,
      notes: notes,
      sourceValidationComplete: sourceValidationComplete,
      translationValidationComplete: translationValidationComplete,
      approvedForNotification: approvedForNotification,
      approvedForSharing: approvedForSharing,
    );
  }
}
