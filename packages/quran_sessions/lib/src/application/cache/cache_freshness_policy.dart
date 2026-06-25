class CacheFreshnessPolicy {
  const CacheFreshnessPolicy();

  static const teacherProfileTtl = Duration(minutes: 5);
  static const weeklyScheduleTtl = Duration(minutes: 30);
  static const sessionDetailTtl = Duration(minutes: 5);
  static const dashboardSessionsTtl = Duration(minutes: 1);

  bool isFresh(DateTime cachedAt, Duration ttl, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.difference(cachedAt) <= ttl;
  }
}
