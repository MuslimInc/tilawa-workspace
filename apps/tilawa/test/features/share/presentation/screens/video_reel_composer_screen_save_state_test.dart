import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa/features/share/presentation/cubit/share_state.dart';
import 'package:tilawa/features/share/presentation/screens/video_reel_composer_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockShareCubit extends Mock implements ShareCubit {}

void main() {
  late _MockShareCubit cubit;
  late StreamController<ShareState> controller;

  const reviewingState = ShareState(
    status: ShareStatus.reviewing,
    content: ShareContent.screenshot(
      filePath: '/tmp/preview.png',
      surahName: 'Al-Fatihah',
      pageNumber: 1,
    ),
    fromAyah: 1,
    toAyah: 7,
    reciterName: 'Test Reciter',
    videoPageSpecs: [],
  );

  setUp(() {
    cubit = _MockShareCubit();
    controller = StreamController<ShareState>.broadcast();

    when(() => cubit.state).thenReturn(reviewingState);
    when(() => cubit.stream).thenAnswer((_) => controller.stream);
    when(
      () => cubit.configureAudioClip(
        surahNumber: any(named: 'surahNumber'),
        fromAyah: any(named: 'fromAyah'),
        toAyah: any(named: 'toAyah'),
        reciterName: any(named: 'reciterName'),
        serverUrl: any(named: 'serverUrl'),
      ),
    ).thenReturn(null);
    when(() => cubit.discardPreparedContent()).thenReturn(null);
    when(() => cubit.shareContent()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await controller.close();
  });

  Widget buildSubject() {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
      home: Scaffold(
        body: BlocProvider<ShareCubit>.value(
          value: cubit,
          child: const VideoReelComposerScreen(
            surahNumber: 1,
            initialFromAyah: 1,
            initialToAyah: 7,
            reciterName: 'Test Reciter',
            reciterServerUrl: 'https://server.test',
          ),
        ),
      ),
    );
  }

  testWidgets('save action enters loading state while export is pending', (
    tester,
  ) async {
    final completer = Completer<String?>();
    when(() => cubit.savePreparedContent()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final Finder saveButtonFinder = find.widgetWithText(OutlinedButton, 'Save');
    expect(saveButtonFinder, findsOneWidget);

    await tester.tap(saveButtonFinder);
    await tester.pump();

    final Finder saveSpinnerFinder = find.descendant(
      of: saveButtonFinder,
      matching: find.byType(CircularProgressIndicator),
    );
    expect(saveSpinnerFinder, findsOneWidget);
    final OutlinedButton savingButton = tester.widget<OutlinedButton>(
      saveButtonFinder,
    );
    expect(savingButton.onPressed, isNull);

    completer.complete('/tmp/exported.mp4');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(saveSpinnerFinder, findsNothing);
  });
}
