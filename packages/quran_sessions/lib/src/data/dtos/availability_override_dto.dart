/// Serializable form of a single dated [AvailabilityOverride].
///
/// `date` is a `yyyy-MM-dd` teacher-local calendar date (also the storage doc
/// id). `type` is `'unavailable'` or `'custom'`; `intervals` is only meaningful
/// for `custom` and lists `{ 'start': 'HH:mm', 'end': 'HH:mm' }` entries.
class AvailabilityOverrideDto {
  const AvailabilityOverrideDto({
    required this.date,
    required this.type,
    this.intervals = const [],
    this.reason,
  });

  final String date;
  final String type;
  final List<Map<String, String>> intervals;
  final String? reason;

  factory AvailabilityOverrideDto.fromJson(Map<String, dynamic> json) =>
      AvailabilityOverrideDto(
        date: json['date'] as String,
        type: json['type'] as String,
        intervals: (json['intervals'] as List<dynamic>? ?? const [])
            .map(
              (e) => (e as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, v as String),
              ),
            )
            .toList(),
        reason: json['reason'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'date': date,
    'type': type,
    'intervals': intervals,
    'reason': reason,
  };
}
