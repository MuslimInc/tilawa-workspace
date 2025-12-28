import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/usecases.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_status.dart';
import 'package:tilawa/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../helpers/mock_helper.mocks.dart';

// Robust Mock Implementation avoiding noSuchMethod on getters
class MockDownloadsBloc extends MockBloc<DownloadsEvent, DownloadsState>
    implements DownloadsBloc {
  final statusController = StreamController<DownloadsStatus>.broadcast();

  @override
  Stream<DownloadsStatus> get statusStream => statusController.stream;
}

@visibleForTesting
DownloadsState provideDummyDownloadsState() => const DownloadsState();

void main() {
  MockDownloadsBloc? mockDownloadsBloc;
  late MockDownloadsRepository mockDownloadsRepository;
  late MockCheckSurahDownloadedUseCase mockCheckSurahDownloadedUseCase;
  late MockDownloadSurahUseCase mockDownloadSurahUseCase;

  setUpAll(() {
    provideDummy(const DownloadsState());
    provideDummy<Future<void>>(Future.value());
    provideDummy<Stream<DownloadsState>>(const Stream.empty());
    provideDummy<Stream<DownloadsStatus>>(const Stream.empty());
    // Provide dummy values for UseCase results
    provideDummy<Either<Failure, bool>>(const Right(false));
    provideDummy<Either<Failure, void>>(const Right(null));
  });

  setUp(() {
    // Create a fresh mock for each test
    mockDownloadsBloc = MockDownloadsBloc();
    mockDownloadsRepository = MockDownloadsRepository();
    mockCheckSurahDownloadedUseCase = MockCheckSurahDownloadedUseCase();
    mockDownloadSurahUseCase = MockDownloadSurahUseCase();

    // Register dependencies in GetIt for DownloadButtonBloc
    final GetIt getIt = GetIt.instance;
    getIt.allowReassignment = true;

    if (!getIt.isRegistered<DownloadsRepository>()) {
      getIt.registerSingleton<DownloadsRepository>(mockDownloadsRepository);
    }
    if (!getIt.isRegistered<CheckSurahDownloadedUseCase>()) {
      getIt.registerSingleton<CheckSurahDownloadedUseCase>(
        mockCheckSurahDownloadedUseCase,
      );
    }
    if (!getIt.isRegistered<DownloadSurahUseCase>()) {
      getIt.registerSingleton<DownloadSurahUseCase>(mockDownloadSurahUseCase);
    }

    // Mock UseCase responses
    when(
      mockCheckSurahDownloadedUseCase.call(
        surahId: anyNamed('surahId'),
        reciterName: anyNamed('reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    when(
      mockDownloadSurahUseCase.call(
        surahId: anyNamed('surahId'),
        surahTitle: anyNamed('surahTitle'),
        reciterName: anyNamed('reciterName'),
        reciterId: anyNamed('reciterId'),
      ),
    ).thenAnswer((_) async => const Right(null));

    // Stub repository
    when(
      mockDownloadsRepository.isSurahDownloaded(any, any),
    ).thenAnswer((_) async => false);
    when(
      mockDownloadsRepository.isSurahDownloading(any, any),
    ).thenAnswer((_) async => false);
    when(
      mockDownloadsRepository.getDownloadProgress(any),
    ).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() {
    mockDownloadsBloc?.statusController.close();
    mockDownloadsBloc?.close();
    GetIt.instance.reset();
  });

  Widget createTestWidget() {
    return RepositoryProvider<DownloadsRepository>.value(
      value: mockDownloadsRepository,
      child: BlocProvider<DownloadsBloc>.value(
        value: mockDownloadsBloc!,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              ScreenUtilPlus.init(
                context,
                designSize: const Size(375, 812),
                minTextAdapt: true,
                splitScreenMode: true,
              );
              return const SizedBox(
                width: 375,
                height: 812,
                child: DownloadsScreen(),
              );
            },
          ),
        ),
      ),
    );
  }

  group('DownloadsScreen', () {
    testWidgets('should display downloads when state is loaded', (
      WidgetTester tester,
    ) async {
      // Set surface size to match design
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Arrange
      final downloads = {
        'Test Reciter': {
          'Default': [
            DownloadItem(
              id: 'test_id',
              title: 'Test Surah',
              url: 'https://example.com/test.mp3',
              filePath: '/path/to/test.mp3',
              reciterName: 'Test Reciter',
              reciterId: 0,
              status: DownloadStatus.downloading,
              progress: 0.5,
              fileSize: 1024,
              downloadedSize: 512,
              createdAt: DateTime.now(),
            ),
          ],
        },
      };

      // Set up state
      final loadedState = DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: downloads,
      );

      // Use whenListen for MockBloc state emission
      whenListen(
        mockDownloadsBloc!,
        Stream.value(loadedState),
        initialState: loadedState,
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Surah'), findsOneWidget);
      expect(find.text('Test Reciter'), findsOneWidget);
    });

    testWidgets('should update UI when download progress changes', (
      WidgetTester tester,
    ) async {
      // Arrange
      final download = DownloadItem(
        id: 'test_id',
        title: 'Test Surah',
        url: 'https://example.com/test.mp3',
        filePath: '/path/to/test.mp3',
        reciterName: 'Test Reciter',
        status: DownloadStatus.downloading,
        progress: 0.0,
        fileSize: 1000,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      );

      final initialState = DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: {
          'Test Reciter': {
            'Default': [download],
          },
        },
      );

      // Use a controller to update MockBloc state
      final stateController = StreamController<DownloadsState>.broadcast();
      whenListen(
        mockDownloadsBloc!,
        stateController.stream,
        initialState: initialState,
      );

      // Stub repo
      when(
        mockDownloadsRepository.isSurahDownloading(any, any),
      ).thenAnswer((_) async => true);

      // We also need to stub getDownloadItem because DownloadButton might refresh
      when(
        mockDownloadsRepository.getDownloadItem(any),
      ).thenAnswer((_) async => download);

      // Act - Initial render
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Initial state
      expect(find.textContaining('0%'), findsOneWidget);

      // Update progress
      final DownloadItem updatedDownload = download.copyWith(
        progress: 0.3,
        downloadedSize: 300,
      );
      final updatedState = DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: {
          'Test Reciter': {
            'Default': [updatedDownload],
          },
        },
      );

      // Emit new state
      stateController.add(updatedState);

      // Pump frames to allow BlocListener/Builder to react
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('30%'), findsOneWidget);

      await stateController.close();
    });

    testWidgets('should reflect progress updates in real-time', (
      WidgetTester tester,
    ) async {
      final stateController = StreamController<DownloadsState>.broadcast();

      // Arrange
      var download = DownloadItem(
        id: 'test_id',
        title: 'Test Surah',
        url: 'https://example.com/test.mp3',
        filePath: '/path/to/test.mp3',
        reciterName: 'Test Reciter',
        status: DownloadStatus.downloading,
        progress: 0.0,
        fileSize: 1000,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      );

      // Set up initial state
      var loadedState = DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: {
          'Test Reciter': {
            'Default': [download],
          },
        },
      );

      whenListen(
        mockDownloadsBloc!,
        stateController.stream,
        initialState: loadedState,
      );

      // Stubs for DownloadButton
      when(
        mockDownloadsRepository.isSurahDownloading(any, any),
      ).thenAnswer((_) async => true);
      when(
        mockDownloadsRepository.getDownloadItem(any),
      ).thenAnswer((_) async => download);

      // Create widget once
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act & Assert - Simulate progress updates
      for (var second = 0; second <= 5; second++) {
        final double progress = second * 0.2;
        download = download.copyWith(
          progress: progress,
          downloadedSize: (1000 * progress).round(),
        );

        loadedState = DownloadsState(
          status: DownloadsStateStatus.loaded,
          downloads: {
            'Test Reciter': {
              'Default': [download],
            },
          },
        );

        stateController.add(loadedState);
        // Update DownloadItem stub for the next loop/check
        when(
          mockDownloadsRepository.getDownloadItem(any),
        ).thenAnswer((_) async => download);

        // Pump frames to allow BlocBuilder to receive and process the state
        await tester.pumpAndSettle();

        // Verify percentage is displayed correctly
        final int expectedPercentage = (progress * 100).round();
        expect(
          find.textContaining('$expectedPercentage%'),
          findsOneWidget,
          reason: 'Should display $expectedPercentage% at second $second',
        );
      }
      await stateController.close();
    });

    testWidgets(
      'should display correct status text for downloading with percentage',
      (WidgetTester tester) async {
        final stateController = StreamController<DownloadsState>.broadcast();

        // Arrange
        final download = DownloadItem(
          id: 'test_id',
          title: 'Test Surah',
          url: 'https://example.com/test.mp3',
          filePath: '/path/to/test.mp3',
          reciterName: 'Test Reciter',
          reciterId: 0,
          status: DownloadStatus.downloading,
          progress: 0.75,
          fileSize: 1000,
          downloadedSize: 750,
          createdAt: DateTime.now(),
        );

        final loadedState = DownloadsState(
          status: DownloadsStateStatus.loaded,
          downloads: {
            'Test Reciter': {
              'Default': [download],
            },
          },
        );

        whenListen(
          mockDownloadsBloc!,
          stateController.stream,
          initialState: loadedState,
        );

        // Stub repo for DownloadButtonBloc
        when(
          mockDownloadsRepository.isSurahDownloading(any, any),
        ).thenAnswer((_) async => true);
        when(
          mockDownloadsRepository.getDownloadProgress(any),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockDownloadsRepository.getDownloadItem(any),
        ).thenAnswer((_) async => download);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        // Check DownloadsScreen
        expect(
          find.byType(DownloadsScreen),
          findsOneWidget,
          reason: 'DownloadsScreen not found',
        );

        // Check ListView
        expect(
          find.byType(ListView),
          findsOneWidget,
          reason: 'ListView not found - BlocBuilder failing?',
        );

        // 1. Check Reciter Header
        expect(
          find.text('Test Reciter', skipOffstage: false),
          findsOneWidget,
          reason: 'Reciter Header Missing - Screen might be empty',
        );

        // 2. Check Surah Title
        expect(
          find.text('Test Surah', skipOffstage: false),
          findsOneWidget,
          reason: 'Surah Title Missing - List item not rendered',
        );

        // 3. Check Progress Indicator
        expect(
          find.byType(LinearProgressIndicator, skipOffstage: false),
          findsOneWidget,
          reason:
              'LinearProgressIndicator Missing - DownloadStatus check failing?',
        );

        // 4. Check Status Text
        expect(
          find.textContaining('75%', skipOffstage: false),
          findsOneWidget,
          reason: 'Percentage text missing',
        );
        await stateController.close();
      },
    );
  });
}
