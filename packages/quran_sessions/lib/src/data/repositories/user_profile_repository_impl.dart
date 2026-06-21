import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_remote_data_source.dart';
import '../mappers/user_profile_mapper.dart';
import 'repository_error_mapper.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl(this._remote);

  final UserProfileRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> getProfile(
    String userId,
  ) async {
    try {
      final dto = await _remote.getOrCreateProfile(userId);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, UserProfile>> updateProfile(
    UserProfile profile,
  ) async {
    try {
      final dto = await _remote.updateProfile(profile.toDto());
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, void>> blockAccount({
    required String userId,
    required AccountRestrictionReason reason,
  }) async {
    try {
      await _remote.blockAccount(
        userId: userId,
        restrictionReason: reason.name,
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
