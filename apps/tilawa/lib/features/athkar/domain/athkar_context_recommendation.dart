/// Canonical daily Athkar category IDs used for Home context.
abstract final class AthkarContextCategoryIds {
  static const int morning = 1;
  static const int evening = 2;
  static const int sleep = 3;

  static const List<int> daily = [morning, evening, sleep];
}

/// Time-of-day window for contextual Athkar (suitability, not obligation).
enum AthkarContextWindow { morning, evening, sleep, neutral }

/// What the Home tile should invite the user to do.
enum AthkarContextIntent {
  start,
  continueSession,
  completedWindow,
  explore,
}

/// How strongly the recommendation matches the current moment.
enum AthkarContextConfidence { high, soft }

/// Daily completion snapshot for one Athkar category.
enum AthkarCategoryCompletion { notStarted, inProgress, done }

/// Prayer anchors for prayer-aware windows. All times must be local.
///
/// When [asr] is null, evening start falls back to the midpoint of
/// [fajr]→[maghrib] (or clock rules if [maghrib] is also null).
final class AthkarPrayerAnchors {
  const AthkarPrayerAnchors({
    required this.fajr,
    required this.isha,
    this.asr,
    this.maghrib,
  });

  final DateTime fajr;
  final DateTime? asr;
  final DateTime? maghrib;
  final DateTime isha;
}

/// Deterministic Home Athkar recommendation (UI-free).
final class AthkarContextRecommendation {
  const AthkarContextRecommendation({
    required this.window,
    required this.intent,
    required this.confidence,
    this.categoryId,
  });

  /// Preferred category to open, or null when [intent] is [AthkarContextIntent.explore].
  final int? categoryId;
  final AthkarContextWindow window;
  final AthkarContextIntent intent;
  final AthkarContextConfidence confidence;

  bool get opensLibrary =>
      intent == AthkarContextIntent.explore || categoryId == null;
}

/// Resolves the Athkar recommendation for [now].
///
/// Prayer windows (when [prayerAnchors] is present):
/// - morning: `[fajr, asr)`
/// - evening: `[asr, isha)`
/// - sleep: `[isha, next fajr)`
///
/// Clock fallback (approximate only — not a fiqh claim):
/// - morning: 04:00–14:59
/// - evening: 15:00–21:59
/// - sleep: 22:00–03:59
AthkarContextRecommendation resolveAthkarContextRecommendation({
  required DateTime now,
  AthkarPrayerAnchors? prayerAnchors,
  required Map<int, AthkarCategoryCompletion> completions,
}) {
  final AthkarContextWindow window = _resolveWindow(now, prayerAnchors);
  final int? preferredId = _preferredCategoryId(window);

  if (preferredId == null) {
    return const AthkarContextRecommendation(
      window: AthkarContextWindow.neutral,
      intent: AthkarContextIntent.explore,
      confidence: AthkarContextConfidence.soft,
    );
  }

  final AthkarCategoryCompletion preferred =
      completions[preferredId] ?? AthkarCategoryCompletion.notStarted;

  if (preferred == AthkarCategoryCompletion.inProgress) {
    return AthkarContextRecommendation(
      categoryId: preferredId,
      window: window,
      intent: AthkarContextIntent.continueSession,
      confidence: AthkarContextConfidence.high,
    );
  }

  if (preferred == AthkarCategoryCompletion.notStarted) {
    return AthkarContextRecommendation(
      categoryId: preferredId,
      window: window,
      intent: AthkarContextIntent.start,
      confidence: AthkarContextConfidence.high,
    );
  }

  // Preferred window category is done — soft secondary or explore.
  final int? secondaryId = _nextIncomplete(
    preferredId: preferredId,
    completions: completions,
  );
  if (secondaryId == null) {
    return AthkarContextRecommendation(
      window: window,
      intent: AthkarContextIntent.explore,
      confidence: AthkarContextConfidence.soft,
    );
  }

  final AthkarCategoryCompletion secondary =
      completions[secondaryId] ?? AthkarCategoryCompletion.notStarted;
  return AthkarContextRecommendation(
    categoryId: secondaryId,
    window: window,
    intent: secondary == AthkarCategoryCompletion.inProgress
        ? AthkarContextIntent.continueSession
        : AthkarContextIntent.completedWindow,
    confidence: AthkarContextConfidence.soft,
  );
}

AthkarContextWindow _resolveWindow(DateTime now, AthkarPrayerAnchors? anchors) {
  if (anchors == null) {
    return _clockWindow(now);
  }

  final DateTime fajr = anchors.fajr;
  final DateTime isha = anchors.isha;
  final DateTime asr = anchors.asr ?? _fallbackAsr(anchors);

  // After today's Isha → sleep until tomorrow's Fajr (or before today's Fajr).
  if (!now.isBefore(isha) || now.isBefore(fajr)) {
    return AthkarContextWindow.sleep;
  }
  if (now.isBefore(asr)) {
    return AthkarContextWindow.morning;
  }
  return AthkarContextWindow.evening;
}

/// Midpoint fajr→maghrib, or midday (12:00) on the fajr calendar day.
DateTime _fallbackAsr(AthkarPrayerAnchors anchors) {
  final DateTime? maghrib = anchors.maghrib;
  if (maghrib != null) {
    final int midMs =
        anchors.fajr.millisecondsSinceEpoch +
        ((maghrib.millisecondsSinceEpoch -
                anchors.fajr.millisecondsSinceEpoch) ~/
            2);
    return DateTime.fromMillisecondsSinceEpoch(midMs);
  }
  return DateTime(anchors.fajr.year, anchors.fajr.month, anchors.fajr.day, 12);
}

/// Approximate clock windows when prayer times are unavailable.
AthkarContextWindow _clockWindow(DateTime now) {
  final int hour = now.hour;
  if (hour >= 4 && hour < 15) {
    return AthkarContextWindow.morning;
  }
  if (hour >= 15 && hour < 22) {
    return AthkarContextWindow.evening;
  }
  return AthkarContextWindow.sleep;
}

int? _preferredCategoryId(AthkarContextWindow window) {
  return switch (window) {
    AthkarContextWindow.morning => AthkarContextCategoryIds.morning,
    AthkarContextWindow.evening => AthkarContextCategoryIds.evening,
    AthkarContextWindow.sleep => AthkarContextCategoryIds.sleep,
    AthkarContextWindow.neutral => null,
  };
}

/// Soft cycle after [preferredId]: morning → evening → sleep → morning…
int? _nextIncomplete({
  required int preferredId,
  required Map<int, AthkarCategoryCompletion> completions,
}) {
  const List<int> order = AthkarContextCategoryIds.daily;
  final int startIndex = order.indexOf(preferredId);
  if (startIndex < 0) {
    return null;
  }

  for (var step = 1; step < order.length; step++) {
    final int id = order[(startIndex + step) % order.length];
    final AthkarCategoryCompletion completion =
        completions[id] ?? AthkarCategoryCompletion.notStarted;
    if (completion != AthkarCategoryCompletion.done) {
      return id;
    }
  }
  return null;
}
