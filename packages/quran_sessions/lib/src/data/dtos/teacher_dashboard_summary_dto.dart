import 'availability_override_dto.dart';
import 'market_scheduling_config_dto.dart';
import 'quran_session_dto.dart';
import 'weekly_schedule_dto.dart';

/// Wire shape of the teacher dashboard read-model document, decoded by the
/// host app's Firestore data source. Field decoding reuses the same
/// converters as the legacy per-collection reads, so both paths produce
/// identical DTOs for identical source data.
class TeacherDashboardSummaryDto {
  const TeacherDashboardSummaryDto({
    required this.teacherProfileId,
    required this.ownerUserId,
    required this.schedulingConfig,
    required this.sessions,
    required this.overrides,
    required this.sessionsTruncated,
    required this.updatedAt,
    this.weeklySchedule,
    this.displayName,
    this.countryCode,
  });

  final String teacherProfileId;
  final String ownerUserId;
  final String? displayName;
  final String? countryCode;
  final MarketSchedulingConfigDto schedulingConfig;
  final WeeklyScheduleDto? weeklySchedule;
  final List<AvailabilityOverrideDto> overrides;
  final List<QuranSessionDto> sessions;
  final bool sessionsTruncated;

  /// ISO-8601 UTC instant of the last projection write.
  final String updatedAt;
}
