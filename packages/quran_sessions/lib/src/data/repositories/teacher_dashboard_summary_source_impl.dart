import 'package:dartz_plus/dartz_plus.dart';

import '../../application/dashboard/teacher_dashboard_summary.dart';
import '../../boundaries/dashboard/teacher_dashboard_summary_source.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../datasources/teacher_dashboard_summary_remote_data_source.dart';
import '../mappers/market_scheduling_config_mapper.dart';
import '../mappers/schedule_mapper.dart';
import '../mappers/session_mapper.dart';
import 'repository_error_mapper.dart';

/// Maps the summary wire DTO to domain via the same mappers the legacy
/// per-collection reads use, so both dashboard paths decode identically.
class TeacherDashboardSummarySourceImpl
    implements TeacherDashboardSummarySource {
  const TeacherDashboardSummarySourceImpl(this._remote);

  final TeacherDashboardSummaryRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, TeacherDashboardSummary?>> fetch(
    String teacherProfileId,
  ) async {
    try {
      final dto = await _remote.fetchSummary(teacherProfileId);
      if (dto == null) return const Right(null);
      return Right(
        TeacherDashboardSummary(
          teacherProfileId: dto.teacherProfileId,
          ownerUserId: dto.ownerUserId,
          displayName: dto.displayName,
          countryCode: dto.countryCode,
          schedulingConfig: marketSchedulingConfigFromDto(dto.schedulingConfig),
          weeklySchedule: dto.weeklySchedule?.toDomain(),
          overrides: dto.overrides.map((o) => o.toDomain()).toList(),
          sessions: dto.sessions.map((s) => s.toDomain()).toList(),
          sessionsTruncated: dto.sessionsTruncated,
          updatedAt: DateTime.parse(dto.updatedAt).toUtc(),
        ),
      );
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
