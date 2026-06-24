import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/teacher_application_access.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/teacher_application_access_repository.dart';
import '../../domain/services/teacher_application_access_resolver.dart';
import '../datasources/teacher_application_access_remote_data_source.dart';

class TeacherApplicationAccessRepositoryImpl
    implements TeacherApplicationAccessRepository {
  TeacherApplicationAccessRepositoryImpl(this._dataSource);

  final TeacherApplicationAccessRemoteDataSource _dataSource;

  @override
  Future<Either<QuranSessionsFailure, TeacherApplicationAccess>> resolveForUser(
    String userId,
  ) async {
    try {
      final snapshot = await _dataSource.getAccessSnapshot(userId);
      final canApply = TeacherApplicationAccessResolver.resolve(
        policy: snapshot.policy.toDomain(),
        context: snapshot.toContext(userId),
      );
      return Right(TeacherApplicationAccess(canApplyAsTeacher: canApply));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
