import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/availability_override.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_data_source.dart';
import '../mappers/schedule_mapper.dart';
import 'repository_error_mapper.dart';

/// [ScheduleRepository] backed by a [ScheduleRemoteDataSource]. Maps DTOs to
/// domain entities and remote exceptions to [QuranSessionsFailure].
class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl(this._remote);

  final ScheduleRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, WeeklySchedule?>> getSchedule(
    String teacherId,
  ) async {
    try {
      final dto = await _remote.getSchedule(teacherId);
      return Right(dto?.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, void>> saveSchedule(
    WeeklySchedule schedule,
  ) async {
    try {
      await _remote.saveSchedule(schedule.toDto());
      return const Right(null);
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<AvailabilityOverride>>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final dtos = await _remote.getOverrides(teacherId, from: from, to: to);
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, void>> saveOverride(
    String teacherId,
    AvailabilityOverride override,
  ) async {
    try {
      await _remote.saveOverride(teacherId, override.toDto());
      return const Right(null);
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, void>> removeOverride(
    String teacherId,
    String dateKey,
  ) async {
    try {
      await _remote.removeOverride(teacherId, dateKey);
      return const Right(null);
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
