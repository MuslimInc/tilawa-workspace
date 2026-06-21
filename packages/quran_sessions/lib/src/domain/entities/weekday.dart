/// Day of the week, ordered **Saturday-first** to match the Arabic/Hijri week
/// used across Tilawa. The declaration order of [values] is the canonical UI
/// order (Sat → Fri).
///
/// [key] is the stable serialization token written to Firestore — never derive
/// it from [name] or [index], which are presentation/order concerns that may
/// change.
enum Weekday {
  saturday('sat', DateTime.saturday),
  sunday('sun', DateTime.sunday),
  monday('mon', DateTime.monday),
  tuesday('tue', DateTime.tuesday),
  wednesday('wed', DateTime.wednesday),
  thursday('thu', DateTime.thursday),
  friday('fri', DateTime.friday);

  const Weekday(this.key, this.dartWeekday);

  /// Stable storage key (e.g. `'sat'`). Order-independent.
  final String key;

  /// Matching [DateTime.weekday] constant (1 = Mon … 7 = Sun).
  final int dartWeekday;

  /// Resolves a [Weekday] from its stable [key].
  ///
  /// Throws [ArgumentError] for an unknown key — callers reading persisted data
  /// should treat that as corrupt input.
  static Weekday fromKey(String key) => values.firstWhere(
    (w) => w.key == key,
    orElse: () => throw ArgumentError.value(key, 'key', 'Unknown weekday key'),
  );

  /// The [Weekday] a calendar [date] falls on (uses [DateTime.weekday]).
  static Weekday fromDateTime(DateTime date) =>
      values.firstWhere((w) => w.dartWeekday == date.weekday);
}
