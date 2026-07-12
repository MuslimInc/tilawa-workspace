import 'package:json_annotation/json_annotation.dart';

/// The type of content delivered in the daily guidance item.
enum DailyGuidanceItemType {
  @JsonValue('quran')
  quran,
  @JsonValue('hadith')
  hadith,
}

/// The user's preference for what kind of content they receive.
enum DailyGuidanceContentMode {
  @JsonValue('quranOnly')
  quranOnly,
  @JsonValue('hadithOnly')
  hadithOnly,
  @JsonValue('mixed')
  mixed,
}

/// Content lifecycle status. Only [published] items are eligible for delivery.
enum ContentPublicationStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('inReview')
  inReview,
  @JsonValue('approved')
  approved,
  @JsonValue('published')
  published,
  @JsonValue('retired')
  retired,
  @JsonValue('rejected')
  rejected,
}

/// Authenticity grading for Hadith items.
enum HadithGrading {
  @JsonValue('sahih')
  sahih,
  @JsonValue('hasan')
  hasan,
  @JsonValue('daif')
  daif,
  @JsonValue('fabricated')
  fabricated,
}

/// Lifecycle of a daily delivery.
enum DeliveryStatus {
  @JsonValue('selected')
  selected,
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('delivered')
  delivered,
  @JsonValue('opened')
  opened,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('skipped')
  skipped,
  @JsonValue('failed')
  failed,
}

/// Overall state of the Daily Guidance feature.
enum FeatureState {
  disabled,
  permissionRequired,
  permissionDenied,
  enabled,
  paused,
  temporarilyUnavailable,
}
