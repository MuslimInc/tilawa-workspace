import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/teacher_availability.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../boundaries/scheduling/availability_provider.dart';
import '../datasources/availability_remote_data_source.dart';
import '../mappers/availability_mapper.dart';
import '../repositories/repository_error_mapper.dart';

/// [AvailabilityProvider] backed by a remote datasource.
class RemoteAvailabilityProvider implements AvailabilityProvider {
  const RemoteAvailabilityProvider(this._remote);

  final AvailabilityRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> getSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final dtos = await _remote.getSlots(teacherId, from: from, to: to);
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, void>> publishSlot(
    TeacherAvailability slot,
  ) async {
    try {
      await _remote.publishSlot(slot.toDto());
      return const Right(null);
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, void>> withdrawSlot(
    String slotId,
  ) async {
    try {
      await _remote.withdrawSlot(slotId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
