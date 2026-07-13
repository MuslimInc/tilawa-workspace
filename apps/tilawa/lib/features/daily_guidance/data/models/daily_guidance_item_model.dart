import 'package:equatable/equatable.dart';

import '../../domain/entities/daily_guidance_enums.dart';
import 'content_review_metadata_model.dart';
import 'hadith_source_metadata_model.dart';
import 'quran_source_metadata_model.dart';

class DailyGuidanceItemModel extends Equatable {
  final String id;
  final DailyGuidanceItemType type;
  final ContentPublicationStatus status;
  final String originalArabicText;
  final String? notificationExcerpt;
  final Map<String, String>? shortExplanation;
  final Map<String, String>? translations;
  final Map<String, String>? shortExplanationSourceIds;
  final Map<String, String>? translationSourceIds;
  final List<String> topicTags;
  final List<String>? occasionTags;
  final List<String> availableLocales;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? publishedAt;
  final DateTime? retiredAt;
  final int revision;
  final QuranSourceMetadataModel? quranSource;
  final HadithSourceMetadataModel? hadithSource;
  final ContentReviewMetadataModel reviewMetadata;

  const DailyGuidanceItemModel({
    required this.id,
    required this.type,
    required this.status,
    required this.originalArabicText,
    this.notificationExcerpt,
    this.shortExplanation,
    this.translations,
    this.shortExplanationSourceIds,
    this.translationSourceIds,
    required this.topicTags,
    this.occasionTags,
    required this.availableLocales,
    this.validFrom,
    this.validUntil,
    this.publishedAt,
    this.retiredAt,
    required this.revision,
    this.quranSource,
    this.hadithSource,
    required this.reviewMetadata,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    originalArabicText,
    notificationExcerpt,
    shortExplanation,
    translations,
    shortExplanationSourceIds,
    translationSourceIds,
    topicTags,
    occasionTags,
    availableLocales,
    validFrom,
    validUntil,
    publishedAt,
    retiredAt,
    revision,
    quranSource,
    hadithSource,
    reviewMetadata,
  ];

  factory DailyGuidanceItemModel.fromJson(Map<String, dynamic> json) {
    return DailyGuidanceItemModel(
      id: json['id'] as String,
      type: DailyGuidanceItemType.values.firstWhere(
        (e) =>
            e.name == json['type'] ||
            e.toString() == "DailyGuidanceItemType.${json['type']}",
      ),
      status: ContentPublicationStatus.values.firstWhere(
        (e) =>
            e.name == json['status'] ||
            e.toString() == "ContentPublicationStatus.${json['status']}",
      ),
      originalArabicText: json['original_arabic_text'] as String,
      notificationExcerpt: json['notification_excerpt'] as String?,
      shortExplanation: (json['short_explanation'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
      translations: (json['translations'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as String),
      ),
      shortExplanationSourceIds:
          (json['short_explanation_source_ids'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ),
      translationSourceIds:
          (json['translation_source_ids'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ),
      topicTags: (json['topic_tags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      occasionTags: (json['occasion_tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      availableLocales: (json['available_locales'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      validFrom: json['valid_from'] == null
          ? null
          : DateTime.parse(json['valid_from'] as String),
      validUntil: json['valid_until'] == null
          ? null
          : DateTime.parse(json['valid_until'] as String),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      retiredAt: json['retired_at'] == null
          ? null
          : DateTime.parse(json['retired_at'] as String),
      revision: json['revision'] as int,
      quranSource: json['quran_source'] == null
          ? null
          : QuranSourceMetadataModel.fromJson(
              json['quran_source'] as Map<String, dynamic>,
            ),
      hadithSource: json['hadith_source'] == null
          ? null
          : HadithSourceMetadataModel.fromJson(
              json['hadith_source'] as Map<String, dynamic>,
            ),
      reviewMetadata: ContentReviewMetadataModel.fromJson(
        json['review_metadata'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'original_arabic_text': originalArabicText,
      'notification_excerpt': notificationExcerpt,
      'short_explanation': shortExplanation,
      'translations': translations,
      'short_explanation_source_ids': shortExplanationSourceIds,
      'translation_source_ids': translationSourceIds,
      'topic_tags': topicTags,
      'occasion_tags': occasionTags,
      'available_locales': availableLocales,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
      'retired_at': retiredAt?.toIso8601String(),
      'revision': revision,
      'quran_source': quranSource?.toJson(),
      'hadith_source': hadithSource?.toJson(),
      'review_metadata': reviewMetadata.toJson(),
    };
  }
}
