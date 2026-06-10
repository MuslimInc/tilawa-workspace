abstract interface class WhatsNewProgressRepository {
  Future<String?> getLastSeenReleaseId();

  Future<void> markReleaseSeen(String releaseId);

  Future<void> clearProgress();
}
