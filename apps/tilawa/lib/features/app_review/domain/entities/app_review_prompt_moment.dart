/// Calm moments where a native review dialog may be considered.
///
/// Not every moment may prompt — see [AppReviewTriggerPolicy.allowedPromptMoments].
enum AppReviewPromptMoment {
  /// Updates counters only; never shows a dialog.
  sessionStarted,

  /// User finished a surah/track while not in a sacred flow.
  listeningSessionCompleted,

  /// User left the Prayer Times tab for a neutral surface.
  leftPrayerTimesTab,

  /// User returned to Reciters (home) from another main tab.
  returnedToRecitersTab,

  favoriteReciterAdded,
  bookmarkCreated,
}
