import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';

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

  void setMethodHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) {
    messenger.setMockMethodCallHandler(methodChannel, handler);
  }

  setUp(() {
    setMethodHandler(null);
    messenger.setMockStreamHandler(eventChannel, null);
    InAppUpdate.resetInstallUpdateListenerForTesting();
  });

  group('InAppUpdate.checkForUpdate', () {
    test('maps native payload into AppUpdateInfo', () async {
      setMethodHandler((call) async {
        expect(call.method, 'checkForUpdate');
        return <String, Object?>{
          'updateAvailability': UpdateAvailability.updateAvailable.value,
          'immediateAllowed': true,
          'immediateAllowedPreconditions': <int>[1, 2],
          'flexibleAllowed': true,
          'flexibleAllowedPreconditions': <int>[3],
          'availableVersionCode': 88,
          'installStatus': InstallStatus.downloading.value,
          'packageName': 'de.test.app',
          'clientVersionStalenessDays': 5,
          'updatePriority': 4,
          'totalBytesToDownload': 1024,
          'bytesDownloaded': 512,
        };
      });

      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      expect(info.updateAvailability, UpdateAvailability.updateAvailable);
      expect(info.immediateUpdateAllowed, isTrue);
      expect(info.immediateAllowedPreconditions, <int>[1, 2]);
      expect(info.flexibleUpdateAllowed, isTrue);
      expect(info.flexibleAllowedPreconditions, <int>[3]);
      expect(info.availableVersionCode, 88);
      expect(info.installStatus, InstallStatus.downloading);
      expect(info.packageName, 'de.test.app');
      expect(info.clientVersionStalenessDays, 5);
      expect(info.updatePriority, 4);
      expect(info.totalBytesToDownload, 1024);
      expect(info.bytesDownloaded, 512);
    });
  });

  group('InAppUpdate.performImmediateUpdate', () {
    test('returns success when native call succeeds', () async {
      setMethodHandler((_) async => null);

      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();

      expect(result, AppUpdateResult.success);
    });

    test('returns userDeniedUpdate for USER_DENIED_UPDATE', () async {
      setMethodHandler((_) async {
        throw PlatformException(code: 'USER_DENIED_UPDATE');
      });

      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();

      expect(result, AppUpdateResult.userDeniedUpdate);
    });

    test('returns inAppUpdateFailed for IN_APP_UPDATE_FAILED', () async {
      setMethodHandler((_) async {
        throw PlatformException(code: 'IN_APP_UPDATE_FAILED');
      });

      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();

      expect(result, AppUpdateResult.inAppUpdateFailed);
    });

    test('rethrows unknown platform exceptions', () async {
      setMethodHandler((_) async {
        throw PlatformException(code: 'TASK_FAILURE');
      });

      expect(
        InAppUpdate.performImmediateUpdate(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('InAppUpdate.startFlexibleUpdate', () {
    test('returns success when native call succeeds', () async {
      setMethodHandler((_) async => null);

      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();

      expect(result, AppUpdateResult.success);
    });

    test('returns userDeniedUpdate for USER_DENIED_UPDATE', () async {
      setMethodHandler((_) async {
        throw PlatformException(code: 'USER_DENIED_UPDATE');
      });

      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();

      expect(result, AppUpdateResult.userDeniedUpdate);
    });

    test('returns inAppUpdateFailed for IN_APP_UPDATE_FAILED', () async {
      setMethodHandler((_) async {
        throw PlatformException(code: 'IN_APP_UPDATE_FAILED');
      });

      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();

      expect(result, AppUpdateResult.inAppUpdateFailed);
    });

    test('rethrows unknown platform exceptions', () async {
      setMethodHandler((_) async {
        throw PlatformException(code: 'Error during installation');
      });

      expect(
        InAppUpdate.startFlexibleUpdate(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('InAppUpdate complete/open helpers', () {
    test('completeFlexibleUpdate invokes native method', () async {
      setMethodHandler((call) async {
        expect(call.method, 'completeFlexibleUpdate');
        return null;
      });

      await InAppUpdate.completeFlexibleUpdate();
    });

    test('openAppStoreListing invokes native method', () async {
      setMethodHandler((call) async {
        expect(call.method, 'openAppStoreListing');
        return null;
      });

      await InAppUpdate.openAppStoreListing();
    });
  });

  group('InAppUpdate.installUpdateListener', () {
    test('installStatusFromCode maps known and unknown codes', () {
      expect(
        InstallStatus.fromCode(InstallStatus.downloaded.value),
        InstallStatus.downloaded,
      );
      expect(InstallStatus.fromCode(999), InstallStatus.unknown);
      expect(
        InAppUpdate.installStatusFromCode(InstallStatus.downloaded.value),
        InstallStatus.downloaded,
      );
    });

    test('UpdateAvailability.fromCode maps known and unknown codes', () {
      expect(
        UpdateAvailability.fromCode(
          UpdateAvailability.updateAvailable.value,
        ),
        UpdateAvailability.updateAvailable,
      );
      expect(UpdateAvailability.fromCode(999), UpdateAvailability.unknown);
    });

    test('caches the broadcast stream across getter accesses', () {
      expect(
        identical(
          InAppUpdate.installUpdateListener,
          InAppUpdate.installUpdateListener,
        ),
        isTrue,
      );
    });

    test('maps install status codes', () async {
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            events.success(InstallStatus.pending.value);
            events.success(InstallStatus.downloading.value);
            events.success(InstallStatus.downloaded.value);
            events.success(999);
          },
        ),
      );

      final List<InstallStatus> statuses = await InAppUpdate
          .installUpdateListener
          .take(4)
          .toList();

      expect(
        statuses,
        <InstallStatus>[
          InstallStatus.pending,
          InstallStatus.downloading,
          InstallStatus.downloaded,
          InstallStatus.unknown,
        ],
      );
    });

    test('maps every known install status code', () async {
      final Map<int, InstallStatus> expected = <int, InstallStatus>{
        InstallStatus.unknown.value: InstallStatus.unknown,
        InstallStatus.pending.value: InstallStatus.pending,
        InstallStatus.downloading.value: InstallStatus.downloading,
        InstallStatus.installing.value: InstallStatus.installing,
        InstallStatus.installed.value: InstallStatus.installed,
        InstallStatus.failed.value: InstallStatus.failed,
        InstallStatus.canceled.value: InstallStatus.canceled,
        InstallStatus.downloaded.value: InstallStatus.downloaded,
      };

      for (final MapEntry<int, InstallStatus> entry in expected.entries) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (_, events) => events.success(entry.key),
              ),
            );

        final InstallStatus status =
            await InAppUpdate.installUpdateListener.first;
        expect(status, entry.value);
      }
    });
  });

  group('AppUpdateInfo', () {
    test('equality hashCode and toString include all fields', () {
      final AppUpdateInfo first = _sampleInfo();
      final AppUpdateInfo second = _sampleInfo();
      final AppUpdateInfo different = _sampleInfo(totalBytesToDownload: 2048);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
      expect(first.toString(), contains('totalBytesToDownload: 1024'));
      expect(first.toString(), contains('bytesDownloaded: 512'));
    });

    test('operator equals returns false for non AppUpdateInfo', () {
      expect(_sampleInfo(), isNot(equals('other')));
    });
  });

  group('enum values', () {
    test('InstallStatus values match Play constants', () {
      expect(InstallStatus.unknown.value, 0);
      expect(InstallStatus.downloaded.value, 11);
    });

    test('UpdateAvailability values match Play constants', () {
      expect(UpdateAvailability.updateAvailable.value, 2);
      expect(
        UpdateAvailability.developerTriggeredUpdateInProgress.value,
        3,
      );
    });
  });
}

AppUpdateInfo _sampleInfo({int? totalBytesToDownload}) {
  return AppUpdateInfo(
    updateAvailability: UpdateAvailability.updateAvailable,
    immediateUpdateAllowed: true,
    immediateAllowedPreconditions: const <int>[1],
    flexibleUpdateAllowed: true,
    flexibleAllowedPreconditions: const <int>[2],
    availableVersionCode: 88,
    installStatus: InstallStatus.downloaded,
    packageName: 'de.test.app',
    clientVersionStalenessDays: 3,
    updatePriority: 4,
    totalBytesToDownload: totalBytesToDownload ?? 1024,
    bytesDownloaded: 512,
  );
}
