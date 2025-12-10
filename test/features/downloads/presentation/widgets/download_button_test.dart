import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/widgets/download_button.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

class MockDownloadsBloc extends MockBloc<DownloadsEvent, DownloadsState>
    implements DownloadsBloc {}

void main() {
  late MockDownloadsBloc mockDownloadsBloc;

  setUp(() {
    mockDownloadsBloc = MockDownloadsBloc();

    // Stub getDownloadProgressStream to return an empty stream by default
    when(
      () => mockDownloadsBloc.getDownloadProgressStream(any()),
    ).thenAnswer((_) => const Stream<DownloadProgress>.empty());

    // Stub statusStream since it's used in initState
    when(
      () => mockDownloadsBloc.statusStream,
    ).thenAnswer((_) => const Stream.empty());

    // Mock fluttertoast channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('PonnamKarthik/fluttertoast'),
          (MethodCall methodCall) async {
            return true;
          },
        );
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<DownloadsBloc>.value(
        value: mockDownloadsBloc,
        child: Scaffold(body: child),
      ),
    );
  }

  const surahId = '1';
  const surahTitle = 'Al-Fatiha';
  const reciterName = 'Mishary Rashid Alafasy';

  testWidgets('shows download icon when not downloaded', (tester) async {
    when(
      () => mockDownloadsBloc.state,
    ).thenReturn(const DownloadsState(status: DownloadsStateStatus.loaded));

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          surahId: surahId,
          surahTitle: surahTitle,
          reciterName: reciterName,
        ),
      ),
    );

    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
  });

  testWidgets('shows progress when downloading', (tester) async {
    final downloadItem = DownloadItem(
      id: surahId,
      title: surahTitle,
      url: 'url',
      filePath: 'path',
      reciterName: reciterName,
      status: DownloadStatus.downloading,
      progress: 0.5,
      fileSize: 100,
      downloadedSize: 50,
      createdAt: DateTime.now(),
    );

    when(() => mockDownloadsBloc.state).thenReturn(
      DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: {
          reciterName: {
            'Default': [downloadItem],
          },
        },
      ),
    );

    // Stub the progress stream for this specific download
    const downloadId = surahId;
    when(
      () => mockDownloadsBloc.getDownloadProgressStream(downloadId),
    ).thenAnswer(
      (_) => Stream.value(
        const DownloadProgress(
          id: downloadId,
          status: DownloadStatus.downloading,
          progress: 0.5,
          downloadedSize: 50,
          fileSize: 100,
        ),
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          surahId: surahId,
          surahTitle: surahTitle,
          reciterName: reciterName,
        ),
      ),
    );

    // Wait for StreamBuilder to process
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('shows hourglass when pending', (tester) async {
    final downloadItem = DownloadItem(
      id: surahId,
      title: surahTitle,
      url: 'url',
      filePath: 'path',
      reciterName: reciterName,
      status: DownloadStatus.pending,
      progress: 0.0,
      fileSize: 100,
      downloadedSize: 0,
      createdAt: DateTime.now(),
    );

    when(() => mockDownloadsBloc.state).thenReturn(
      DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: {
          reciterName: {
            'Default': [downloadItem],
          },
        },
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          surahId: surahId,
          surahTitle: surahTitle,
          reciterName: reciterName,
        ),
      ),
    );

    // Use pump() not pumpAndSettle() since pending animation repeats infinitely
    await tester.pump();

    // Pending state shows pulsing hourglass icon
    expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
  });

  testWidgets('shows check icon when downloaded', (tester) async {
    final downloadItem = DownloadItem(
      id: surahId,
      title: surahTitle,
      url: 'url',
      filePath: 'path',
      reciterName: reciterName,
      status: DownloadStatus.completed,
      progress: 1.0,
      fileSize: 100,
      downloadedSize: 100,
      createdAt: DateTime.now(),
    );

    when(() => mockDownloadsBloc.state).thenReturn(
      DownloadsState(
        status: DownloadsStateStatus.loaded,
        downloads: {
          reciterName: {
            'Default': [downloadItem],
          },
        },
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          surahId: surahId,
          surahTitle: surahTitle,
          reciterName: reciterName,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Completed state shows solid check_circle icon (not outline)
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('triggers download event on tap', (tester) async {
    when(
      () => mockDownloadsBloc.state,
    ).thenReturn(const DownloadsState(status: DownloadsStateStatus.loaded));

    await tester.pumpWidget(
      createTestWidget(
        const DownloadButton(
          surahId: surahId,
          surahTitle: surahTitle,
          reciterName: reciterName,
        ),
      ),
    );
    await tester.pumpAndSettle(); // Wait for initial animation

    await tester.tap(find.byIcon(Icons.download_rounded));
    await tester.pump();
    // Wait for toast timer (1 second) and animation (300ms)
    await tester.pump(const Duration(seconds: 2));

    verify(
      () => mockDownloadsBloc.add(
        const DownloadSurahEvent(
          surahId: surahId,
          surahTitle: surahTitle,
          reciterName: reciterName,
        ),
      ),
    ).called(1);
  });
}
