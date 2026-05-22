import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Locally persisted engagement counters for review eligibility.
@immutable
class AppReviewEngagement extends Equatable {
  const AppReviewEngagement({
    this.sessionCount = 0,
    this.distinctActiveDays = 0,
    this.listeningCompletions = 0,
    this.prayerTimesTabVisits = 0,
    this.favoriteAdds = 0,
    this.bookmarkCreates = 0,
    this.promptCount = 0,
    this.firstSeenAtMs,
    this.lastPromptAtMs,
    this.lastSessionDayKey,
    this.lastActiveDayKey,
  });

  final int sessionCount;
  final int distinctActiveDays;
  final int listeningCompletions;
  final int prayerTimesTabVisits;
  final int favoriteAdds;
  final int bookmarkCreates;
  final int promptCount;
  final int? firstSeenAtMs;
  final int? lastPromptAtMs;

  /// `yyyy-MM-dd` — at most one session per calendar day.
  final String? lastSessionDayKey;

  /// `yyyy-MM-dd` — last day any signal was recorded.
  final String? lastActiveDayKey;

  int get engagementActions => favoriteAdds + bookmarkCreates;

  bool get hasValueMoment =>
      listeningCompletions > 0 ||
      prayerTimesTabVisits > 0 ||
      engagementActions > 0;

  AppReviewEngagement copyWith({
    int? sessionCount,
    int? distinctActiveDays,
    int? listeningCompletions,
    int? prayerTimesTabVisits,
    int? favoriteAdds,
    int? bookmarkCreates,
    int? promptCount,
    int? firstSeenAtMs,
    int? lastPromptAtMs,
    String? lastSessionDayKey,
    String? lastActiveDayKey,
  }) {
    return AppReviewEngagement(
      sessionCount: sessionCount ?? this.sessionCount,
      distinctActiveDays: distinctActiveDays ?? this.distinctActiveDays,
      listeningCompletions: listeningCompletions ?? this.listeningCompletions,
      prayerTimesTabVisits: prayerTimesTabVisits ?? this.prayerTimesTabVisits,
      favoriteAdds: favoriteAdds ?? this.favoriteAdds,
      bookmarkCreates: bookmarkCreates ?? this.bookmarkCreates,
      promptCount: promptCount ?? this.promptCount,
      firstSeenAtMs: firstSeenAtMs ?? this.firstSeenAtMs,
      lastPromptAtMs: lastPromptAtMs ?? this.lastPromptAtMs,
      lastSessionDayKey: lastSessionDayKey ?? this.lastSessionDayKey,
      lastActiveDayKey: lastActiveDayKey ?? this.lastActiveDayKey,
    );
  }

  @override
  List<Object?> get props => [
    sessionCount,
    distinctActiveDays,
    listeningCompletions,
    prayerTimesTabVisits,
    favoriteAdds,
    bookmarkCreates,
    promptCount,
    firstSeenAtMs,
    lastPromptAtMs,
    lastSessionDayKey,
    lastActiveDayKey,
  ];
}
