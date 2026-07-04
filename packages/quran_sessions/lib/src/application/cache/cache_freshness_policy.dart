class CacheFreshnessPolicy {
  const CacheFreshnessPolicy();

  static const teacherProfileTtl = Duration(minutes: 5);
  static const weeklyScheduleTtl = Duration(minutes: 30);
  static const sessionDetailTtl = Duration(minutes: 5);
  static const dashboardSessionsTtl = Duration(minutes: 1);

  /// Max acceptable age of the server-maintained dashboard summary doc.
  /// Mutations rebuild it immediately and the backend prune refreshes idle
  /// docs daily, so anything older signals a broken projection — fall back
  /// to the legacy multi-fetch path.
  static const teacherDashboardSummaryTtl = Duration(hours: 26);

  bool isFresh(DateTime cachedAt, Duration ttl, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.difference(cachedAt) <= ttl;
  }
}
