import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/check_prayer_alarm_capability_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/value_objects/prayer_alarm_capability.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'check_prayer_alarm_capability_use_case_test.mocks.dart';

@GenerateMocks([
  IPrayerAdhanNotificationService,
  NotificationPermissionService,
  IAdhanAlarmPlayer,
])
void main() {
  late CheckPrayerAlarmCapabilityUseCase useCase;
  late MockIPrayerAdhanNotificationService mockService;
  late MockNotificationPermissionService mockPermissions;
  late MockIAdhanAlarmPlayer mockAdhanPlayer;

  setUp(() {
    mockService = MockIPrayerAdhanNotificationService();
    mockPermissions = MockNotificationPermissionService();
    mockAdhanPlayer = MockIAdhanAlarmPlayer();
    when(
      mockAdhanPlayer.isIgnoringBatteryOptimizations(),
    ).thenAnswer((_) async => true);
    when(mockAdhanPlayer.manufacturer()).thenAnswer((_) async => null);
    useCase = CheckPrayerAlarmCapabilityUseCase(
      mockService,
      mockPermissions,
      mockAdhanPlayer,
    );
  });

  group('CheckPrayerAlarmCapabilityUseCase', () {
    test('returns fully capable when both checks return true', () async {
      when(mockService.canScheduleExactAlarms()).thenAnswer((_) async => true);
      when(mockPermissions.isPermissionGranted()).thenAnswer((_) async => true);

      final result = await useCase();

      expect(result, isA<Right<Failure, PrayerAlarmCapability>>());
      final capability = result.getOrElse(
        () => const PrayerAlarmCapability(
          canScheduleExact: false,
          hasNotificationPermission: false,
        ),
      );
      expect(capability.canScheduleExact, isTrue);
      expect(capability.hasNotificationPermission, isTrue);
      expect(capability.isFullyCapable, isTrue);
    });

    test(
      'returns canScheduleExact=false when exact alarm not granted',
      () async {
        when(
          mockService.canScheduleExactAlarms(),
        ).thenAnswer((_) async => false);
        when(
          mockPermissions.isPermissionGranted(),
        ).thenAnswer((_) async => true);

        final result = await useCase();

        result.fold((l) => fail('Expected Right but got Left: $l'), (
          capability,
        ) {
          expect(capability.canScheduleExact, isFalse);
          expect(capability.hasNotificationPermission, isTrue);
          expect(capability.isFullyCapable, isFalse);
        });
      },
    );

    test(
      'returns hasNotificationPermission=false when permission not granted',
      () async {
        when(
          mockService.canScheduleExactAlarms(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissions.isPermissionGranted(),
        ).thenAnswer((_) async => false);

        final result = await useCase();

        result.fold((l) => fail('Expected Right but got Left: $l'), (
          capability,
        ) {
          expect(capability.canScheduleExact, isTrue);
          expect(capability.hasNotificationPermission, isFalse);
          expect(capability.isFullyCapable, isFalse);
        });
      },
    );

    test(
      'defaults canScheduleExact to false when service throws (fail-soft)',
      () async {
        when(
          mockService.canScheduleExactAlarms(),
        ).thenThrow(Exception('platform error'));
        when(
          mockPermissions.isPermissionGranted(),
        ).thenAnswer((_) async => true);

        // Should not throw
        final result = await useCase();

        result.fold((l) => fail('Expected Right but got Left: $l'), (
          capability,
        ) {
          expect(capability.canScheduleExact, isFalse);
          expect(capability.hasNotificationPermission, isTrue);
        });
      },
    );

    test(
      'defaults hasNotificationPermission to false when permissions service throws (fail-soft)',
      () async {
        when(
          mockService.canScheduleExactAlarms(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissions.isPermissionGranted(),
        ).thenThrow(Exception('permission error'));

        final result = await useCase();

        result.fold((l) => fail('Expected Right but got Left: $l'), (
          capability,
        ) {
          expect(capability.canScheduleExact, isTrue);
          expect(capability.hasNotificationPermission, isFalse);
        });
      },
    );

    test('returns both false when both services throw', () async {
      when(mockService.canScheduleExactAlarms()).thenThrow(Exception('error'));
      when(mockPermissions.isPermissionGranted()).thenThrow(Exception('error'));

      final result = await useCase();

      result.fold((l) => fail('Expected Right but got Left: $l'), (capability) {
        expect(capability.canScheduleExact, isFalse);
        expect(capability.hasNotificationPermission, isFalse);
        expect(capability.isFullyCapable, isFalse);
      });
    });

    test('flags Transsion Infinix ROM for autostart guidance', () async {
      when(mockService.canScheduleExactAlarms()).thenAnswer((_) async => true);
      when(mockPermissions.isPermissionGranted()).thenAnswer((_) async => true);
      when(mockAdhanPlayer.manufacturer()).thenAnswer((_) async => 'INFINIX');

      final result = await useCase();

      result.fold((l) => fail('Expected Right but got Left: $l'), (
        capability,
      ) {
        expect(capability.oemRequiresAutostart, isTrue);
      });
    });

    test(
      'returns isIgnoringBatteryOptimizations=false when adhan player reports false',
      () async {
        when(
          mockService.canScheduleExactAlarms(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissions.isPermissionGranted(),
        ).thenAnswer((_) async => true);
        when(
          mockAdhanPlayer.isIgnoringBatteryOptimizations(),
        ).thenAnswer((_) async => false);

        final result = await useCase();

        result.fold((l) => fail('Expected Right but got Left: $l'), (
          capability,
        ) {
          expect(capability.isIgnoringBatteryOptimizations, isFalse);
        });
      },
    );
  });
}
