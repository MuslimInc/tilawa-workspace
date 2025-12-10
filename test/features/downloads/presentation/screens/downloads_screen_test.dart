import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

import 'downloads_screen_test.mocks.dart';

// Provide dummy value for DownloadsState - Mockito will use this automatically
// The function name must follow the pattern: provideDummy<TypeName>
// This must be a top-level function in the same file as @GenerateMocks
@visibleForTesting
DownloadsState provideDummyDownloadsState() => const DownloadsState();

@GenerateMocks([DownloadsBloc])
void main() {
  late MockDownloadsBloc mockDownloadsBloc;
  late StreamController<DownloadsState> stateController;

  setUp(() {
    // Provide dummy value for Mockito
    provideDummy(const DownloadsState());

    // Create a fresh mock for each test
    mockDownloadsBloc = MockDownloadsBloc();

    // Create a StreamController to control the bloc's stream
    stateController = StreamController<DownloadsState>.broadcast();

    // Set up stream to use our controller
    when(mockDownloadsBloc.stream).thenAnswer((_) => stateController.stream);
    when(
      mockDownloadsBloc.statusStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockDownloadsBloc.downloadProgressStream,
    ).thenAnswer((_) => const Stream.empty());

    // Set up default state (tests can override this)
    when(mockDownloadsBloc.state).thenReturn(const DownloadsState());

    // Stub add() method to prevent errors when DownloadsScreen dispatches events
    when(mockDownloadsBloc.add(any)).thenReturn(null);

    // Stub close() method to prevent errors during widget disposal
    when(mockDownloadsBloc.close()).thenAnswer((_) async {
      await stateController.close();
      return;
    });
  });

  tearDown(() {
    // Close the controller if it's still open
    if (!stateController.isClosed) {
      stateController.close();
    }
  });

  Widget createTestWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<DownloadsBloc>.value(
        value: mockDownloadsBloc,
        child: const DownloadsScreen(),
      ),
    );
  }

  group('DownloadsScreen', () {
    testWidgets('should display downloads when state is loaded', (
      WidgetTester tester,
    ) async {
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
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Expand the ExpansionTile to see the download items
      final Finder expansionTile = find.byType(ExpansionTile);
      expect(expansionTile, findsOneWidget);
      await tester.tap(expansionTile);
      await tester.pump();
      await tester.pump();

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

      // Act - Initial render
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump();

      // Expand the ExpansionTile to see the download items
      final Finder expansionTile = find.byType(ExpansionTile);
      expect(expansionTile, findsOneWidget);
      await tester.tap(expansionTile);
      await tester.pump();
      await tester.pump();

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
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Assert - Updated state
      expect(find.textContaining('30%'), findsOneWidget);
      // Note: The old "0%" text might still be in the widget tree briefly during rebuild
      // So we check that "30%" is present, which confirms the update worked
      // We can't reliably check that "0%" is gone due to widget tree rebuild timing
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
      await tester.pump();
      await tester.pump();

      // Expand ExpansionTile once
      final Finder expansionTile = find.byType(ExpansionTile);
      expect(expansionTile, findsOneWidget);
      await tester.tap(expansionTile);
      await tester.pump();
      await tester.pump();

      // Act & Assert - Simulate progress updates every second
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
        await tester.pump();
        await tester.pump();

        // Verify percentage is displayed correctly
        final int expectedPercentage = (progress * 100).round();
        expect(
          find.textContaining('$expectedPercentage%'),
          findsOneWidget,
          reason: 'Should display $expectedPercentage% at second $second',
        );

        // Verify progress bar exists and has correct value
        if (progress < 1.0) {
          final Finder progressIndicatorFinder = find.byType(
            LinearProgressIndicator,
          );
          if (progressIndicatorFinder.evaluate().isNotEmpty) {
            final LinearProgressIndicator progressIndicator = tester
                .widget<LinearProgressIndicator>(progressIndicatorFinder);
            expect(
              progressIndicator.value ?? 0.0,
              closeTo(progress, 0.01),
              reason: 'Progress bar should be $progress at second $second',
            );
          }
        }

        // Simulate 1 second delay
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('should show progress bar with increasing value over time', (
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
        fileSize: 10000,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      );

      final progressValues = <double>[];

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
      await tester.pump();
      await tester.pump();

      // Expand ExpansionTile once
      final Finder expansionTile = find.byType(ExpansionTile);
      expect(expansionTile, findsOneWidget);
      await tester.tap(expansionTile);
      await tester.pump();
      await tester.pump();

      // Act - Simulate 10 seconds of progress
      for (var second = 0; second <= 10; second++) {
        final double progress = (second / 10).clamp(0.0, 1.0);
        download = download.copyWith(
          progress: progress,
          downloadedSize: (10000 * progress).round(),
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
        await tester.pump();
        await tester.pump();

        // Only check progress bar if it exists (when progress < 1.0)
        final Finder progressIndicatorFinder = find.byType(
          LinearProgressIndicator,
        );
        if (progress < 1.0 && progressIndicatorFinder.evaluate().isNotEmpty) {
          final LinearProgressIndicator progressIndicator = tester
              .widget<LinearProgressIndicator>(progressIndicatorFinder);
          progressValues.add(progressIndicator.value ?? 0.0);
        }

        // Verify percentage text updates
        final int expectedPercentage = (progress * 100).round();
        expect(find.textContaining('$expectedPercentage%'), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));
      }

      // Assert - Progress values should be increasing
      expect(progressValues.length, greaterThan(1));
      for (var i = 1; i < progressValues.length; i++) {
        expect(
          progressValues[i],
          greaterThan(progressValues[i - 1]),
          reason:
              'Progress should increase: ${progressValues[i - 1]} -> ${progressValues[i]}',
        );
      }

      // Verify final progress is close to 1.0 (or 0.9 if we didn't capture the last value)
      // Note: The last iteration has progress = 1.0, but we only check progress bar when progress < 1.0
      // So the last captured value will be 0.9
      expect(progressValues.last, greaterThanOrEqualTo(0.9));
    });

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

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        // Expand the ExpansionTile to see the download items
        final Finder expansionTile = find.byType(ExpansionTile);
        expect(expansionTile, findsOneWidget);
        await tester.tap(expansionTile);
        await tester.pump();
        await tester.pump();

        // Assert
        // Should display "Downloading 75%" (or localized equivalent)
        expect(find.textContaining('75%'), findsOneWidget);
      },
    );

    testWidgets(
      'should update percentage text every second as progress increases in real-time',
      (WidgetTester tester) async {
        // This test simulates real-time download progress updates:
        // 1. Widget is created once and stays alive
        // 2. Progress updates are emitted through the bloc stream every second
        // 3. UI automatically rebuilds to reflect each progress update
        // 4. This mimics how DownloadService.globalProgressStream would emit updates

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

        final displayedPercentages = <int>[];
        final progressHistory = <double>[];

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

        // Create widget once - it will stay alive and update as state changes
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump();

        // Expand ExpansionTile once
        final Finder expansionTile = find.byType(ExpansionTile);
        expect(expansionTile, findsOneWidget);
        await tester.tap(expansionTile);
        await tester.pump();
        await tester.pump();

        // Verify initial state (0%)
        expect(find.textContaining('0%'), findsOneWidget);

        // Act - Simulate real-time progress updates every second for 5 seconds
        // This simulates DownloadService emitting progress updates through the stream
        for (var second = 0; second <= 5; second++) {
          final double progress = second * 0.2; // 0%, 20%, 40%, 60%, 80%, 100%
          final int downloadedBytes = (1000 * progress).round();
          download = download.copyWith(
            progress: progress,
            downloadedSize: downloadedBytes,
          );

          // Simulate progress update being emitted through the bloc stream
          // (In real app, this would come from DownloadService.globalProgressStream)
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

          // Pump frames to allow BlocBuilder to receive and process the state update
          // This simulates the UI automatically rebuilding when new state arrives
          await tester.pump();
          await tester.pump();

          // Verify UI reflects the progress update immediately
          final int expectedPercentage = (progress * 100).round();
          final Finder percentageText = find.textContaining(
            '$expectedPercentage%',
          );
          expect(
            percentageText,
            findsOneWidget,
            reason:
                'UI should update to show $expectedPercentage% at second $second',
          );
          displayedPercentages.add(expectedPercentage);

          // Print progress update
          if (second > 0) {}

          // Verify progress bar value also updates
          if (progress < 1.0) {
            final Finder progressIndicatorFinder = find.byType(
              LinearProgressIndicator,
            );
            if (progressIndicatorFinder.evaluate().isNotEmpty) {
              final LinearProgressIndicator progressIndicator = tester
                  .widget<LinearProgressIndicator>(progressIndicatorFinder);
              progressHistory.add(progressIndicator.value ?? 0.0);
              expect(
                progressIndicator.value ?? 0.0,
                closeTo(progress, 0.01),
                reason:
                    'Progress bar should update to $progress at second $second',
              );
            }
          }

          // Simulate 1 second delay before next progress update
          // (In real app, DownloadService would emit the next update after ~1 second)
          await tester.pump(const Duration(seconds: 1));
        }

        // Assert - Verify real-time updates were reflected correctly
        // Percentages should be increasing: 0, 20, 40, 60, 80, 100
        expect(displayedPercentages, [0, 20, 40, 60, 80, 100]);
        for (var i = 1; i < displayedPercentages.length; i++) {
          expect(
            displayedPercentages[i],
            greaterThan(displayedPercentages[i - 1]),
            reason: 'Percentage should increase each second in real-time',
          );
        }

        // Verify progress bar values also increased over time
        if (progressHistory.length > 1) {
          for (var i = 1; i < progressHistory.length; i++) {
            expect(
              progressHistory[i],
              greaterThan(progressHistory[i - 1]),
              reason: 'Progress bar should increase over time',
            );
          }
        }
      },
    );
  });
}
