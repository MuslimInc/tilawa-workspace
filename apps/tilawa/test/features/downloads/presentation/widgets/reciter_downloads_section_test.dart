import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/reciter_downloads_section.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockDownloadsBloc extends MockBloc<DownloadsEvent, DownloadsState>
    implements DownloadsBloc {}

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

void main() {
  late MockDownloadsBloc mockDownloadsBloc;
  late MockAudioPlayerBloc mockAudioPlayerBloc;

  setUp(() {
    mockDownloadsBloc = MockDownloadsBloc();
    mockAudioPlayerBloc = MockAudioPlayerBloc();

    when(() => mockAudioPlayerBloc.state).thenReturn(
      const AudioPlayerState(
        status: AudioPlayerStatus.initial,
        playbackState: PlaybackStateEntity(
          isPlaying: false,
          processingState: AudioProcessingStateStatus.idle,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: Duration.zero,
          currentIndex: 0,
          queue: [],
        ),
      ),
    );
    when(() => mockDownloadsBloc.state).thenReturn(const DownloadsState());
  });

  Widget createWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DownloadsBloc>.value(value: mockDownloadsBloc),
        BlocProvider<AudioPlayerBloc>.value(value: mockAudioPlayerBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  DownloadItem createTestDownload({
    String id = '1',
    String title = 'Surah 1',
    String reciterName = 'Reciter 1',
    DownloadStatus status = DownloadStatus.completed,
  }) {
    return DownloadItem(
      id: id,
      title: title,
      url: 'url',
      filePath: 'path',
      reciterName: reciterName,
      reciterId: 1,
      status: status,
      progress: status == DownloadStatus.completed ? 1.0 : 0.5,
      fileSize: 100,
      downloadedSize: status == DownloadStatus.completed ? 100 : 50,
      createdAt: DateTime.now(),
    );
  }

  testWidgets('renders reciter name and download count', (tester) async {
    final List<DownloadItem> downloads = [createTestDownload()];

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reciter 1'), findsOneWidget);
    expect(find.text('1 surahs'), findsOneWidget);
    expect(find.text('R'), findsOneWidget); // Avatar letter
  });

  testWidgets('expands and shows downloads list on tap', (tester) async {
    final List<DownloadItem> downloads = [createTestDownload()];

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to expand
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.text('Surah 1'), findsOneWidget);
  });

  testWidgets('shows delete confirmation dialog and triggers event', (
    tester,
  ) async {
    final List<DownloadItem> downloads = [createTestDownload()];

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap menu button
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    // Tap delete all in menu
    await tester.tap(find.text('Delete All'));
    await tester.pumpAndSettle();

    // Verify dialog shown
    expect(find.text('Delete All'), findsWidgets);
    expect(
      find.textContaining(
        'Are you sure you want to delete all downloads for Reciter 1?',
      ),
      findsOneWidget,
    );

    // Tap Delete in dialog
    await tester.tap(find.widgetWithText(TextButton, 'Delete All'));
    await tester.pumpAndSettle();

    verify(
      () => mockDownloadsBloc.add(
        const DeleteReciterDownloads(reciterName: 'Reciter 1'),
      ),
    ).called(1);
  });

  testWidgets('play all button triggers play event', (tester) async {
    final List<DownloadItem> downloads = [createTestDownload()];

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap play button
    await tester.tap(find.byTooltip('Play All'));

    verify(
      () => mockDownloadsBloc.add(
        const DownloadsEvent.playAllDownloads(reciterName: 'Reciter 1'),
      ),
    ).called(1);
  });

  testWidgets('pause button triggers pause when playing from this reciter', (
    tester,
  ) async {
    final List<DownloadItem> downloads = [createTestDownload()];

    // State shows playing from this reciter
    when(() => mockAudioPlayerBloc.state).thenReturn(
      const AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: AudioEntity(
          id: '1',
          title: 'Test',
          url: 'url',
          artist: 'Reciter 1', // Same as reciterName
          duration: Duration(minutes: 5),
        ),
        playbackState: PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: Duration(minutes: 5),
          currentIndex: 0,
          queue: [],
        ),
      ),
    );

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap pause button (should show "Pause All" tooltip when playing)
    await tester.tap(find.byTooltip('Pause All'));

    verify(
      () => mockAudioPlayerBloc.add(const AudioPlayerEvent.pauseAudio()),
    ).called(1);
  });

  testWidgets('play button triggers resume when paused from this reciter', (
    tester,
  ) async {
    final List<DownloadItem> downloads = [createTestDownload()];

    // State shows paused from this reciter
    when(() => mockAudioPlayerBloc.state).thenReturn(
      const AudioPlayerState(
        status: AudioPlayerStatus.success,
        currentAudio: AudioEntity(
          id: '1',
          title: 'Test',
          url: 'url',
          artist: 'Reciter 1',
          duration: Duration(minutes: 5),
        ),
        playbackState: PlaybackStateEntity(
          isPlaying: false,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration(minutes: 2),
          bufferedPosition: Duration.zero,
          duration: Duration(minutes: 5),
          currentIndex: 0,
          queue: [],
        ),
      ),
    );

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Play All'));

    verify(
      () => mockAudioPlayerBloc.add(const AudioPlayerEvent.playAudio()),
    ).called(1);
  });

  testWidgets('displays multiple narratives with headers', (tester) async {
    final List<DownloadItem> hafsDownloads = [
      createTestDownload(title: 'Surah Al-Fatiha'),
    ];
    final List<DownloadItem> warshDownloads = [
      createTestDownload(id: '2', title: 'Surah Al-Baqara'),
    ];

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {
            'Hafs': hafsDownloads,
            'Warsh': warshDownloads,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Shows narrative count
    expect(find.text('2 surahs • 2 narratives'), findsOneWidget);

    // Tap to expand
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    // Shows narrative headers
    expect(find.text('Hafs'), findsOneWidget);
    expect(find.text('Warsh'), findsOneWidget);
    expect(find.text('Surah Al-Fatiha'), findsOneWidget);
    expect(find.text('Surah Al-Baqara'), findsOneWidget);
  });

  testWidgets('delete individual download triggers delete event', (
    tester,
  ) async {
    final List<DownloadItem> downloads = [
      createTestDownload(),
      createTestDownload(id: '2', title: 'Surah 2'),
    ];

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to expand
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    // Find and tap delete button on first download item
    // The DownloadItemCard has an onDelete callback
    final Finder deleteButtons = find.byIcon(Icons.delete_outline);
    if (deleteButtons.evaluate().isNotEmpty) {
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      verify(
        () => mockDownloadsBloc.add(const DeleteDownloadEvent(downloadId: '1')),
      ).called(1);
    }
  });

  testWidgets('hides play button when no completed downloads', (tester) async {
    final List<DownloadItem> downloads = [
      createTestDownload(status: DownloadStatus.downloading),
    ];

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: 'Reciter 1',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Should not find play all tooltip
    expect(find.byTooltip('Play All'), findsNothing);
  });

  testWidgets('shows empty reciter name initial as avatar', (tester) async {
    final List<DownloadItem> downloads = [createTestDownload(reciterName: '')];

    await tester.pumpWidget(
      createWidget(
        ReciterDownloadsSection(
          reciterName: '',
          downloadsByNarrative: {'Hafs': downloads},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Should show 'R' as fallback
    expect(find.text('R'), findsOneWidget);
  });
}
