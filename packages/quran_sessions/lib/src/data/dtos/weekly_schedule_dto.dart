/// Serializable form of a teacher's recurring weekly availability.
///
/// `weeklyRules` maps a stable weekday key (`'sat'`…`'fri'`) to a list of
/// `{ 'start': 'HH:mm', 'end': 'HH:mm' }` intervals. Closed days are present
/// with an empty list so the document is self-describing.
class WeeklyScheduleDto {
  const WeeklyScheduleDto({
    required this.teacherId,
    required this.timezone,
    required this.slotDurationMinutes,
    required this.minNoticeMinutes,
    required this.maxHorizonDays,
    required this.bufferBeforeMinutes,
    required this.bufferAfterMinutes,
    required this.weeklyRules,
    required this.version,
    this.updatedAt,
  });

  final String teacherId;
  final String timezone;
  final int slotDurationMinutes;
  final int minNoticeMinutes;
  final int maxHorizonDays;
  final int bufferBeforeMinutes;
  final int bufferAfterMinutes;
  final Map<String, List<Map<String, String>>> weeklyRules;
  final int version;
  final String? updatedAt;

  factory WeeklyScheduleDto.fromJson(Map<String, dynamic> json) {
    final rawRules =
        (json['weekly_rules'] as Map<String, dynamic>? ?? const {});
    final rules = <String, List<Map<String, String>>>{};
    for (final entry in rawRules.entries) {
      rules[entry.key] = (entry.value as List<dynamic>? ?? const [])
          .map(
            (e) => (e as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v as String),
            ),
          )
          .toList();
    }
    return WeeklyScheduleDto(
      teacherId: json['teacher_id'] as String,
      timezone: json['timezone'] as String,
      slotDurationMinutes: json['slot_duration_minutes'] as int,
      minNoticeMinutes: json['min_notice_minutes'] as int? ?? 120,
      maxHorizonDays: json['max_horizon_days'] as int? ?? 30,
      bufferBeforeMinutes: json['buffer_before_minutes'] as int? ?? 0,
      bufferAfterMinutes: json['buffer_after_minutes'] as int? ?? 0,
      weeklyRules: rules,
      version: json['version'] as int? ?? 1,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'teacher_id': teacherId,
    'timezone': timezone,
    'slot_duration_minutes': slotDurationMinutes,
    'min_notice_minutes': minNoticeMinutes,
    'max_horizon_days': maxHorizonDays,
    'buffer_before_minutes': bufferBeforeMinutes,
    'buffer_after_minutes': bufferAfterMinutes,
    'weekly_rules': weeklyRules,
    'version': version,
    'updated_at': updatedAt,
  };
}
