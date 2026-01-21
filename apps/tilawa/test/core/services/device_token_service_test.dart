import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/services/device_token_service.dart';

import '../../features/auth/helpers/auth_mock_helper.mocks.dart';

void main() {
  late DeviceTokenServiceImpl deviceTokenService;
  late MockFirebaseMessaging mockFirebaseMessaging;

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    deviceTokenService = DeviceTokenServiceImpl(mockFirebaseMessaging);
  });

  group('DeviceTokenServiceImpl', () {
    test('getToken calls FirebaseMessaging.getToken', () async {
      // Arrange
      const tToken = 'test_token';
      when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => tToken);

      // Act
      final String? result = await deviceTokenService.getToken();

      // Assert
      verify(mockFirebaseMessaging.getToken()).called(1);
      expect(result, tToken);
    });

    test(
      'onTokenRefresh returns stream from FirebaseMessaging.onTokenRefresh',
      () {
        // Arrange
        const tToken = 'refreshed_token';
        final Stream<String> tStream = Stream.value(tToken);
        when(mockFirebaseMessaging.onTokenRefresh).thenAnswer((_) => tStream);

        // Act
        final Stream<String> result = deviceTokenService.onTokenRefresh;

        // Assert
        expect(result, tStream);
        verify(mockFirebaseMessaging.onTokenRefresh).called(1);
      },
    );
  });
}
