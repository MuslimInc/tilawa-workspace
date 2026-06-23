import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/session_policy.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/session_policy_repository.dart';
import '../datasources/session_policy_remote_data_source.dart';
import '../mappers/session_policy_mapper.dart';
import 'repository_error_mapper.dart';

class SessionPolicyRepositoryImpl implements SessionPolicyRepository {
  const SessionPolicyRepositoryImpl(this._remote);

  final SessionPolicyRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, QuranSessionSafetyPolicy>>
  getGlobalPolicy() async {
    try {
      final dto = await _remote.getGlobalPolicy();
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, TeacherEligibilityPolicy>>
  getTeacherEligibilityPolicy(String teacherId) async {
    try {
      final dto = await _remote.getTeacherEligibilityPolicy(teacherId);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, void>> updateGlobalPolicy(
    QuranSessionSafetyPolicy policy,
  ) async {
    try {
      await _remote.updateGlobalPolicy(policy.toDto());
      return const Right(null);
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, void>> updateTeacherEligibilityPolicy({
    required String teacherId,
    required TeacherEligibilityPolicy policy,
  }) async {
    try {
      await _remote.updateTeacherEligibilityPolicy(
        teacherId: teacherId,
        policy: policy.toDto(),
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
