import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/auth/data/services/device_identity_service.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync mockPrefs;
  late DeviceIdentityServiceImpl service;

  const installationsChannel = MethodChannel(
    'plugins.flutter.io/firebase_app_installations',
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockPrefs = MockSharedPreferencesAsync();
    service = DeviceIdentityServiceImpl(mockPrefs);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(installationsChannel, null);
  });

  group('getDeviceId', () {
    test('returns Firebase installation id when plugin responds', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(installationsChannel, (call) async {
            if (call.method == 'FirebaseInstallations#getId') {
              return 'firebase_fid_123';
            }
            return null;
          });

      final id = await service.getDeviceId();

      expect(id, 'firebase_fid_123');
      verifyNever(() => mockPrefs.getString(any()));
    });

    test(
      'uses stable local id when Installations plugin is missing',
      () async {
        final stored = <String, String>{};
        when(() => mockPrefs.getString(any())).thenAnswer((invocation) async {
          return stored[invocation.positionalArguments.first as String];
        });
        when(() => mockPrefs.setString(any(), any())).thenAnswer((
          invocation,
        ) async {
          stored[invocation.positionalArguments[0] as String] =
              invocation.positionalArguments[1] as String;
        });

        final first = await service.getDeviceId();
        final second = await service.getDeviceId();

        expect(first, startsWith('local_'));
        expect(second, first);
        verify(() => mockPrefs.getString('tilawa_local_device_id')).called(1);
        verify(
          () => mockPrefs.setString('tilawa_local_device_id', first),
        ).called(1);
      },
    );

    test(
      'reuses persisted local id without calling Installations again',
      () async {
        when(
          () => mockPrefs.getString('tilawa_local_device_id'),
        ).thenAnswer((_) async => 'local_persisted');

        final id = await service.getDeviceId();

        expect(id, 'local_persisted');
        verifyNever(() => mockPrefs.setString(any(), any()));
      },
    );
  });
}
