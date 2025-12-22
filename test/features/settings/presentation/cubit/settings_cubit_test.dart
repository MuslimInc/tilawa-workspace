import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/downloads/data/services/download_notification_service.dart';
import 'package:muzakri/features/downloads/data/services/download_queue_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/settings/presentation/cubit/settings_cubit.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';

class MockDownloadService extends Mock implements DownloadService {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

class MockDownloadNotificationService extends Mock
    implements DownloadNotificationService {}

final GetIt getIt = GetIt.instance;

void main() {
  setUpAll(() async {
    registerFallbackValue(DownloadStatus.pending);
    await initializeHydratedStorageForTest();
  });

  group('SettingsCubit', () {
    late SettingsCubit cubit;
    late MockDownloadService mockDownloadService;
    late MockDownloadsRepository mockDownloadsRepository;
    late MockDownloadNotificationService mockDownloadNotificationService;

    setUp(() {
      // Clean up GetIt manually
      if (getIt.isRegistered<DownloadQueueManager>()) {
        getIt.unregister<DownloadQueueManager>();
      }
      if (getIt.isRegistered<DownloadService>()) {
        getIt.unregister<DownloadService>();
      }
      if (getIt.isRegistered<DownloadsRepository>()) {
        getIt.unregister<DownloadsRepository>();
      }
      if (getIt.isRegistered<DownloadNotificationService>()) {
        getIt.unregister<DownloadNotificationService>();
      }

      mockDownloadService = MockDownloadService();
      mockDownloadsRepository = MockDownloadsRepository();
      mockDownloadNotificationService = MockDownloadNotificationService();

      when(
        () => mockDownloadService.getActiveDownloadIds(),
      ).thenAnswer((_) async => []);
      when(
        () => mockDownloadService.globalProgressStream,
      ).thenAnswer((_) => const Stream.empty());

      getIt.registerSingleton<DownloadService>(mockDownloadService);
      getIt.registerSingleton<DownloadsRepository>(mockDownloadsRepository);
      getIt.registerSingleton<DownloadNotificationService>(
        mockDownloadNotificationService,
      );

      when(
        () => mockDownloadNotificationService.initialize(),
      ).thenAnswer((_) async {});
      when(
        () => mockDownloadNotificationService.showDownloadProgress(
          downloadId: any(named: 'downloadId'),
          title: any(named: 'title'),
          reciterName: any(named: 'reciterName'),
          progress: any(named: 'progress'),
          status: any(named: 'status'),
          pendingMessage: any(named: 'pendingMessage'),
          progressMessage: any(named: 'progressMessage'),
          completeMessage: any(named: 'completeMessage'),
          failedMessage: any(named: 'failedMessage'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockDownloadNotificationService.cancelNotification(any()),
      ).thenAnswer((_) async {});

      DownloadQueueManager.initForTesting(downloadService: mockDownloadService);

      // We must initialize the QueueManager because SettingsCubit might access it
      // or set values on it. Note that initForTesting registers the lazy singleton,
      // but doesn't initialize it until accessed or called.
      // SettingsCubit calls instance.maxConcurrentDownloads getter/setter.

      cubit = SettingsCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default maxConcurrentDownloads of 2', () {
      expect(cubit.state, const SettingsState());
      expect(DownloadQueueManager.instance.maxConcurrentDownloads, 2);
    });

    blocTest<SettingsCubit, SettingsState>(
      'emits new state when setMaxConcurrentDownloads is called',
      build: () => cubit,
      act: (cubit) => cubit.setMaxConcurrentDownloads(4),
      expect: () => [const SettingsState(maxConcurrentDownloads: 4)],
      verify: (_) {
        expect(DownloadQueueManager.instance.maxConcurrentDownloads, 4);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updates DownloadQueueManager when setting changes',
      build: () => cubit,
      act: (cubit) => cubit.setMaxConcurrentDownloads(3),
      verify: (_) {
        expect(DownloadQueueManager.instance.maxConcurrentDownloads, 3);
      },
    );

    group('Serialization', () {
      test('fromJson returns correct state', () {
        expect(
          cubit.fromJson({
            'maxConcurrentDownloads': 5,
            'restorePlaybackState': true,
          }),
          const SettingsState(maxConcurrentDownloads: 5),
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
        });
      });
    });
  });
}
