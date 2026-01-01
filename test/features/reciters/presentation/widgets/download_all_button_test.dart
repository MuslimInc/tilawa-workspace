import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
import 'package:tilawa/features/reciters/presentation/widgets/download_all_button.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

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
      when(() => mockBloc.state).thenReturn(const ReciterDownloadState());

      await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.text('Download All'), findsOneWidget);
    },
  );

  testWidgets(
    'DownloadAllButton renders pause icon and progress when downloading',
    (tester) async {
      when(() => mockBloc.state).thenReturn(
        const ReciterDownloadState(isDownloadingAll: true, progress: 0.5),
      );

      await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.text('Pause 50%'), findsOneWidget);
    },
  );

  testWidgets('DownloadAllButton fires StartReciterDownloadAll on tap', (
    tester,
  ) async {
    when(() => mockBloc.state).thenReturn(const ReciterDownloadState());

    await tester.pumpWidget(
      createWidget(reciter: testReciter, surahs: const []),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('download_all_button')));
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

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('All Downloaded'), findsOneWidget);

      final ElevatedButton button = tester.widget<ElevatedButton>(
        find.byKey(const Key('download_all_button')),
      );
      expect(button.onPressed, isNull);
    },
  );
  testWidgets('DownloadAllButton shows toast on network error', (tester) async {
    // Stream controller to simulate state changes
    final stateController = StreamController<ReciterDownloadState>.broadcast();
    when(() => mockBloc.stream).thenAnswer((_) => stateController.stream);
    when(() => mockBloc.state).thenReturn(const ReciterDownloadState());

    await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
    await tester.pumpAndSettle();

    // Emit error state
    stateController.add(
      const ReciterDownloadState(errorMessage: 'No internet connection'),
    );
    await tester.pumpAndSettle(); // Allow listener to react

    // Verify MethodChannel call for toast
    /*
         Since we can't easily access the capture log from the existing setUp without modifying it widely,
         we rely on the fact that if the code works, it calls the channel.
         To verify it strictly, we'd need to check the log. 
         Let's locally override the handler for this test.
      */
    var toastCalled = false;
    const channel = MethodChannel('PonnamKarthik/fluttertoast');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'showToast') {
            toastCalled = true;
          }
          return true;
        });

    stateController.add(
      const ReciterDownloadState(errorMessage: 'Another internet error'),
    );
    await tester.pumpAndSettle();

    expect(toastCalled, isTrue);
    // Flush any pending timers from Toast
    await tester.pump(const Duration(seconds: 2));

    await stateController.close();
  });

  testWidgets(
    'DownloadAllButton shows "Downloading..." toast when download starts',
    (tester) async {
      final stateController =
          StreamController<ReciterDownloadState>.broadcast();
      when(() => mockBloc.stream).thenAnswer((_) => stateController.stream);
      when(() => mockBloc.state).thenReturn(const ReciterDownloadState());

      await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
      await tester.pumpAndSettle();

      var toastCalled = false;
      const channel = MethodChannel('PonnamKarthik/fluttertoast');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'showToast' &&
                methodCall.arguments['msg'] == 'Downloading all surahs...') {
              toastCalled = true;
            }
            return true;
          });

      // Valid transition: isDownloadingAll: false -> true
      stateController.add(const ReciterDownloadState(isDownloadingAll: true));
      await tester.pumpAndSettle();

      expect(
        toastCalled,
        isTrue,
        reason: 'Toast should show when downloading starts',
      );
      await tester.pump(const Duration(seconds: 2)); // flush timer
      await stateController.close();
    },
  );

  testWidgets(
    'DownloadAllButton cancels download when button is pressed while downloading',
    (tester) async {
      // Initial state: Downloading
      when(() => mockBloc.state).thenReturn(
        const ReciterDownloadState(isDownloadingAll: true, progress: 0.5),
      );

      await tester.pumpWidget(createWidget(reciter: testReciter, surahs: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Tap button to cancel/pause
      await tester.tap(find.byKey(const Key('download_all_button')));
      await tester.pump();

      verify(
        () => mockBloc.add(any(that: isA<CancelReciterDownloadAll>())),
      ).called(1);
    },
  );
}
