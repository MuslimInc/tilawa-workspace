import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/failures/quran_sessions_failure.dart';
import 'get_teacher_dashboard_usecase.dart';

class RefreshTeacherDashboardUseCase {
  const RefreshTeacherDashboardUseCase(this._getDashboard);

  final GetTeacherDashboardUseCase _getDashboard;

  Future<Either<QuranSessionsFailure, TeacherDashboardResult>> call({
    required String teacherProfileId,
    required DateTime now,
  }) {
    return _getDashboard(
      teacherProfileId: teacherProfileId,
      now: now,
      forceRefresh: true,
    );
  }
}
