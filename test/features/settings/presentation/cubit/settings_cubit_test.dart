import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/downloads/data/services/download_queue_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/settings/presentation/cubit/settings_cubit.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';

class MockDownloadService extends Mock implements DownloadService {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

final GetIt getIt = GetIt.instance;

void main() {
  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  group('SettingsCubit', () {
    late SettingsCubit cubit;
    late MockDownloadService mockDownloadService;
    late MockDownloadsRepository mockDownloadsRepository;

    setUp(() {
      getIt.reset();
      mockDownloadService = MockDownloadService();
      mockDownloadsRepository = MockDownloadsRepository();

      when(
        () => mockDownloadService.getActiveDownloadIds(),
      ).thenAnswer((_) async => []);

      getIt.registerSingleton<DownloadService>(mockDownloadService);
      getIt.registerSingleton<DownloadsRepository>(mockDownloadsRepository);

      DownloadQueueManager.initForTesting(downloadService: mockDownloadService);
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
          cubit.fromJson({'maxConcurrentDownloads': 5}),
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
        });
      });
    });
  });
}
