/// Admin-controlled scheduling strategy for a market.
///
/// Phase 1 only implements [recurring]. Other modes are reserved for later
/// phases without changing the resolver contract.
enum SchedulingMode {
  /// Recurring [WeeklySchedule] + overrides → generated slots.
  recurring,

  /// Published week artifacts only (Phase 3).
  weeklyPublish,

  /// Template auto-draft + explicit publish (Phase 3).
  hybrid,
}

extension SchedulingModeX on SchedulingMode {
  String get storageKey => switch (this) {
    SchedulingMode.recurring => 'recurring',
    SchedulingMode.weeklyPublish => 'weekly_publish',
    SchedulingMode.hybrid => 'hybrid',
  };

  static SchedulingMode fromKey(String? key) => switch (key) {
    'weekly_publish' => SchedulingMode.weeklyPublish,
    'hybrid' => SchedulingMode.hybrid,
    _ => SchedulingMode.recurring,
  };
}
