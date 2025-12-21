import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/widgets/download_button.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

class MockDownloadsBloc extends MockBloc<DownloadsEvent, DownloadsState>
    implements DownloadsBloc {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

void main() {
  late MockDownloadsBloc mockDownloadsBloc;
  late MockDownloadsRepository mockDownloadsRepository;

  setUp(() {
    mockDownloadsBloc = MockDownloadsBloc();
    mockDownloadsRepository = MockDownloadsRepository();

    // Default stub for repository
    when(
      () => mockDownloadsRepository.isSurahDownloaded(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockDownloadsRepository.isSurahDownloading(any(), any()),
    ).thenAnswer((_) async => false);

    // Stub statusStream since it's used in initState
    when(
      () => mockDownloadsBloc.statusStream,
    ).thenAnswer((_) => const Stream.empty());

    // Stub downloadUpdates for DownloadButtonBloc
    when(
      () => mockDownloadsRepository.downloadUpdates,
    ).thenAnswer((_) => const Stream.empty());

    // Mock fluttertoast channel
    const channel = MethodChannel('PonnamKarthik/fluttertoast');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return true;
        });
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RepositoryProvider<DownloadsRepository>.value(
        value: mockDownloadsRepository,
        child: BlocProvider<DownloadsBloc>.value(
          value: mockDownloadsBloc,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  const surahUrl = 'https://example.com/001.mp3';
  const surahTitle = 'Al-Fatiha';
  const reciterName = 'Mishary Rashid Alafasy';
  const reciterId = 1;

  testWidgets('shows download icon when not downloaded', (tester) async {
    when(
      () => mockDownloadsRepository.isSurahDownloaded(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockDownloadsRepository.isSurahDownloading(any(), any()),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          url: surahUrl,
          surahTitle: surahTitle,
          reciterName: reciterName,
          reciterId: reciterId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
  });

  testWidgets('shows progress when downloading', (tester) async {
    // Initial checks
    when(
      () => mockDownloadsRepository.isSurahDownloaded(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockDownloadsRepository.isSurahDownloading(any(), any()),
    ).thenAnswer((_) async => true); // It is downloading

    // Return a download item
    final downloadItem = DownloadItem(
      id: '${surahUrl}_$reciterName',
      title: surahTitle,
      url: surahUrl,
      filePath: 'path',
      reciterName: reciterName,
      reciterId: reciterId,
      status: DownloadStatus.downloading,
      progress: 50,
      fileSize: 100,
      downloadedSize: 50,
      createdAt: DateTime.now(),
    );

    when(
      () => mockDownloadsRepository.getDownloadItem(any()),
    ).thenAnswer((_) async => downloadItem);

    // Mock progress stream used by DownloadButtonBloc
    when(
      () => mockDownloadsRepository.getDownloadProgress(any()),
    ).thenAnswer((_) => Stream.value(downloadItem));

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          url: surahUrl,
          surahTitle: surahTitle,
          reciterName: reciterName,
          reciterId: reciterId,
        ),
      ),
    );

    // Wait for BLoC initialization and stream listener
    await tester.pump(); // Init
    await tester.pump(); // Stream update

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows check icon when downloaded', (tester) async {
    when(
      () => mockDownloadsRepository.isSurahDownloaded(any(), any()),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          url: surahUrl,
          surahTitle: surahTitle,
          reciterName: reciterName,
          reciterId: reciterId,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('triggers download event on tap', (tester) async {
    // Not downloaded, not downloading
    when(
      () => mockDownloadsRepository.isSurahDownloaded(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockDownloadsRepository.isSurahDownloading(any(), any()),
    ).thenAnswer((_) async => false);

    // Stub startDownload
    when(
      () => mockDownloadsRepository.startDownload(
        any(),
        title: any(named: 'title'),
        surahTitle: any(named: 'surahTitle'),
        reciterName: any(named: 'reciterName'),
        reciterId: any(named: 'reciterId'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          url: surahUrl,
          surahTitle: surahTitle,
          reciterName: reciterName,
          reciterId: reciterId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.download_rounded));
    await tester.pump();

    verify(
      () => mockDownloadsRepository.startDownload(
        surahUrl,
        title: surahTitle,
        surahTitle: surahTitle,
        reciterName: reciterName,
        reciterId: reciterId,
      ),
    );
    // Drain any pending timers (e.g. Toast)
    await tester.pump(const Duration(seconds: 3));
  });
}
