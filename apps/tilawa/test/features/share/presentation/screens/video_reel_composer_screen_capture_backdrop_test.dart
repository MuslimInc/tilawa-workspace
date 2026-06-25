import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa/features/share/presentation/cubit/share_state.dart';
import 'package:tilawa/features/share/presentation/screens/video_reel_composer_screen.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockShareCubit extends Mock implements ShareCubit {}

/// Verifies that the reel composer swaps the live mushaf preview for a
/// lightweight `_GeneratingBackdrop` while the cubit is in
/// [ShareStatus.capturing] / [ShareStatus.generating]. The backdrop is
/// identified by its `ValueKey('generating_backdrop')` and the live tree
/// by `ValueKey('live_preview')`.
///
/// We deliberately drive only the generating/capturing states here so the
/// live preview's GetIt lookups (MushafService et al.) never run — those
/// require real asset registration that lives in
/// `mushaf_page_renderer_responsive_test.dart`.
void main() {
  late _MockShareCubit cubit;
  late StreamController<ShareState> controller;

  const generatingState = ShareState(
    status: ShareStatus.generating,
    progress: 0.42,
    progressMessage: 'Encoding video',
    fromAyah: 1,
    toAyah: 7,
    reciterName: 'Test Reciter',
    videoPageSpecs: [],
  );

  const capturingState = ShareState(
    status: ShareStatus.capturing,
    progressMessage: 'Capturing frames',
    fromAyah: 1,
    toAyah: 7,
    reciterName: 'Test Reciter',
    videoPageSpecs: [],
  );

  setUp(() {
    cubit = _MockShareCubit();
    controller = StreamController<ShareState>.broadcast();

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
  });

  tearDown(() async {
    await controller.close();
  });

  Widget buildSubject() {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
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

  testWidgets(
    'mounts the generating backdrop and unmounts the live preview while '
    'state is generating',
    (tester) async {
      when(() => cubit.state).thenReturn(generatingState);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
        find.byKey(const ValueKey('generating_backdrop')),
        findsOneWidget,
        reason:
            'The lightweight backdrop must be the only background widget '
            'while the cubit is generating.',
      );
      expect(
        find.byKey(const ValueKey('live_preview')),
        findsNothing,
        reason:
            'The live mushaf preview must not be in the tree during '
            'generation — only the offstage capture surface should be '
            'rendering a mushaf page.',
      );
    },
  );

  testWidgets(
    'mounts the generating backdrop and unmounts the live preview while '
    'state is capturing',
    (tester) async {
      when(() => cubit.state).thenReturn(capturingState);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(const ValueKey('generating_backdrop')), findsOneWidget);
      expect(find.byKey(const ValueKey('live_preview')), findsNothing);
    },
  );

  testWidgets('shows the cubit progress message inside the backdrop', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(generatingState);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Encoding video'), findsOneWidget);
  });
}
