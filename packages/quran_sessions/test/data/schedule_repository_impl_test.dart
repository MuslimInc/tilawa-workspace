import 'package:checks/checks.dart';
import 'package:quran_sessions/src/data/datasources/schedule_remote_data_source.dart';
import 'package:quran_sessions/src/data/dtos/availability_override_dto.dart';
import 'package:quran_sessions/src/data/dtos/weekly_schedule_dto.dart';
import 'package:quran_sessions/src/data/exceptions/remote_exception.dart';
import 'package:quran_sessions/src/data/mappers/schedule_mapper.dart';
import 'package:quran_sessions/src/data/repositories/schedule_repository_impl.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:test/test.dart';

class _FakeScheduleRemoteDataSource implements ScheduleRemoteDataSource {
  WeeklyScheduleDto? schedule;
  Object? throwOnSave;

  @override
  Future<WeeklyScheduleDto?> getSchedule(String teacherId) async => schedule;

  @override
  Future<void> saveSchedule(WeeklyScheduleDto schedule) async {
    if (throwOnSave != null) throw throwOnSave!;
    this.schedule = schedule;
  }

  @override
  Future<List<AvailabilityOverrideDto>> getOverrides(
    String teacherId, {
    DateTime? from,
    DateTime? to,
  }) async => const [];

  @override
  Future<AvailabilityOverrideDto?> getOverrideByDate(
    String teacherId,
    String dateKey,
  ) async => null;

  @override
  Future<void> saveOverride(
    String teacherId,
    AvailabilityOverrideDto override,
  ) async {}

  @override
  Future<void> removeOverride(String teacherId, String dateKey) async {}
}

void main() {
  group('ScheduleRepositoryImpl', () {
    test('saveSchedule persists through remote datasource', () async {
      final remote = _FakeScheduleRemoteDataSource();
      final repo = ScheduleRepositoryImpl(remote);
      final dto = WeeklyScheduleDto(
        teacherId: 'teacher_1',
        timezone: 'Africa/Cairo',
        slotDurationMinutes: 30,
        minNoticeMinutes: 120,
        maxHorizonDays: 30,
        bufferBeforeMinutes: 0,
        bufferAfterMinutes: 0,
        weeklyRules: const {
          'sat': [
            {'start': '09:00', 'end': '17:00'},
          ],
        },
        version: 1,
      );

      final result = await repo.saveSchedule(dto.toDomain());

      check(result.isRight()).isTrue();
      check(remote.schedule?.teacherId).equals('teacher_1');
    });

    test('saveSchedule maps remote exceptions to failures', () async {
      final remote = _FakeScheduleRemoteDataSource()
        ..throwOnSave = const NetworkException();
      final repo = ScheduleRepositoryImpl(remote);
      final dto = WeeklyScheduleDto(
        teacherId: 'teacher_1',
        timezone: 'Africa/Cairo',
        slotDurationMinutes: 30,
        minNoticeMinutes: 120,
        maxHorizonDays: 30,
        bufferBeforeMinutes: 0,
        bufferAfterMinutes: 0,
        weeklyRules: const {
          'sat': [
            {'start': '09:00', 'end': '17:00'},
          ],
        },
        version: 1,
      );

      final result = await repo.saveSchedule(dto.toDomain());

      check(result.isLeft()).isTrue();
      result.fold(
        (failure) => check(failure).isA<NetworkFailure>(),
        (_) => fail('expected Left'),
      );
    });
  });
}
