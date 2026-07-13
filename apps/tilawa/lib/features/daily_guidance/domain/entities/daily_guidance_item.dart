import 'package:equatable/equatable.dart';

import 'daily_guidance_enums.dart';

/// Represents one approved deliverable content item for Daily Guidance.
class DailyGuidanceItem extends Equatable {
  final String id;
  final DailyGuidanceItemType type;
  final ContentPublicationStatus status;
  final String originalArabicText;
  final String? notificationExcerpt;
  final LocalizedGuidanceContent? shortExplanation;
  final LocalizedGuidanceContent? translation;
  final List<String> topicTags;
  final List<String>? occasionTags;
  final List<String> availableLocales;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? publishedAt;
  final DateTime? retiredAt;
  final int revision;
  final QuranSourceMetadata? quranSource;
  final HadithSourceMetadata? hadithSource;
  final ContentReviewMetadata reviewMetadata;

  const DailyGuidanceItem({
    required this.id,
    required this.type,
    required this.status,
    required this.originalArabicText,
    this.notificationExcerpt,
    this.shortExplanation,
    this.translation,
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
    translation,
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
}

/// One locale-specific reviewed text with stable provenance.
class LocalizedGuidanceContent extends Equatable {
  const LocalizedGuidanceContent({
    required this.locale,
    required this.text,
    required this.sourceId,
  });

  final String locale;
  final String text;
  final String sourceId;

  @override
  List<Object?> get props => [locale, text, sourceId];
}

class QuranSourceMetadata extends Equatable {
  final int surahNumber;
  final String surahNameArabic;
  final Map<String, String>? surahNameLocalized;
  final int ayahStart;
  final int? ayahEnd;
  final String quranTextSourceId;
  final Map<String, String>? translationSourceIds;
  final String? tafsirSourceId;

  const QuranSourceMetadata({
    required this.surahNumber,
    required this.surahNameArabic,
    this.surahNameLocalized,
    required this.ayahStart,
    this.ayahEnd,
    required this.quranTextSourceId,
    this.translationSourceIds,
    this.tafsirSourceId,
  });

  @override
  List<Object?> get props => [
    surahNumber,
    surahNameArabic,
    surahNameLocalized,
    ayahStart,
    ayahEnd,
    quranTextSourceId,
    translationSourceIds,
    tafsirSourceId,
  ];
}

class HadithSourceMetadata extends Equatable {
  final String collection;
  final String? book;
  final String? chapter;
  final String referenceNumber;
  final HadithGrading grading;
  final String gradingAuthority;
  final String? sourceEdition;

  const HadithSourceMetadata({
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
}

class ContentReviewMetadata extends Equatable {
  final String? reviewerId;
  final String? reviewAuthority;
  final DateTime? reviewedAt;
  final String? notes;
  final bool sourceValidationComplete;
  final bool translationValidationComplete;
  final bool approvedForNotification;
  final bool approvedForSharing;

  const ContentReviewMetadata({
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
}
