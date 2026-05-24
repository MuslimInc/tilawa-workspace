import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';
import 'package:tilawa/core/services/quran_assets_prefetch_policy_service.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/settings/domain/usecases/get_app_info.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_core/entities/app_info.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../../../downloads/helpers/mock_helper.mocks.dart';

class MockGetAppInfo extends Mock implements GetAppInfo {
  @override
  Future<AppInfo> call() => super.noSuchMethod(
    Invocation.method(#call, []),
    returnValue: Future.value(
      const AppInfo(
        version: '1.0.0',
        buildNumber: '1',
        appName: 'Tilawa',
        packageName: 'com.tilawa.app',
      ),
    ),
  );
}

const AppInfo testAppInfo = AppInfo(
  version: '1.0.0',
  buildNumber: '1',
  appName: 'Tilawa',
  packageName: 'com.tilawa.app',
);

final GetIt getIt = GetIt.instance;

void main() {
  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  group('SettingsCubit', () {
    late SettingsCubit cubit;
    late MockDownloadServiceInterface mockDownloadService;
    late MockDownloadsRepository mockDownloadsRepository;
    late MockDownloadNotificationService mockDownloadNotificationService;
    late MockGetAppInfo mockGetAppInfo;

    setUp(() async {
      // Clean up GetIt manually
      if (getIt.isRegistered<DownloadQueueManager>()) {
        getIt.unregister<DownloadQueueManager>();
      }
      if (getIt.isRegistered<DownloadServiceInterface>()) {
        getIt.unregister<DownloadServiceInterface>();
      }
      if (getIt.isRegistered<DownloadsRepository>()) {
        getIt.unregister<DownloadsRepository>();
      }
      if (getIt.isRegistered<DownloadNotificationService>()) {
        getIt.unregister<DownloadNotificationService>();
      }
      if (getIt.isRegistered<SharedPreferencesAsync>()) {
        getIt.unregister<SharedPreferencesAsync>();
      }

      mockDownloadService = MockDownloadServiceInterface();
      mockDownloadsRepository = MockDownloadsRepository();
      mockDownloadNotificationService = MockDownloadNotificationService();
      mockGetAppInfo = MockGetAppInfo();

      when(mockGetAppInfo()).thenAnswer(
        (_) async => const AppInfo(
          version: '1.0.0',
          buildNumber: '1',
          appName: 'Tilawa',
          packageName: 'com.tilawa.app',
        ),
      );

      when(
        mockDownloadService.getActiveDownloadIds(),
      ).thenAnswer((_) async => []);
      when(
        mockDownloadService.globalProgressStream,
      ).thenAnswer((_) => const Stream.empty());

      getIt.registerSingleton<DownloadServiceInterface>(mockDownloadService);
      getIt.registerSingleton<DownloadsRepository>(mockDownloadsRepository);
      getIt.registerSingleton<DownloadNotificationService>(
        mockDownloadNotificationService,
      );

      when(mockDownloadNotificationService.initialize()).thenAnswer((_) async {
        return;
      });
      when(
        mockDownloadNotificationService.showDownloadProgress(
          downloadId: anyNamed('downloadId'),
          title: anyNamed('title'),
          reciterName: anyNamed('reciterName'),
          progress: anyNamed('progress'),
          status: anyNamed('status'),
          pendingMessage: anyNamed('pendingMessage'),
          progressMessage: anyNamed('progressMessage'),
          completeMessage: anyNamed('completeMessage'),
          failedMessage: anyNamed('failedMessage'),
        ),
      ).thenAnswer((_) async {
        return;
      });
      when(mockDownloadNotificationService.cancelNotification(any)).thenAnswer((
        _,
      ) async {
        return;
      });

      final dqm = DownloadQueueManager(
        mockDownloadService,
        mockDownloadNotificationService,
      );
      dqm.maxConcurrentDownloads = 2; // Default for test

      if (getIt.isRegistered<DownloadQueueManager>()) {
        getIt.unregister<DownloadQueueManager>();
      }
      getIt.registerSingleton<DownloadQueueManager>(dqm);
      getIt.registerSingleton<SharedPreferencesAsync>(
        MockSharedPreferencesAsync(),
      );

      // We must initialize the QueueManager because SettingsCubit might access it
      await dqm.initialize();
      // SettingsCubit calls instance.maxConcurrentDownloads getter/setter.

      cubit = SettingsCubit(
        getIt<DownloadQueueManager>(),
        mockGetAppInfo,
        QuranAssetsPrefetchPolicyService.fromPreferences(
          getIt<SharedPreferencesAsync>(),
        ),
      );
    });

    tearDown(() {
      cubit.close();
      if (getIt.isRegistered<SharedPreferencesAsync>()) {
        getIt.unregister<SharedPreferencesAsync>();
      }
    });

    test('initial state has default maxConcurrentDownloads of 2', () async {
      // Wait for app info to be fetched
      await Future.delayed(Duration.zero);
      expect(cubit.state, const SettingsState(appInfo: testAppInfo));
      expect(getIt<DownloadQueueManager>().maxConcurrentDownloads, 2);
    });

    blocTest<SettingsCubit, SettingsState>(
      'emits new state when setMaxConcurrentDownloads is called',
      build: () => cubit,
      act: (cubit) => cubit.setMaxConcurrentDownloads(4),
      expect: () => [
        const SettingsState(maxConcurrentDownloads: 4, appInfo: testAppInfo),
      ],
      verify: (_) {
        expect(getIt<DownloadQueueManager>().maxConcurrentDownloads, 4);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updates DownloadQueueManager when setting changes',
      build: () => cubit,
      act: (cubit) => cubit.setMaxConcurrentDownloads(3),
      verify: (_) {
        expect(getIt<DownloadQueueManager>().maxConcurrentDownloads, 3);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggleRestorePlaybackState updates state',
      build: () => cubit,
      act: (cubit) => cubit.toggleRestorePlaybackState(false),
      expect: () => [
        const SettingsState(restorePlaybackState: false, appInfo: testAppInfo),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggleRestorePlaybackState can be toggled back to true',
      build: () => cubit,
      act: (cubit) async {
        await cubit.toggleRestorePlaybackState(false);
        await cubit.toggleRestorePlaybackState(true);
      },
      expect: () => [
        const SettingsState(restorePlaybackState: false, appInfo: testAppInfo),
        const SettingsState(appInfo: testAppInfo),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'toggleSleepTimerEnabled updates state',
      build: () => cubit,
      act: (cubit) => cubit.toggleSleepTimerEnabled(false),
      expect: () => [
        const SettingsState(isSleepTimerEnabled: false, appInfo: testAppInfo),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'setShowPrayerTimesAlertChipLabels updates state',
      build: () => cubit,
      act: (cubit) => cubit.setShowPrayerTimesAlertChipLabels(false),
      expect: () => [
        const SettingsState(
          showPrayerTimesAlertChipLabels: false,
          appInfo: testAppInfo,
        ),
      ],
    );

    group('Serialization', () {
      test('fromJson returns correct state', () {
        expect(
          cubit.fromJson({
            'maxConcurrentDownloads': 5,
            'restorePlaybackState': true,
            'isSleepTimerEnabled': false,
          }),
          const SettingsState(
            maxConcurrentDownloads: 5,
            isSleepTimerEnabled: false,
          ),
        );
      });

      test('fromJson handles invalid json', () {
        expect(
          cubit.fromJson({'maxConcurrentDownloads': 'invalid'}),
          const SettingsState(), // Default
        );
      });

      test('toJson returns correct map', () {
        expect(cubit.toJson(const SettingsState(maxConcurrentDownloads: 3)), {
          'maxConcurrentDownloads': 3,
          'restorePlaybackState': true,
          'isSleepTimerEnabled': true,
          'prefetchQuranAssetsOnWifiOnly': true,
          'showPrayerTimesAlertChipLabels': true,
        });
      });

      test('SettingsState.copyWith preserves values when null is passed', () {
        const originalState = SettingsState(maxConcurrentDownloads: 5);
        // Call copyWith with null to test the ?? fallback on line 22
        final SettingsState newState = originalState.copyWith();
        expect(newState.maxConcurrentDownloads, 5);
        expect(newState.restorePlaybackState, true);
      });
    });
  });
}
