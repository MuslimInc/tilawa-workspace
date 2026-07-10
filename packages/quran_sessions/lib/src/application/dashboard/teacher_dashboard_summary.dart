import 'package:equatable/equatable.dart';

import '../../domain/entities/availability_override.dart';
import '../../domain/entities/market_scheduling_config.dart';
import '../../domain/entities/quran_session.dart';
import '../../domain/entities/weekly_schedule.dart';

/// Decoded teacher dashboard read-model document
/// (`quran_teacher_profiles/{id}/dashboard/summary`).
///
/// Maintained server-side by the dashboard projection Cloud Functions; one
/// document read supplies everything the teacher dashboard needs. Sessions
/// are the raw upcoming-window list — lifecycle classification (pending vs
/// upcoming) and slot generation stay in the domain layer, exactly as on the
/// legacy multi-fetch path.
class TeacherDashboardSummary extends Equatable {
  const TeacherDashboardSummary({
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
  final MarketSchedulingConfig schedulingConfig;
  final WeeklySchedule? weeklySchedule;
  final List<AvailabilityOverride> overrides;

  /// Raw upcoming-window sessions (`endsAt >= build time`), capped by the
  /// projector. When [sessionsTruncated] is true the doc holds only the first
  /// cap-many sessions and callers must fall back to direct queries.
  final List<QuranSession> sessions;
  final bool sessionsTruncated;

  /// Server time of the last projection write; drives client freshness checks.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    teacherProfileId,
    ownerUserId,
    displayName,
    countryCode,
    schedulingConfig,
    weeklySchedule,
    overrides,
    sessions,
    sessionsTruncated,
    updatedAt,
  ];
}
