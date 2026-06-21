import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:tilawa/features/in_app_update/data/datasources/play_in_app_update_platform_data_source.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_availability.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel = MethodChannel(
    'de.ffuf.in_app_update/methods',
  );
  const EventChannel eventChannel = EventChannel(
    'de.ffuf.in_app_update/stateEvents',
  );

  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final PlayInAppUpdatePlatformDataSource dataSource =
      PlayInAppUpdatePlatformDataSource();

  void setMethodHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) {
    messenger.setMockMethodCallHandler(methodChannel, handler);
  }

  setUp(() {
    setMethodHandler(null);
    messenger.setMockStreamHandler(eventChannel, null);
    InAppUpdate.resetInstallUpdateListenerForTesting();
    dataSource.androidPlatformForTesting = null;
  });

  group('PlayInAppUpdatePlatformDataSource', () {
    test('isSupported reflects host platform', () async {
      expect(await dataSource.isSupported(), isA<bool>());
    });

    test('maps checkForUpdate payload into availability', () async {
      setMethodHandler((call) async {
        expect(call.method, 'checkForUpdate');
        return <String, Object?>{
          'updateAvailability': UpdateAvailability.updateAvailable.value,
          'immediateAllowed': true,
          'flexibleAllowed': true,
          'installStatus': InstallStatus.downloaded.value,
          'packageName': 'com.tilawa.app',
          'updatePriority': 1,
        };
      });

      final Either<Failure, InAppUpdateAvailability> result = await dataSource
          .checkAvailability();

      result.fold(
        (_) => fail('expected Right'),
        (InAppUpdateAvailability availability) {
          expect(availability.updateAvailable, isTrue);
          expect(availability.immediateUpdateAllowed, isTrue);
          expect(availability.flexibleUpdateAllowed, isTrue);
          expect(availability.flexibleUpdateDownloaded, isTrue);
        },
      );
    });

    test('logs and maps download bytes when Play reports them', () async {
      setMethodHandler((call) async {
        return <String, Object?>{
          'updateAvailability': UpdateAvailability.updateAvailable.value,
          'immediateAllowed': false,
          'flexibleAllowed': true,
          'installStatus': InstallStatus.downloading.value,
          'packageName': 'com.tilawa.app',
          'updatePriority': 0,
          'totalBytesToDownload': 2048,
        };
      });

      final Either<Failure, InAppUpdateAvailability> result = await dataSource
          .checkAvailability();

      expect(result.isRight(), isTrue);
    });

    test('returns unavailable when no foreground activity', () async {
      setMethodHandler((_) async {
        throw PlatformException(
          code: 'REQUIRE_FOREGROUND_ACTIVITY',
          message: 'in_app_update requires a foreground activity',
        );
      });

      final Either<Failure, InAppUpdateAvailability> result = await dataSource
          .checkAvailability();

      result.fold(
        (_) => fail('expected Right'),
        (InAppUpdateAvailability availability) {
          expect(availability.updateAvailable, isFalse);
          expect(availability.immediateUpdateAllowed, isFalse);
          expect(availability.flexibleUpdateAllowed, isFalse);
        },
      );
    });

    test('returns unavailable when app is not owned by Play', () async {
      setMethodHandler((_) async {
        throw PlatformException(
          code: 'TASK_FAILURE',
          message: 'Install Error(-10): app not owned',
        );
      });

      final Either<Failure, InAppUpdateAvailability> result = await dataSource
          .checkAvailability();

      result.fold(
        (_) => fail('expected Right'),
        (InAppUpdateAvailability availability) {
          expect(availability.updateAvailable, isFalse);
          expect(availability.immediateUpdateAllowed, isFalse);
          expect(availability.flexibleUpdateAllowed, isFalse);
        },
      );
    });

    test('returns unavailable when Play Store is missing', () async {
      setMethodHandler((_) async {
        throw PlatformException(
          code: 'TASK_FAILURE',
          message:
              '-9: Install Error(-9): The Play Store app is either not '
              'installed or not the official version.',
        );
      });

      final Either<Failure, InAppUpdateAvailability> result = await dataSource
          .checkAvailability();

      result.fold(
        (_) => fail('expected Right'),
        (InAppUpdateAvailability availability) {
          expect(availability.updateAvailable, isFalse);
        },
      );
    });

    test('returns checkFailed for other platform exceptions', () async {
      setMethodHandler((_) async {
        throw PlatformException(code: 'TASK_FAILURE', message: 'other');
      });

      final Either<Failure, InAppUpdateAvailability> result = await dataSource
          .checkAvailability();

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure failure) => expect(failure, isA<InAppUpdateFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test(
      'maps unknown Play availability codes to unavailable update',
      () async {
        setMethodHandler((call) async {
          return <String, Object?>{
            'updateAvailability': 999,
            'immediateAllowed': true,
            'flexibleAllowed': true,
            'installStatus': InstallStatus.downloaded.value,
            'packageName': 'com.tilawa.app',
            'updatePriority': 1,
          };
        });

        final Either<Failure, InAppUpdateAvailability> result = await dataSource
            .checkAvailability();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('expected Right'), (
          InAppUpdateAvailability availability,
        ) {
          expect(availability.updateAvailable, isFalse);
        });
      },
    );

    test('returns checkFailed for generic exceptions', () async {
      setMethodHandler((_) async {
        throw Exception('boom');
      });

      final Either<Failure, InAppUpdateAvailability> result = await dataSource
          .checkAvailability();

      expect(result.isLeft(), isTrue);
    });

    test(
      'performImmediateUpdate handles success, denial, and failure',
      () async {
        setMethodHandler((call) async {
          expect(call.method, 'performImmediateUpdate');
          return null;
        });
        expect((await dataSource.performImmediateUpdate()).isRight(), isTrue);

        setMethodHandler((_) async {
          throw PlatformException(code: 'USER_DENIED_UPDATE');
        });
        expect((await dataSource.performImmediateUpdate()).isRight(), isTrue);

        setMethodHandler((_) async {
          throw PlatformException(code: 'IN_APP_UPDATE_FAILED');
        });
        final Either<Failure, void> failed = await dataSource
            .performImmediateUpdate();
        expect(failed.isLeft(), isTrue);

        setMethodHandler((_) async {
          throw PlatformException(code: 'UNKNOWN');
        });
        expect((await dataSource.performImmediateUpdate()).isLeft(), isTrue);

        setMethodHandler((_) async {
          throw Exception('boom');
        });
        expect((await dataSource.performImmediateUpdate()).isLeft(), isTrue);
      },
    );

    test('openAppStoreListing succeeds and maps failures', () async {
      setMethodHandler((call) async {
        expect(call.method, 'openAppStoreListing');
        return null;
      });
      expect((await dataSource.openAppStoreListing()).isRight(), isTrue);

      setMethodHandler((_) async {
        throw PlatformException(code: 'OPEN_STORE_FAILED');
      });
      expect((await dataSource.openAppStoreListing()).isLeft(), isTrue);

      setMethodHandler((_) async {
        throw Exception('boom');
      });
      expect((await dataSource.openAppStoreListing()).isLeft(), isTrue);
    });

    test(
      'startFlexibleUpdate maps success, non-success, and failures',
      () async {
        setMethodHandler((call) async {
          expect(call.method, 'startFlexibleUpdate');
          return null;
        });
        expect(
          await dataSource.startFlexibleUpdate(),
          const Right<Failure, bool>(true),
        );

        setMethodHandler((_) async {
          throw PlatformException(code: 'USER_DENIED_UPDATE');
        });
        expect(
          await dataSource.startFlexibleUpdate(),
          const Right<Failure, bool>(false),
        );

        setMethodHandler((_) async {
          throw PlatformException(code: 'UNKNOWN');
        });
        expect((await dataSource.startFlexibleUpdate()).isLeft(), isTrue);

        setMethodHandler((_) async {
          throw Exception('boom');
        });
        expect((await dataSource.startFlexibleUpdate()).isLeft(), isTrue);
      },
    );

    test('completeFlexibleUpdate succeeds and maps failures', () async {
      setMethodHandler((call) async {
        expect(call.method, 'completeFlexibleUpdate');
        return null;
      });
      expect((await dataSource.completeFlexibleUpdate()).isRight(), isTrue);

      setMethodHandler((_) async {
        throw PlatformException(code: 'IN_APP_UPDATE_FAILED');
      });
      expect((await dataSource.completeFlexibleUpdate()).isLeft(), isTrue);

      setMethodHandler((_) async {
        throw Exception('boom');
      });
      expect((await dataSource.completeFlexibleUpdate()).isLeft(), isTrue);
    });

    test(
      'onFlexibleUpdateDownloaded returns empty stream off Android host',
      () async {
        dataSource.androidPlatformForTesting = false;

        expect(await dataSource.onFlexibleUpdateDownloaded.isEmpty, isTrue);
      },
    );

    test('onFlexibleUpdateDownloaded caches stream on Android host', () {
      dataSource.androidPlatformForTesting = true;

      expect(
        identical(
          dataSource.onFlexibleUpdateDownloaded,
          dataSource.onFlexibleUpdateDownloaded,
        ),
        isTrue,
      );
    });

    test(
      'onFlexibleUpdateDownloaded emits when Play reports downloaded status',
      () async {
        dataSource.androidPlatformForTesting = true;
        messenger.setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (_, events) {
              events.success(InstallStatus.downloading.value);
              events.success(InstallStatus.downloaded.value);
            },
          ),
        );

        final List<void> events = await dataSource.onFlexibleUpdateDownloaded
            .take(1)
            .toList();

        expect(events, hasLength(1));
      },
    );
  });
}
