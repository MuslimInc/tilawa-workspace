import 'package:tilawa/test_support/screenutil_compat.dart';
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
import 'package:tilawa/features/reciters/presentation/widgets/download_all_button.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

class MockReciterDownloadBloc
    extends MockBloc<ReciterDownloadEvent, ReciterDownloadState>
    implements ReciterDownloadBloc {}

void main() {
  late MockReciterDownloadBloc mockBloc;

  setUp(() {
    mockBloc = MockReciterDownloadBloc();
    registerFallbackValue(
      const StartReciterDownloadAll(
        reciter: ReciterEntity(
          id: 0,
          name: '',
          letter: '',
          date: '',
          moshaf: [],
        ),
        surahs: [],
      ),
    );
    registerFallbackValue(const CancelReciterDownloadAll(reciterName: ''));

    const channel = MethodChannel('PonnamKarthik/fluttertoast');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return true;
        });
  });

  Widget createWidget({
    required ReciterEntity reciter,
    required List<SurahEntity> surahs,
  }) {
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      child: BlocProvider<ReciterDownloadBloc>.value(
        value: mockBloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DownloadAllButton(reciter: reciter, surahs: surahs),
          ),
        ),
      ),
    );
  }

  const testReciter = ReciterEntity(
    id: 1,
    name: 'Test Reciter',
    letter: 'T',
    date: '2023',
    moshaf: [],
  );

  testWidgets(
    'DownloadAllButton renders download icon and text when not downloading',
    (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const ReciterDownloadState(totalCount: 10));

      await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.text('0/10'), findsOneWidget);
    },
  );

  testWidgets(
    'DownloadAllButton renders pause icon and progress when downloading',
    (tester) async {
      when(() => mockBloc.state).thenReturn(
        const ReciterDownloadState(
          isDownloadingAll: true,
          progress: 0.5,
          totalCount: 10,
          downloadedCount: 5,
        ),
      );

      await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.text('5/10'), findsOneWidget);
    },
  );

  testWidgets('DownloadAllButton is disabled when state is pending', (
    tester,
  ) async {
    when(
      () => mockBloc.state,
    ).thenReturn(const ReciterDownloadState(isPending: true, totalCount: 10));

    await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('reciter_details_download_all_button')),
    );
    verifyNever(() => mockBloc.add(any()));
  });

  testWidgets('DownloadAllButton fires StartReciterDownloadAll on tap', (
    tester,
  ) async {
    when(
      () => mockBloc.state,
    ).thenReturn(const ReciterDownloadState(totalCount: 10));

    await tester.pumpWidget(
      createWidget(reciter: testReciter, surahs: const []),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('reciter_details_download_all_button')),
    );
    verify(
      () => mockBloc.add(any(that: isA<StartReciterDownloadAll>())),
    ).called(1);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'DownloadAllButton renders "All Downloaded" state when all surahs are downloaded',
    (tester) async {
      when(() => mockBloc.state).thenReturn(
        const ReciterDownloadState(totalCount: 10, downloadedCount: 10),
      );

      await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('All Downloaded'), findsOneWidget);

      expect(
        find.byKey(const Key('reciter_details_download_all_button')),
        findsNothing,
      );
    },
  );

  testWidgets('DownloadAllButton shows network error toast', (tester) async {
    // Setup mock toast handler
    var toastCalled = false;
    const channel = MethodChannel('PonnamKarthik/fluttertoast');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'showToast') {
            toastCalled = true;
          }
          return true;
        });

    // Setup bloc to emit network error state
    whenListen(
      mockBloc,
      Stream.fromIterable([
        const ReciterDownloadState(totalCount: 10),
        const ReciterDownloadState(
          errorMessage: 'No internet connection',
          totalCount: 10,
        ),
      ]),
      initialState: const ReciterDownloadState(totalCount: 10),
    );

    await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
    await tester.pump(); // Trigger the state change

    expect(toastCalled, isTrue);

    // Handle pending timers from Toast
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'DownloadAllButton cancels download when button is pressed while downloading',
    (tester) async {
      // Initial state: Downloading
      when(() => mockBloc.state).thenReturn(
        const ReciterDownloadState(isDownloadingAll: true, progress: 0.5),
      );

      await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Tap button to cancel/pause
      await tester.tap(
        find.byKey(const Key('reciter_details_download_all_button')),
      );
      await tester.pump();

      verify(
        () => mockBloc.add(any(that: isA<CancelReciterDownloadAll>())),
      ).called(1);
    },
  );
}
