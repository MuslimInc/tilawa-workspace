import 'package:dartz_plus/dartz_plus.dart';

import '../entities/teacher_application_access.dart';
import '../failures/quran_sessions_failure.dart';

/// Reads platform policy and per-user override for teacher apply entry.
abstract class TeacherApplicationAccessRepository {
  Future<Either<QuranSessionsFailure, TeacherApplicationAccess>> resolveForUser(
    String userId,
  );
}
