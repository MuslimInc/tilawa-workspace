import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/availability_override.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/teacher_profile_repository.dart';
import '../datasources/schedule_remote_data_source.dart';
import '../dtos/availability_override_dto.dart';
import '../dtos/weekly_schedule_dto.dart';
import '../mappers/schedule_mapper.dart';
import 'repository_error_mapper.dart';

/// [ScheduleRepository] backed by a [ScheduleRemoteDataSource]. Maps DTOs to
/// domain entities and remote exceptions to [QuranSessionsFailure].
class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl(
    this._remote, {
    this._teacherProfiles,
  });

  final ScheduleRemoteDataSource _remote;
  final TeacherProfileRepository? _teacherProfiles;

  Future<String?> _legacyOwnerUserId(String teacherProfileId) async {
    final profiles = _teacherProfiles;
    if (profiles == null) return null;
    final profileResult = await profiles.getProfileById(teacherProfileId);
    return profileResult.fold((_) => null, (profile) {
      final userId = profile.userId;
      return userId == teacherProfileId ? null : userId;
    });
  }

  WeeklyScheduleDto _canonicalizeDto(
    WeeklyScheduleDto dto,
    String teacherProfileId,
  ) => WeeklyScheduleDto(
    teacherId: teacherProfileId,
    timezone: dto.timezone,
    slotDurationMinutes: dto.slotDurationMinutes,
    minNoticeMinutes: dto.minNoticeMinutes,
    maxHorizonDays: dto.maxHorizonDays,
    bufferBeforeMinutes: dto.bufferBeforeMinutes,
    bufferAfterMinutes: dto.bufferAfterMinutes,
    weeklyRules: dto.weeklyRules,
    version: dto.version,
    updatedAt: dto.updatedAt,
  );

  Future<WeeklyScheduleDto?> _loadScheduleDto(String teacherProfileId) async {
    final primary = await _remote.getSchedule(teacherProfileId);
    if (primary != null) return _canonicalizeDto(primary, teacherProfileId);
    final legacyUserId = await _legacyOwnerUserId(teacherProfileId);
    if (legacyUserId == null) return null;
    final legacy = await _remote.getSchedule(legacyUserId);
    if (legacy == null) return null;
    return _canonicalizeDto(legacy, teacherProfileId);
  }

  Future<List<AvailabilityOverrideDto>> _loadOverrides(
    String teacherProfileId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final primary = await _remote.getOverrides(
      teacherProfileId,
      from: from,
      to: to,
    );
    if (primary.isNotEmpty) return primary;
    final legacyUserId = await _legacyOwnerUserId(teacherProfileId);
    if (legacyUserId == null) return primary;
    return _remote.getOverrides(legacyUserId, from: from, to: to);
  }

  @override
  Future<Either<QuranSessionsFailure, WeeklySchedule?>> getSchedule(
    String teacherId,
  ) async {
    try {
      final dto = await _loadScheduleDto(teacherId);
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
      final dtos = await _loadOverrides(teacherId, from: from, to: to);
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, AvailabilityOverride?>> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async {
    try {
      final dto = await _remote.getOverrideByDate(teacherId, dateKey);
      if (dto != null) return Right(dto.toDomain());
      final legacyUserId = await _legacyOwnerUserId(teacherId);
      if (legacyUserId == null) return const Right(null);
      final legacyDto = await _remote.getOverrideByDate(legacyUserId, dateKey);
      return Right(legacyDto?.toDomain());
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
