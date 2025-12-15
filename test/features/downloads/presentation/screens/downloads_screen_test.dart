import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/presentation/bloc/download_button/download_button_bloc.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_status.dart';
import 'package:muzakri/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

import 'downloads_screen_test.mocks.dart';

// Provide dummy value for DownloadsState - Mockito will use this automatically
// The function name must follow the pattern: provideDummy<TypeName>
// This must be a top-level function in the same file as @GenerateMocks
@visibleForTesting
DownloadsState provideDummyDownloadsState() => const DownloadsState();

@GenerateMocks([DownloadsBloc, DownloadsRepository])
void main() {
  late MockDownloadsBloc mockDownloadsBloc;
  late MockDownloadsRepository mockDownloadsRepository;
  late StreamController<DownloadsState> stateController;

  setUpAll(() {
    provideDummy(const DownloadsState());
  });

  setUp(() {
    // Create a fresh mock for each test
    mockDownloadsBloc = MockDownloadsBloc();
    mockDownloadsRepository = MockDownloadsRepository();
    stateController = StreamController<DownloadsState>.broadcast();

    // Register dependencies in GetIt for DownloadButtonBloc
    final GetIt getIt = GetIt.instance;
    getIt.allowReassignment = true; // Allow overwriting for tests

    if (!getIt.isRegistered<DownloadsRepository>()) {
      getIt.registerSingleton<DownloadsRepository>(mockDownloadsRepository);
    }

    // Register DownloadButtonBloc factory
    if (!getIt.isRegistered<DownloadButtonBloc>()) {
      getIt.registerFactoryParam<DownloadButtonBloc, String, String>(
        (url, reciterName) => DownloadButtonBloc(
          url: url,
          reciterName: reciterName,
          downloadsRepository: mockDownloadsRepository,
        ),
      );
    }

    // Set up stream to use our controller
    when(mockDownloadsBloc.stream).thenAnswer((_) => stateController.stream);
    when(mockDownloadsBloc.statusStream).thenAnswer(
      (_) => const Stream<DownloadsStatus>.empty().asBroadcastStream(),
    );

    // Set up default state (tests can override this)
    when(mockDownloadsBloc.state).thenReturn(const DownloadsState());

    // Stub add() method to prevent errors when DownloadsScreen dispatches events
    when(mockDownloadsBloc.add(any)).thenReturn(null);

    // Stub close() method to prevent errors during widget disposal
    when(mockDownloadsBloc.close()).thenAnswer((_) async {
      await stateController.close();
      return;
    });

    // Stub repository methods needed by DownloadButtonBloc
    when(
      mockDownloadsRepository.isSurahDownloaded(any, any),
    ).thenAnswer((_) async => false);
    when(
      mockDownloadsRepository.isSurahDownloading(any, any),
    ).thenAnswer((_) async => false);
  });

  tearDown(() {
    // Close the controller if it's still open
    if (!stateController.isClosed) {
      stateController.close();
    }
    GetIt.instance.reset();
  });

  Widget createTestWidget() {
    return RepositoryProvider<DownloadsRepository>.value(
      value: mockDownloadsRepository,
      child: BlocProvider<DownloadsBloc>.value(
        value: mockDownloadsBloc,
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
              status: DownloadStatus.downloading,
              progress: 0.5,
              fileSize: 1024,
              downloadedSize: 512,
              createdAt: DateTime.now(),
            ),
          ],
        },
      };

      // Set up state and emit it through the stream
      final loadedState = DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: downloads,
      );
      when(mockDownloadsBloc.state).thenReturn(loadedState);

      // Emit state first so BlocBuilder can receive it when it subscribes
      stateController.add(loadedState);

      // Act
      await tester.pumpWidget(createTestWidget());
      // Pump a few frames to allow initState, postFrameCallback, and BlocBuilder to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Surah'), findsOneWidget);
      expect(find.text('Test Reciter'), findsOneWidget);
    });

    testWidgets('should update UI when download progress changes', (
      WidgetTester tester,
    ) async {
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

      var loadedState = DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: {
          'Test Reciter': {
            'Default': [download],
          },
        },
      );

      // Emit state BEFORE building widget
      when(mockDownloadsBloc.state).thenReturn(loadedState);
      stateController.add(loadedState);

      // Stub repo to confirm downloading status so DownloadButtonBloc picks it up
      when(
        mockDownloadsRepository.isSurahDownloading(any, any),
      ).thenAnswer((_) async => true);
      when(
        mockDownloadsRepository.getDownloadProgress(any),
      ).thenAnswer((_) => const Stream.empty());
      when(
        mockDownloadsRepository.getDownloadItem(any),
      ).thenAnswer((_) async => download);

      // Act - Initial render
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Initial state
      expect(find.textContaining('0%'), findsOneWidget);

      // Act - Update progress to 30%
      download = download.copyWith(progress: 0.3, downloadedSize: 300);
      loadedState = DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: {
          'Test Reciter': {
            'Default': [download],
          },
        },
      );
      when(mockDownloadsBloc.state).thenReturn(loadedState);
      stateController.add(loadedState);

      // Wait for rebuild - pump multiple times to ensure BlocBuilder processes the update
      await tester.pumpAndSettle();

      // Assert - Updated state
      expect(find.textContaining('30%'), findsOneWidget);
    });

    testWidgets('should reflect progress updates in real-time', (
      WidgetTester tester,
    ) async {
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
      when(mockDownloadsBloc.state).thenReturn(loadedState);
      stateController.add(loadedState);

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
        when(mockDownloadsBloc.state).thenReturn(loadedState);
        stateController.add(loadedState);

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
    });

    // Modified test case with sequential assertions
    testWidgets(
      'should display correct status text for downloading with percentage',
      (WidgetTester tester) async {
        // Arrange
        final download = DownloadItem(
          id: 'test_id',
          title: 'Test Surah',
          url: 'https://example.com/test.mp3',
          filePath: '/path/to/test.mp3',
          reciterName: 'Test Reciter',
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
        when(mockDownloadsBloc.state).thenReturn(loadedState);
        stateController.add(loadedState);

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

        // Check CustomScrollView
        expect(
          find.byType(CustomScrollView),
          findsOneWidget,
          reason: 'CustomScrollView not found - BlocBuilder failing?',
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
      },
    );
  });
}
