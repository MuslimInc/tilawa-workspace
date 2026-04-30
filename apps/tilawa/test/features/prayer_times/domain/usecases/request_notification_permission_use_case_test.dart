import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/services/notification_permission_service.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/request_notification_permission_use_case.dart';

import 'request_notification_permission_use_case_test.mocks.dart';

@GenerateMocks([NotificationPermissionService])
void main() {
  late MockNotificationPermissionService mockPermissions;
  late RequestNotificationPermissionUseCase useCase;

  setUp(() {
    mockPermissions = MockNotificationPermissionService();
    useCase = RequestNotificationPermissionUseCase(mockPermissions);
  });

  group('RequestNotificationPermissionUseCase', () {
    test(
      'returns Right(true) when notification permission is granted',
      () async {
        when(mockPermissions.requestPermission()).thenAnswer((_) async => true);

        final result = await useCase.call();

        expect(result.getOrElse(() => false), isTrue);
        verify(mockPermissions.requestPermission()).called(1);
      },
    );

    test(
      'returns Right(false) when notification permission is denied',
      () async {
        when(
          mockPermissions.requestPermission(),
        ).thenAnswer((_) async => false);

        final result = await useCase.call();

        expect(result.getOrElse(() => true), isFalse);
        verify(mockPermissions.requestPermission()).called(1);
      },
    );

    test('returns Left when permission service throws', () async {
      when(mockPermissions.requestPermission()).thenThrow(Exception('denied'));

      final result = await useCase.call();

      expect(result.fold((_) => true, (_) => false), isTrue);
    });
  });
}
