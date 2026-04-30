import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/prayer_times/domain/services/prayer_adhan_notification_service_interface.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/cancel_prayer_notifications_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'cancel_prayer_notifications_use_case_test.mocks.dart';

@GenerateMocks([IPrayerAdhanNotificationService])
void main() {
  late CancelPrayerNotificationsUseCase useCase;
  late MockIPrayerAdhanNotificationService mockService;

  setUp(() {
    mockService = MockIPrayerAdhanNotificationService();
    useCase = CancelPrayerNotificationsUseCase(mockService);
  });

  group('CancelPrayerNotificationsUseCase', () {
    test('delegates to service.cancelAllPrayerNotifications()', () async {
      when(mockService.cancelAllPrayerNotifications()).thenAnswer((_) async {});

      final result = await useCase();

      verify(mockService.cancelAllPrayerNotifications()).called(1);
      expect(result, const Right<Failure, void>(null));
    });

    test('calls service exactly once', () async {
      when(mockService.cancelAllPrayerNotifications()).thenAnswer((_) async {});

      await useCase();

      verifyNever(
        mockService.schedulePrayerNotifications(
          settings: anyNamed('settings'),
          prayerTimesForDays: anyNamed('prayerTimesForDays'),
          forceReschedule: anyNamed('forceReschedule'),
        ),
      );
    });

    test('returns Left(Failure) when service throws', () async {
      when(
        mockService.cancelAllPrayerNotifications(),
      ).thenThrow(Exception('cancel error'));

      final result = await useCase();

      expect(result.isLeft, isTrue);
    });
  });
}
