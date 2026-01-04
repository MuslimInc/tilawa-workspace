import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/core/network/network_info.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_surah_downloaded_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_surah_use_case.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/download_button.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockDownloadsBloc extends MockBloc<DownloadsEvent, DownloadsState>
    implements DownloadsBloc {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

class MockCheckSurahDownloadedUseCase extends Mock
    implements CheckSurahDownloadedUseCase {}

class MockDownloadSurahUseCase extends Mock implements DownloadSurahUseCase {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockDownloadsBloc mockDownloadsBloc;
  late MockDownloadsRepository mockDownloadsRepository;
  late MockCheckSurahDownloadedUseCase mockCheckSurahDownloadedUseCase;
  late MockDownloadSurahUseCase mockDownloadSurahUseCase;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockDownloadsBloc = MockDownloadsBloc();
    mockDownloadsRepository = MockDownloadsRepository();
    mockCheckSurahDownloadedUseCase = MockCheckSurahDownloadedUseCase();
    mockCheckSurahDownloadedUseCase = MockCheckSurahDownloadedUseCase();
    mockDownloadSurahUseCase = MockDownloadSurahUseCase();
    mockNetworkInfo = MockNetworkInfo();

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
    if (!GetIt.instance.isRegistered<NetworkInfo>()) {
      GetIt.instance.registerSingleton<NetworkInfo>(mockNetworkInfo);
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

    // Default network connected
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

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

    // Drain any pending timers from toast
    await tester.pump(const Duration(seconds: 3));
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

  testWidgets('only shows downloading toast once when progress updates', (
    tester,
  ) async {
    final List<MethodCall> methodCalls = [];
    const channel = MethodChannel('PonnamKarthik/fluttertoast');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall methodCall,
    ) async {
      methodCalls.add(methodCall);
      return true;
    });

    when(
      () => mockCheckSurahDownloadedUseCase.call(
        surahId: any(named: 'surahId'),
        reciterName: any(named: 'reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    final progressController = StreamController<DownloadItem>();
    when(
      () => mockDownloadsRepository.getDownloadProgress(any()),
    ).thenAnswer((_) => progressController.stream);

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

    // Start download
    final item1 = DownloadItem(
      id: '${surahUrl}_$reciterName',
      title: surahTitle,
      url: surahUrl,
      filePath: 'path',
      reciterName: reciterName,
      reciterId: reciterId,
      status: DownloadStatus.downloading,
      progress: 0.1,
      fileSize: 100,
      downloadedSize: 10,
      createdAt: DateTime.now(),
    );
    progressController.add(item1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Update progress
    final DownloadItem item2 = item1.copyWith(
      progress: 0.5,
      downloadedSize: 50,
    );
    progressController.add(item2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Update progress again
    final DownloadItem item3 = item2.copyWith(
      progress: 0.9,
      downloadedSize: 90,
    );
    progressController.add(item3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify toast was only shown once for "downloading"
    final List<MethodCall> toastCalls = methodCalls
        .where((call) => call.method == 'showToast')
        .toList();
    expect(toastCalls.length, 1);
    final toastArgs = Map<String, dynamic>.from(
      toastCalls.first.arguments as Map,
    );
    expect(toastArgs['msg'], contains('Downloading'));

    await progressController.close();
    // Drain any pending timers from toast
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('shows localized network error toast on networkError state', (
    tester,
  ) async {
    final List<MethodCall> methodCalls = [];
    const channel = MethodChannel('PonnamKarthik/fluttertoast');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall methodCall,
    ) async {
      methodCalls.add(methodCall);
      return true;
    });

    // Mock initial state: not downloaded
    when(
      () => mockCheckSurahDownloadedUseCase.call(
        surahId: any(named: 'surahId'),
        reciterName: any(named: 'reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    // Mock failure that triggers network error
    when(
      () => mockDownloadSurahUseCase.call(
        surahId: any(named: 'surahId'),
        surahTitle: any(named: 'surahTitle'),
        reciterName: any(named: 'reciterName'),
        reciterId: any(named: 'reciterId'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure('No internet')));

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

    // Tap to download
    await tester.tap(find.byIcon(Icons.download_rounded));
    await tester.pumpAndSettle();

    // Verify network error toast (should be localized, so we check if it matches l10n key)
    final List<MethodCall> toastCalls = methodCalls
        .where((call) => call.method == 'showToast')
        .toList();
    expect(toastCalls.length, 1);
    // Since we use the real localizations in createTestWidget, it should be the English string
    final toastNetworkArgs = Map<String, dynamic>.from(
      toastCalls.first.arguments as Map,
    );
    expect(toastNetworkArgs['msg'], contains('internet connection'));

    // Drain any pending timers from toast
    await tester.pump(const Duration(seconds: 3));
  });
}
