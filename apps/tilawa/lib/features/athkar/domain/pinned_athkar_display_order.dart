import 'entities/athkar_category.dart';

/// Athkar time relevance for Home shortcut ordering.
enum AthkarTimeRelevance { morning, evening, neutral }

/// Maps category icon keys to a time-of-day relevance bucket.
AthkarTimeRelevance athkarTimeRelevanceForIcon(String iconName) {
  return switch (iconName) {
    'wb_sunny_rounded' => AthkarTimeRelevance.morning,
    'nights_stay_rounded' ||
    'bedtime_rounded' ||
    'alarm_rounded' => AthkarTimeRelevance.evening,
    _ => AthkarTimeRelevance.neutral,
  };
}

/// Puts the most relevant pinned athkar first for the current local hour.
///
/// Morning categories surface before 17:00; evening categories surface after.
List<AthkarCategory> orderPinnedAthkarForTime({
  required List<AthkarCategory> pinned,
  required DateTime now,
}) {
  if (pinned.length <= 1) {
    return pinned;
  }

  final AthkarTimeRelevance priority = now.hour < 17
      ? AthkarTimeRelevance.morning
      : AthkarTimeRelevance.evening;

  int rank(AthkarCategory category) {
    final AthkarTimeRelevance relevance = athkarTimeRelevanceForIcon(
      category.icon,
    );
    if (relevance == priority) {
      return 0;
    }
    if (relevance == AthkarTimeRelevance.neutral) {
      return 1;
    }
    return 2;
  }

  final ordered = List<AthkarCategory>.from(pinned)
    ..sort((a, b) => rank(a).compareTo(rank(b)));
  return ordered;
}

/// First pinned category when it matches the current time-of-day window.
AthkarCategory? contextualAthkarCategory({
  required List<AthkarCategory> categories,
  required DateTime now,
}) {
  if (categories.isEmpty) {
    return null;
  }

  final AthkarCategory first = categories.first;
  final AthkarTimeRelevance priority = now.hour < 17
      ? AthkarTimeRelevance.morning
      : AthkarTimeRelevance.evening;
  final AthkarTimeRelevance relevance = athkarTimeRelevanceForIcon(
    first.icon,
  );
  return relevance == priority ? first : null;
}
