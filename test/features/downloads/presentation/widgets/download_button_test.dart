import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/check_surah_downloaded_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/download_surah_use_case.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/widgets/download_button.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

class MockDownloadsBloc extends MockBloc<DownloadsEvent, DownloadsState>
    implements DownloadsBloc {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

class MockCheckSurahDownloadedUseCase extends Mock
    implements CheckSurahDownloadedUseCase {}

class MockDownloadSurahUseCase extends Mock implements DownloadSurahUseCase {}

void main() {
  late MockDownloadsBloc mockDownloadsBloc;
  late MockDownloadsRepository mockDownloadsRepository;
  late MockCheckSurahDownloadedUseCase mockCheckSurahDownloadedUseCase;
  late MockDownloadSurahUseCase mockDownloadSurahUseCase;

  setUp(() {
    mockDownloadsBloc = MockDownloadsBloc();
    mockDownloadsRepository = MockDownloadsRepository();
    mockCheckSurahDownloadedUseCase = MockCheckSurahDownloadedUseCase();
    mockDownloadSurahUseCase = MockDownloadSurahUseCase();

    // Register mocks in GetIt
    if (!GetIt.instance.isRegistered<CheckSurahDownloadedUseCase>()) {
      GetIt.instance.registerSingleton<CheckSurahDownloadedUseCase>(
        mockCheckSurahDownloadedUseCase,
      );
    }
    if (!GetIt.instance.isRegistered<DownloadSurahUseCase>()) {
      GetIt.instance.registerSingleton<DownloadSurahUseCase>(
        mockDownloadSurahUseCase,
      );
    }
    if (!GetIt.instance.isRegistered<DownloadsRepository>()) {
      GetIt.instance.registerSingleton<DownloadsRepository>(
        mockDownloadsRepository,
      );
    }

    // Default stub for repository
    when(
      () => mockDownloadsRepository.isSurahDownloaded(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockDownloadsRepository.isSurahDownloading(any(), any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockDownloadsRepository.getDownloadProgress(any()),
    ).thenAnswer((_) => const Stream.empty());

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

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false), // Fix for shader error
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
      () => mockCheckSurahDownloadedUseCase.call(
        surahId: any(named: 'surahId'),
        reciterName: any(named: 'reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

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
      () => mockCheckSurahDownloadedUseCase.call(
        surahId: any(named: 'surahId'),
        reciterName: any(named: 'reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    // Return a download item
    final downloadItem = DownloadItem(
      id: '${surahUrl}_$reciterName',
      title: surahTitle,
      url: surahUrl,
      filePath: 'path',
      reciterName: reciterName,
      reciterId: reciterId,
      status: DownloadStatus.downloading,
      progress: 0.5,
      fileSize: 100,
      downloadedSize: 50,
      createdAt: DateTime.now(),
    );

    // Mock progress stream used by DownloadButtonBloc
    // Note: DownloadButton uses ObserveDownloadProgressUseCase(repo), which calls repo.getDownloadProgress
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
          // Force initial state to avoid race condition with stream
          initialIsDownloading: true,
          initialProgress: 0.5,
        ),
      ),
    );

    await tester.pump();
    // Allow animations to start
    await tester.pump(const Duration(milliseconds: 50));

    // We expect a CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows check icon when downloaded', (tester) async {
    when(
      () => mockCheckSurahDownloadedUseCase.call(
        surahId: any(named: 'surahId'),
        reciterName: any(named: 'reciterName'),
      ),
    ).thenAnswer((_) async => const Right(true));

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
    // Not downloaded
    when(
      () => mockCheckSurahDownloadedUseCase.call(
        surahId: any(named: 'surahId'),
        reciterName: any(named: 'reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    // Stub downloadSurah
    when(
      () => mockDownloadSurahUseCase.call(
        surahId: any(named: 'surahId'),
        surahTitle: any(named: 'surahTitle'),
        reciterName: any(named: 'reciterName'),
        reciterId: any(named: 'reciterId'),
      ),
    ).thenAnswer((_) async => const Right(null));

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
      () => mockDownloadSurahUseCase.call(
        surahId: any(named: 'surahId'),
        surahTitle: any(named: 'surahTitle'),
        reciterName: any(named: 'reciterName'),
        reciterId: any(named: 'reciterId'),
      ),
    ).called(1);

    // Drain any pending timers
    await tester.pump(const Duration(seconds: 3));
  });
}
