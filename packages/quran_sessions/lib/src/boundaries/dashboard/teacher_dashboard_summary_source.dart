import 'package:dartz_plus/dartz_plus.dart';

import '../../application/dashboard/teacher_dashboard_summary.dart';
import '../../domain/failures/quran_sessions_failure.dart';

/// Fetches the server-maintained teacher dashboard read model.
///
/// Implementations perform exactly one document read. `Right(null)` means no
/// summary has been materialized for the teacher yet (the projection builds
/// lazily on the first mutation) — callers fall back to the legacy
/// multi-fetch path in that case, as they do on any `Left`.
abstract interface class TeacherDashboardSummarySource {
  Future<Either<QuranSessionsFailure, TeacherDashboardSummary?>> fetch(
    String teacherProfileId,
  );
}
