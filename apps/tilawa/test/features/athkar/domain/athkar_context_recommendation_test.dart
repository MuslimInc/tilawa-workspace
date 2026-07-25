import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/athkar/domain/athkar_context_recommendation.dart';

void main() {
  group('resolveAthkarContextRecommendation', () {
    const Map<int, AthkarCategoryCompletion> untouched = {
      AthkarContextCategoryIds.morning: AthkarCategoryCompletion.notStarted,
      AthkarContextCategoryIds.evening: AthkarCategoryCompletion.notStarted,
      AthkarContextCategoryIds.sleep: AthkarCategoryCompletion.notStarted,
    };

    final AthkarPrayerAnchors anchors = AthkarPrayerAnchors(
      fajr: DateTime(2026, 7, 25, 4, 30),
      asr: DateTime(2026, 7, 25, 15, 45),
      maghrib: DateTime(2026, 7, 25, 19, 10),
      isha: DateTime(2026, 7, 25, 20, 40),
    );

    test('prayer morning window starts morning athkar', () {
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 8),
            prayerAnchors: anchors,
            completions: untouched,
          );

      check(rec.window).equals(AthkarContextWindow.morning);
      check(rec.categoryId).equals(AthkarContextCategoryIds.morning);
      check(rec.intent).equals(AthkarContextIntent.start);
      check(rec.confidence).equals(AthkarContextConfidence.high);
    });

    test('prayer evening window starts evening athkar', () {
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 17),
            prayerAnchors: anchors,
            completions: untouched,
          );

      check(rec.window).equals(AthkarContextWindow.evening);
      check(rec.categoryId).equals(AthkarContextCategoryIds.evening);
      check(rec.intent).equals(AthkarContextIntent.start);
    });

    test('after isha prefers sleep athkar', () {
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 22, 15),
            prayerAnchors: anchors,
            completions: untouched,
          );

      check(rec.window).equals(AthkarContextWindow.sleep);
      check(rec.categoryId).equals(AthkarContextCategoryIds.sleep);
      check(rec.intent).equals(AthkarContextIntent.start);
    });

    test('before fajr prefers sleep athkar', () {
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 2, 10),
            prayerAnchors: anchors,
            completions: untouched,
          );

      check(rec.window).equals(AthkarContextWindow.sleep);
      check(rec.categoryId).equals(AthkarContextCategoryIds.sleep);
    });

    test('in-progress preferred category continues', () {
      final AthkarContextRecommendation
      rec = resolveAthkarContextRecommendation(
        now: DateTime(2026, 7, 25, 9),
        prayerAnchors: anchors,
        completions: {
          AthkarContextCategoryIds.morning: AthkarCategoryCompletion.inProgress,
          AthkarContextCategoryIds.evening: AthkarCategoryCompletion.notStarted,
          AthkarContextCategoryIds.sleep: AthkarCategoryCompletion.notStarted,
        },
      );

      check(rec.intent).equals(AthkarContextIntent.continueSession);
      check(rec.categoryId).equals(AthkarContextCategoryIds.morning);
    });

    test('done preferred soft-suggests next incomplete', () {
      final AthkarContextRecommendation
      rec = resolveAthkarContextRecommendation(
        now: DateTime(2026, 7, 25, 9),
        prayerAnchors: anchors,
        completions: {
          AthkarContextCategoryIds.morning: AthkarCategoryCompletion.done,
          AthkarContextCategoryIds.evening: AthkarCategoryCompletion.notStarted,
          AthkarContextCategoryIds.sleep: AthkarCategoryCompletion.notStarted,
        },
      );

      check(rec.window).equals(AthkarContextWindow.morning);
      check(rec.categoryId).equals(AthkarContextCategoryIds.evening);
      check(rec.intent).equals(AthkarContextIntent.completedWindow);
      check(rec.confidence).equals(AthkarContextConfidence.soft);
    });

    test('all daily done explores library', () {
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 9),
            prayerAnchors: anchors,
            completions: {
              AthkarContextCategoryIds.morning: AthkarCategoryCompletion.done,
              AthkarContextCategoryIds.evening: AthkarCategoryCompletion.done,
              AthkarContextCategoryIds.sleep: AthkarCategoryCompletion.done,
            },
          );

      check(rec.intent).equals(AthkarContextIntent.explore);
      check(rec.categoryId).isNull();
      check(rec.opensLibrary).isTrue();
    });

    test('missing asr uses fajr-maghrib midpoint', () {
      final AthkarPrayerAnchors noAsr = AthkarPrayerAnchors(
        fajr: DateTime(2026, 7, 25, 4, 30),
        maghrib: DateTime(2026, 7, 25, 19, 10),
        isha: DateTime(2026, 7, 25, 20, 40),
      );
      // Midpoint ≈ 11:50 — 16:00 should be evening.
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 16),
            prayerAnchors: noAsr,
            completions: untouched,
          );

      check(rec.window).equals(AthkarContextWindow.evening);
      check(rec.categoryId).equals(AthkarContextCategoryIds.evening);
    });

    test('clock fallback morning before 15:00', () {
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 10),
            completions: untouched,
          );

      check(rec.window).equals(AthkarContextWindow.morning);
      check(rec.categoryId).equals(AthkarContextCategoryIds.morning);
    });

    test('clock fallback evening 15–21', () {
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 18),
            completions: untouched,
          );

      check(rec.window).equals(AthkarContextWindow.evening);
      check(rec.categoryId).equals(AthkarContextCategoryIds.evening);
    });

    test('clock fallback sleep after 22:00', () {
      final AthkarContextRecommendation rec =
          resolveAthkarContextRecommendation(
            now: DateTime(2026, 7, 25, 23),
            completions: untouched,
          );

      check(rec.window).equals(AthkarContextWindow.sleep);
      check(rec.categoryId).equals(AthkarContextCategoryIds.sleep);
    });
  });
}
