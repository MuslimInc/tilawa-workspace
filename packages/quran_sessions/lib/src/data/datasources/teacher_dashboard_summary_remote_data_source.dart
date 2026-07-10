import '../dtos/teacher_dashboard_summary_dto.dart';

/// Single-read access to the server-maintained dashboard summary doc
/// (`quran_teacher_profiles/{id}/dashboard/summary`).
///
/// Implementations throw `RemoteException` subtypes on transport errors and
/// return `null` when no summary has been materialized for the teacher.
abstract interface class TeacherDashboardSummaryRemoteDataSource {
  Future<TeacherDashboardSummaryDto?> fetchSummary(String teacherProfileId);
}
