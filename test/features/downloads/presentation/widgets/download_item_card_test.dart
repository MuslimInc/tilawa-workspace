import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/widgets/download_item_card.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

import 'download_item_card_test.mocks.dart';

// Provide dummy value for DownloadsState - Mockito will use this automatically
@visibleForTesting
DownloadsState provideDummyDownloadsState() => const DownloadsState.initial();

@GenerateMocks([DownloadsBloc, AudioPlayerBloc])
void main() {
  late MockDownloadsBloc mockDownloadsBloc;
  late MockAudioPlayerBloc mockAudioPlayerBloc;

  setUp(() {
    // Provide dummy value for Mockito before creating mocks
    provideDummy(DownloadsState.initial());

    mockDownloadsBloc = MockDownloadsBloc();
    mockAudioPlayerBloc = MockAudioPlayerBloc();

    // Set up stream first (required for BlocProvider)
    when(mockDownloadsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(mockAudioPlayerBloc.stream).thenAnswer((_) => const Stream.empty());

    // Provide default dummy values for state
    when(mockDownloadsBloc.state).thenReturn(const DownloadsState.initial());
    when(
      mockAudioPlayerBloc.state,
    ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.initial));

    // Stub add() method to prevent errors
    when(mockDownloadsBloc.add(any)).thenReturn(null);
    when(mockAudioPlayerBloc.add(any)).thenReturn(null);
  });

  Widget createTestWidget(DownloadItem download) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<DownloadsBloc>.value(value: mockDownloadsBloc),
            BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
          ],
          child: DownloadItemCard(download: download, onDelete: () {}),
        ),
      ),
    );
  }

  group('DownloadItemCard', () {
    testWidgets('should display download title', (WidgetTester tester) async {
      // Arrange
      final download = DownloadItem(
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
      );

      // Act
      await tester.pumpWidget(createTestWidget(download));

      // Assert
      expect(find.text('Test Surah'), findsOneWidget);
    });

    testWidgets('should display progress bar when status is downloading', (
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
        progress: 0.5,
        fileSize: 1024,
        downloadedSize: 512,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(download));

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.5);
    });

    testWidgets(
      'should display correct percentage in status text when downloading',
      (WidgetTester tester) async {
        // Arrange
        final download = DownloadItem(
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
        );

        // Act
        await tester.pumpWidget(createTestWidget(download));
        await tester.pumpAndSettle();

        // Assert
        // The status text should contain "50%" (or the localized equivalent)
        final statusText = find.textContaining('50%');
        expect(statusText, findsOneWidget);
      },
    );

    testWidgets('should update progress bar value when progress changes', (
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
        progress: 0.3,
        fileSize: 1024,
        downloadedSize: 307,
        createdAt: DateTime.now(),
      );

      // Act - Initial render with 30% progress
      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      // Assert - Initial progress
      var progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.3);

      // Act - Update to 60% progress
      download = download.copyWith(progress: 0.6, downloadedSize: 614);
      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      // Assert - Updated progress
      progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.6);
    });

    testWidgets('should update percentage text when progress increases', (
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
        progress: 0.25,
        fileSize: 1024,
        downloadedSize: 256,
        createdAt: DateTime.now(),
      );

      // Act - Initial render with 25% progress
      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      // Assert - Initial percentage
      expect(find.textContaining('25%'), findsOneWidget);

      // Act - Update to 50% progress
      download = download.copyWith(progress: 0.5, downloadedSize: 512);
      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      // Assert - Updated percentage
      expect(find.textContaining('50%'), findsOneWidget);
      expect(find.textContaining('25%'), findsNothing);
    });

    testWidgets('should display file size information when fileSize > 0', (
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
        progress: 0.5,
        fileSize: 1024,
        downloadedSize: 512,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      // Assert
      // Should display file size (e.g., "512 B / 1.0 KB" or similar)
      // 512 bytes = "512 B", 1024 bytes = "1.0 KB"
      expect(find.textContaining('512'), findsWidgets);
      expect(find.textContaining('1.0'), findsWidgets);
      expect(find.textContaining('KB'), findsWidgets);
    });

    testWidgets(
      'should not display progress bar when status is not downloading',
      (WidgetTester tester) async {
        // Arrange
        final download = DownloadItem(
          id: 'test_id',
          title: 'Test Surah',
          url: 'https://example.com/test.mp3',
          filePath: '/path/to/test.mp3',
          reciterName: 'Test Reciter',
          status: DownloadStatus.completed,
          progress: 1.0,
          fileSize: 1024,
          downloadedSize: 1024,
          createdAt: DateTime.now(),
        );

        // Act
        await tester.pumpWidget(createTestWidget(download));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(LinearProgressIndicator), findsNothing);
      },
    );

    testWidgets('should display correct status icon for downloading status', (
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
        progress: 0.5,
        fileSize: 1024,
        downloadedSize: 512,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });

  group('DownloadItemCard - Progress Updates Over Time', () {
    testWidgets('should reflect real-time progress updates simulating 1 second intervals', (
      WidgetTester tester,
    ) async {
      // This test simulates real-time download progress updates:
      // 1. Progress updates are simulated every second (0%, 20%, 40%, 60%, 80%, 100%)
      // 2. UI is updated with each progress value
      // 3. Both progress bar and percentage text are verified to update correctly
      // 4. This mimics how the UI would update in real-time as DownloadService emits progress

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

      final progressHistory = <double>[];
      final percentageHistory = <int>[];

      print('📥 DownloadItemCard - Download Simulation Started');

      // Act & Assert - Simulate real-time progress updates every second
      for (int second = 0; second <= 5; second++) {
        final progress = second * 0.2; // 0%, 20%, 40%, 60%, 80%, 100%
        final downloadedBytes = (1000 * progress).round();
        download = download.copyWith(
          progress: progress,
          downloadedSize: downloadedBytes,
        );

        // Update widget with new progress (simulating state update from bloc)
        await tester.pumpWidget(createTestWidget(download));
        await tester.pumpAndSettle();

        // Verify progress bar value updates in real-time
        double? currentProgressValue;
        if (progress < 1.0) {
          final progressIndicator = tester.widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          );
          currentProgressValue = progressIndicator.value ?? 0.0;
          progressHistory.add(currentProgressValue);
          expect(
            currentProgressValue,
            closeTo(progress, 0.01),
            reason: 'Progress bar should update to $progress at second $second',
          );
        }

        // Verify percentage text updates in real-time
        final expectedPercentage = (progress * 100).round();
        expect(
          find.textContaining('$expectedPercentage%'),
          findsOneWidget,
          reason:
              'Percentage text should update to $expectedPercentage% at second $second',
        );
        percentageHistory.add(expectedPercentage);

        // Print progress update
        final progressBarValue = currentProgressValue != null
            ? ' (Progress Bar: ${currentProgressValue.toStringAsFixed(2)})'
            : '';
        print(
          '⏱️  Second $second: $expectedPercentage% ($downloadedBytes/1000 bytes)$progressBarValue',
        );

        // Simulate 1 second delay before next progress update
        // (In real app, DownloadService would emit the next update after ~1 second)
        await tester.pump(const Duration(seconds: 1));
      }

      print('✅ DownloadItemCard - Download Simulation Completed');
      print('📊 Progress Bar History: $progressHistory');
      print('📊 Percentage History: $percentageHistory');

      // Assert - Verify progress increased over time
      expect(progressHistory.length, greaterThan(1));
      for (int i = 1; i < progressHistory.length; i++) {
        expect(
          progressHistory[i],
          greaterThan(progressHistory[i - 1]),
          reason:
              'Progress should increase each second: ${progressHistory[i - 1]} -> ${progressHistory[i]}',
        );
      }

      // Verify percentages increased: 0, 20, 40, 60, 80, 100
      expect(percentageHistory, [0, 20, 40, 60, 80, 100]);
    });

    testWidgets('should update from 0% to 100% over multiple seconds', (
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

      final progressHistory = <double>[];

      print(
        '📥 DownloadItemCard - Extended Download Simulation Started (10 seconds)',
      );

      // Act - Simulate 10 seconds of progress
      for (int second = 0; second <= 10; second++) {
        final progress = (second / 10).clamp(0.0, 1.0);
        final downloadedBytes = (10000 * progress).round();
        download = download.copyWith(
          progress: progress,
          downloadedSize: downloadedBytes,
        );

        await tester.pumpWidget(createTestWidget(download));
        await tester.pumpAndSettle();

        // Only check progress bar if it exists (when progress < 1.0)
        final progressIndicatorFinder = find.byType(LinearProgressIndicator);
        if (progress < 1.0 && progressIndicatorFinder.evaluate().isNotEmpty) {
          final progressIndicator = tester.widget<LinearProgressIndicator>(
            progressIndicatorFinder,
          );
          progressHistory.add(progressIndicator.value ?? 0.0);
        }

        // Verify percentage increases
        final expectedPercentage = (progress * 100).round();
        expect(find.textContaining('$expectedPercentage%'), findsOneWidget);

        // Print progress update
        final progressBarInfo = progress < 1.0 && progressHistory.isNotEmpty
            ? ' (Progress Bar: ${progressHistory.last.toStringAsFixed(2)})'
            : '';
        print(
          '⏱️  Second $second: $expectedPercentage% ($downloadedBytes/10000 bytes)$progressBarInfo',
        );

        await tester.pump(const Duration(seconds: 1));
      }

      print('✅ DownloadItemCard - Extended Download Simulation Completed');
      print('📊 Progress Values: $progressHistory');

      // Assert - Progress should be increasing
      for (int i = 1; i < progressHistory.length; i++) {
        expect(
          progressHistory[i],
          greaterThan(progressHistory[i - 1]),
          reason: 'Progress should increase over time',
        );
      }
    });
  });
}
