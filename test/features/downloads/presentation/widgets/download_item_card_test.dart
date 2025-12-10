import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/downloads/data/services/download_queue_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/widgets/download_item_card.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

import 'download_item_card_test.mocks.dart';

// Provide dummy value for DownloadsState - Mockito will use this automatically
@visibleForTesting
DownloadsState provideDummyDownloadsState() => const DownloadsState();

@GenerateMocks([
  DownloadsBloc,
  AudioPlayerBloc,
  DownloadQueueManager,
  DownloadService,
])
void main() {
  late MockDownloadsBloc mockDownloadsBloc;
  late MockAudioPlayerBloc mockAudioPlayerBloc;
  late MockDownloadQueueManager mockDownloadQueueManager;
  late MockDownloadService mockDownloadService;

  setUp(() {
    // Provide dummy value for Mockito before creating mocks
    provideDummy(const DownloadsState());

    mockDownloadsBloc = MockDownloadsBloc();
    mockAudioPlayerBloc = MockAudioPlayerBloc();
    mockDownloadQueueManager = MockDownloadQueueManager();
    mockDownloadService = MockDownloadService();

    // Setup DownloadQueueManager.instance for older tests that might rely on it directly
    DownloadQueueManager.instance = mockDownloadQueueManager;

    // Register mock DownloadService in GetIt for DownloadQueueManager internal use
    final GetIt getIt = GetIt.instance;
    if (!getIt.isRegistered<DownloadService>()) {
      getIt.registerSingleton<DownloadService>(mockDownloadService);
    } else {
      getIt.unregister<DownloadService>();
      getIt.registerSingleton<DownloadService>(mockDownloadService);
    }

    // Set up stream first (required for BlocProvider)
    when(mockDownloadsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      mockDownloadsBloc.statusStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockDownloadsBloc.downloadProgressStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockDownloadsBloc.getDownloadProgressStream(any),
    ).thenAnswer((_) => const Stream.empty());

    // Provide default dummy values for state
    when(mockDownloadsBloc.state).thenReturn(const DownloadsState());
    when(
      mockAudioPlayerBloc.state,
    ).thenReturn(const AudioPlayerState(status: AudioPlayerStatus.initial));
    when(mockAudioPlayerBloc.stream).thenAnswer((_) => const Stream.empty());

    // Stub add() method to prevent errors
    when(mockDownloadsBloc.add(any)).thenReturn(null);
    when(mockAudioPlayerBloc.add(any)).thenReturn(null);

    // Stub queue manager
    when(mockDownloadQueueManager.getQueuePosition(any)).thenReturn(0);

    // Set screen size to larger value to avoid overflows
    TestWidgetsFlutterBinding.ensureInitialized();
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2400); // larger size
    view.devicePixelRatio = 3.0; // standard density
  });

  tearDown(() {
    DownloadQueueManager.reset();
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<DownloadService>()) {
      getIt.unregister<DownloadService>();
    }
  });

  Widget createTestWidget(DownloadItem download, {VoidCallback? onDelete}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<DownloadsBloc>.value(value: mockDownloadsBloc),
            BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
          ],
          child: DownloadItemCard(
            download: download,
            onDelete: onDelete ?? () {},
          ),
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
      final LinearProgressIndicator progressIndicator = tester
          .widget<LinearProgressIndicator>(
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
        final Finder statusText = find.textContaining('50%');
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
      LinearProgressIndicator progressIndicator = tester
          .widget<LinearProgressIndicator>(
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
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('should display correct status icon/color for completed status', (
      WidgetTester tester,
    ) async {
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

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      // Verify color is green (checking the Icon color or Container decoration is hard,
      // but finding the icon verifies proper switch case selection)
      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
      expect(icon.color, Colors.green);
    });

    testWidgets('should display correct status icon/color for failed status', (
      WidgetTester tester,
    ) async {
      final download = DownloadItem(
        id: 'test_id',
        title: 'Test Surah',
        url: 'https://example.com/test.mp3',
        filePath: '/path/to/test.mp3',
        reciterName: 'Test Reciter',
        status: DownloadStatus.failed,
        progress: 0.0,
        fileSize: 0,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      // Check status icon
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(icon.color, Colors.red);

      // Check status text
      expect(find.text('Error'), findsOneWidget);

      // Check retry button exists
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('should display correct status icon/color for paused status', (
      WidgetTester tester,
    ) async {
      final download = DownloadItem(
        id: 'test_id',
        title: 'Test Surah',
        url: 'https://example.com/test.mp3',
        filePath: '/path/to/test.mp3',
        reciterName: 'Test Reciter',
        status: DownloadStatus.paused,
        progress: 0.5,
        fileSize: 1024,
        downloadedSize: 512,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_circle_outline_rounded), findsOneWidget);
      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.pause_circle_outline_rounded),
      );
      expect(icon.color, Colors.orange);
      expect(find.text('Pause'), findsOneWidget);
    });

    testWidgets(
      'should display correct status icon/color for cancelled status',
      (WidgetTester tester) async {
        final download = DownloadItem(
          id: 'test_id',
          title: 'Test Surah',
          url: 'https://example.com/test.mp3',
          filePath: '/path/to/test.mp3',
          reciterName: 'Test Reciter',
          status: DownloadStatus.cancelled,
          progress: 0.0,
          fileSize: 0,
          downloadedSize: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(download));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.cancel_outlined),
        );
        expect(icon.color, Colors.grey);
        expect(find.text('Cancelled'), findsOneWidget);
      },
    );

    testWidgets('should display correct status icon/color for pending status', (
      WidgetTester tester,
    ) async {
      final download = DownloadItem(
        id: 'test_id',
        title: 'Test Surah',
        url: 'https://example.com/test.mp3',
        filePath: '/path/to/test.mp3',
        reciterName: 'Test Reciter',
        status: DownloadStatus.pending,
        progress: 0.0,
        fileSize: 0,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.schedule_rounded),
      );
      expect(icon.color, Colors.grey);
      expect(find.text('Pending'), findsOneWidget);
    });
  });

  group('DownloadItemCard - Interactions', () {
    testWidgets('should show Play button when completed and not playing', (
      WidgetTester tester,
    ) async {
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

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tap play
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      verify(
        mockDownloadsBloc.add(
          const DownloadsEvent.playDownloadedSurah(downloadId: 'test_id'),
        ),
      ).called(1);
    });

    testWidgets('should show Pause button when playing this item', (
      WidgetTester tester,
    ) async {
      final download = DownloadItem(
        id: 'test_id',
        title: 'Test Surah',
        url: 'https://example.com/test.mp3',
        filePath: '/path/to/test.mp3', // matches media item id
        reciterName: 'Test Reciter',
        status: DownloadStatus.completed,
        progress: 1.0,
        fileSize: 1024,
        downloadedSize: 1024,
        createdAt: DateTime.now(),
      );

      // Mock playing state for this item
      when(mockAudioPlayerBloc.state).thenReturn(
        AudioPlayerState(
          status: AudioPlayerStatus.success,
          mediaItem: const MediaItem(
            id: 'file:///path/to/test.mp3',
            title: 'Test',
          ),
          playbackState: PlaybackState(playing: true),
        ),
      );

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Tap pause
      await tester.tap(find.byIcon(Icons.pause_rounded));
      verify(
        mockAudioPlayerBloc.add(const AudioPlayerEvent.pauseAudio()),
      ).called(1);
    });

    testWidgets('should show Play button even if playing ANOTHER item', (
      WidgetTester tester,
    ) async {
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

      // Mock playing state for DIFFERENT item
      when(mockAudioPlayerBloc.state).thenReturn(
        AudioPlayerState(
          status: AudioPlayerStatus.success,
          mediaItem: const MediaItem(
            id: 'file:///path/to/OTHER.mp3',
            title: 'Other',
          ),
          playbackState: PlaybackState(playing: true),
        ),
      );

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('should resume playback when paused on this item', (
      WidgetTester tester,
    ) async {
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

      // Mock PAUSED state for this item
      when(mockAudioPlayerBloc.state).thenReturn(
        AudioPlayerState(
          status: AudioPlayerStatus.success,
          mediaItem: const MediaItem(
            id: 'file:///path/to/test.mp3',
            title: 'Test',
          ),
          playbackState: PlaybackState(),
        ),
      );

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      // Should show play icon because it's paused
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tap play
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));

      // Should send playAudio event to AudioPlayerBloc directly (toggle), not playDownloadedSurah
      verify(
        mockAudioPlayerBloc.add(const AudioPlayerEvent.playAudio()),
      ).called(1);
    });

    testWidgets(
      'should trigger retry when retry button clicked (failed status)',
      (WidgetTester tester) async {
        final download = DownloadItem(
          id: 'test_id',
          title: 'Test Surah',
          url: 'https://example.com/test.mp3',
          filePath: '/path/to/test.mp3',
          reciterName: 'Test Reciter',
          status: DownloadStatus.failed,
          progress: 0.0,
          fileSize: 0,
          downloadedSize: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(download));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.refresh_rounded));
        verify(
          mockDownloadsBloc.add(
            const DownloadsEvent.retryDownload(downloadId: 'test_id'),
          ),
        ).called(1);
      },
    );

    testWidgets('retry button should appear for stuck download', (
      WidgetTester tester,
    ) async {
      // Stuck download: Downloading, 0% progress, created > 30s ago
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
        createdAt: DateTime.now().subtract(const Duration(seconds: 31)),
      );

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('delete flow works correctly', (WidgetTester tester) async {
      var deleteCalled = false;
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

      await tester.pumpWidget(
        createTestWidget(download, onDelete: () => deleteCalled = true),
      );

      // 1. Open menu
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      // 2. Select delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // 3. Verify Dialog appears
      expect(find.text('Delete Download'), findsOneWidget);

      // 4. Click cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deleteCalled, isFalse);

      // 5. Open menu again
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // 6. Click delete in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleteCalled, isTrue);
    });
  });

  group('DownloadItemCard - Edge Cases', () {
    testWidgets('should show queue position when pending and position > 0', (
      WidgetTester tester,
    ) async {
      when(mockDownloadQueueManager.getQueuePosition('test_id')).thenReturn(5);

      final download = DownloadItem(
        id: 'test_id',
        title: 'Test Surah',
        url: 'https://example.com/test.mp3',
        filePath: '/path/to/test.mp3',
        reciterName: 'Test Reciter',
        status: DownloadStatus.pending,
        progress: 0.0,
        fileSize: 0,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(download));
      await tester.pumpAndSettle();

      expect(find.text('Pending (#5)'), findsOneWidget);
    });

    testWidgets('should format file sizes correctly', (
      WidgetTester tester,
    ) async {
      // Test 500 Bytes
      var download = DownloadItem(
        id: 'test_id',
        title: 'Test Surah',
        url: 'url',
        filePath: 'path',
        reciterName: 'Reciter',
        status: DownloadStatus.downloading,
        progress: 0.5,
        fileSize: 500,
        downloadedSize: 250,
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(createTestWidget(download));
      expect(find.textContaining('500 B'), findsOneWidget);

      // Test 1.5 KB
      download = download.copyWith(
        fileSize: 1536,
        downloadedSize: 0,
      ); // 1.5 * 1024
      await tester.pumpWidget(createTestWidget(download));
      expect(find.textContaining('1.5 KB'), findsOneWidget);

      // Test 1.5 MB
      download = download.copyWith(
        fileSize: 1572864,
        downloadedSize: 0,
      ); // 1.5 * 1024 * 1024
      await tester.pumpWidget(createTestWidget(download));
      expect(find.textContaining('1.5 MB'), findsOneWidget);

      // Test 1.0 GB
      download = download.copyWith(
        fileSize: 1073741824,
        downloadedSize: 0,
      ); // 1024^3
      await tester.pumpWidget(createTestWidget(download));
      expect(find.textContaining('1.0 GB'), findsOneWidget);
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

      // Act & Assert - Simulate real-time progress updates every second
      for (var second = 0; second <= 5; second++) {
        final double progress = second * 0.2; // 0%, 20%, 40%, 60%, 80%, 100%
        final int downloadedBytes = (1000 * progress).round();
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
          final LinearProgressIndicator progressIndicator = tester
              .widget<LinearProgressIndicator>(
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
        final int expectedPercentage = (progress * 100).round();
        expect(
          find.textContaining('$expectedPercentage%'),
          findsOneWidget,
          reason:
              'Percentage text should update to $expectedPercentage% at second $second',
        );
        percentageHistory.add(expectedPercentage);

        // Print progress update

        // Simulate 1 second delay before next progress update
        // (In real app, DownloadService would emit the next update after ~1 second)
        await tester.pump(const Duration(seconds: 1));
      }

      // Assert - Verify progress increased over time
      expect(progressHistory.length, greaterThan(1));
      for (var i = 1; i < progressHistory.length; i++) {
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

      // Act - Simulate 10 seconds of progress
      for (var second = 0; second <= 10; second++) {
        final double progress = (second / 10).clamp(0.0, 1.0);
        final int downloadedBytes = (10000 * progress).round();
        download = download.copyWith(
          progress: progress,
          downloadedSize: downloadedBytes,
        );

        await tester.pumpWidget(createTestWidget(download));
        await tester.pumpAndSettle();

        // Only check progress bar if it exists (when progress < 1.0)
        final Finder progressIndicatorFinder = find.byType(
          LinearProgressIndicator,
        );
        if (progress < 1.0 && progressIndicatorFinder.evaluate().isNotEmpty) {
          final LinearProgressIndicator progressIndicator = tester
              .widget<LinearProgressIndicator>(progressIndicatorFinder);
          progressHistory.add(progressIndicator.value ?? 0.0);
        }

        // Verify percentage increases
        final int expectedPercentage = (progress * 100).round();
        expect(find.textContaining('$expectedPercentage%'), findsOneWidget);

        // Print progress update

        await tester.pump(const Duration(seconds: 1));
      }

      // Assert - Progress should be increasing
      for (var i = 1; i < progressHistory.length; i++) {
        expect(
          progressHistory[i],
          greaterThan(progressHistory[i - 1]),
          reason: 'Progress should increase over time',
        );
      }
    });
  });
}
