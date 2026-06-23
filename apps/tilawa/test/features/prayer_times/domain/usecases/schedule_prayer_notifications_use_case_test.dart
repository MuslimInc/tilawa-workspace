import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/schedule_prayer_notifications_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'schedule_prayer_notifications_use_case_test.mocks.dart';

@GenerateMocks([IPrayerAdhanNotificationService, PrayerTimesRepository])
void main() {
  late SchedulePrayerNotificationsUseCase useCase;
  late MockIPrayerAdhanNotificationService mockService;
  late MockPrayerTimesRepository mockRepository;

  const tSettings = PrayerSettingsEntity(
    savedLatitude: 30.0,
    savedLongitude: 31.0,
  );

  final tNow = DateTime(2025, 1, 1, 12);

  PrayerTimeEntity buildPrayerDay(DateTime date) => PrayerTimeEntity(
    date: date,
    fajr: date.copyWith(hour: 5),
    sunrise: date.copyWith(hour: 6),
    dhuhr: date.copyWith(hour: 12),
    asr: date.copyWith(hour: 15),
    maghrib: date.copyWith(hour: 17),
    isha: date.copyWith(hour: 19),
    midnight: date.copyWith(hour: 23),
    lastThird: date.copyWith(hour: 2),
    latitude: 30.0,
    longitude: 31.0,
    timezone: 'Africa/Cairo',
  );

  setUp(() {
    mockService = MockIPrayerAdhanNotificationService();
    mockRepository = MockPrayerTimesRepository();
    useCase = SchedulePrayerNotificationsUseCase(mockService, mockRepository);
  });

  group('SchedulePrayerNotificationsUseCase', () {
    test('returns Right(null) when repository and service succeed', () async {
      final days = List.generate(
        14,
        (i) => buildPrayerDay(tNow.add(Duration(days: i))),
      );
      when(
        mockRepository.getPrayerTimesForRange(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          settings: anyNamed('settings'),
        ),
      ).thenAnswer((_) async => days);

      when(
        mockService.schedulePrayerNotifications(
          settings: anyNamed('settings'),
          prayerTimesForDays: anyNamed('prayerTimesForDays'),
          forceReschedule: anyNamed('forceReschedule'),
        ),
      ).thenAnswer((_) async {});

      final result = await useCase(
        settings: tSettings,
        latitude: 30.0,
        longitude: 31.0,
      );

      expect(result, const Right<Failure, void>(null));
    });

    test('passes forceReschedule=true to service when requested', () async {
      final days = [buildPrayerDay(tNow)];
      when(
        mockRepository.getPrayerTimesForRange(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          settings: anyNamed('settings'),
        ),
      ).thenAnswer((_) async => days);

      when(
        mockService.schedulePrayerNotifications(
          settings: anyNamed('settings'),
          prayerTimesForDays: anyNamed('prayerTimesForDays'),
          forceReschedule: anyNamed('forceReschedule'),
        ),
      ).thenAnswer((_) async {});

      await useCase(
        settings: tSettings,
        latitude: 30.0,
        longitude: 31.0,
        forceReschedule: true,
      );

      verify(
        mockService.schedulePrayerNotifications(
          settings: anyNamed('settings'),
          prayerTimesForDays: anyNamed('prayerTimesForDays'),
          forceReschedule: true,
        ),
      ).called(1);
    });

    test('passes forceReschedule=false by default', () async {
      final days = [buildPrayerDay(tNow)];
      when(
        mockRepository.getPrayerTimesForRange(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          settings: anyNamed('settings'),
        ),
      ).thenAnswer((_) async => days);

      when(
        mockService.schedulePrayerNotifications(
          settings: anyNamed('settings'),
          prayerTimesForDays: anyNamed('prayerTimesForDays'),
          forceReschedule: anyNamed('forceReschedule'),
        ),
      ).thenAnswer((_) async {});

      await useCase(settings: tSettings, latitude: 30.0, longitude: 31.0);

      verify(
        mockService.schedulePrayerNotifications(
          settings: anyNamed('settings'),
          prayerTimesForDays: anyNamed('prayerTimesForDays'),
          forceReschedule: false,
        ),
      ).called(1);
    });

    test('returns Left when repository returns empty list', () async {
      when(
        mockRepository.getPrayerTimesForRange(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          settings: anyNamed('settings'),
        ),
      ).thenAnswer((_) async => []);

      final result = await useCase(
        settings: tSettings,
        latitude: 30.0,
        longitude: 31.0,
      );

      expect(result.isLeft(), isTrue);
      verifyNever(
        mockService.schedulePrayerNotifications(
          settings: anyNamed('settings'),
          prayerTimesForDays: anyNamed('prayerTimesForDays'),
          forceReschedule: anyNamed('forceReschedule'),
        ),
      );
    });

    test('returns Left and does not rethrow when repository throws', () async {
      when(
        mockRepository.getPrayerTimesForRange(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          settings: anyNamed('settings'),
        ),
      ).thenThrow(Exception('Network error'));

      final result = await useCase(
        settings: tSettings,
        latitude: 30.0,
        longitude: 31.0,
      );

      expect(result.isLeft(), isTrue);
    });

    test('returns Left and does not rethrow when service throws', () async {
      final days = [buildPrayerDay(tNow)];
      when(
        mockRepository.getPrayerTimesForRange(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          settings: anyNamed('settings'),
        ),
      ).thenAnswer((_) async => days);

      when(
        mockService.schedulePrayerNotifications(
          settings: anyNamed('settings'),
          prayerTimesForDays: anyNamed('prayerTimesForDays'),
          forceReschedule: anyNamed('forceReschedule'),
        ),
      ).thenThrow(Exception('Notification error'));

      final result = await useCase(
        settings: tSettings,
        latitude: 30.0,
        longitude: 31.0,
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
