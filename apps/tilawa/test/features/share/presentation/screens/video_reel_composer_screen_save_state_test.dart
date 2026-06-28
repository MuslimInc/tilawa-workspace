import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa/features/share/presentation/cubit/share_state.dart';
import 'package:tilawa/features/share/presentation/screens/video_reel_composer_screen.dart';
import 'package:tilawa/features/share/presentation/utils/share_feature_flags.dart';
import 'package:tilawa/features/share/presentation/utils/video_page_specs.dart';
import 'package:tilawa/features/share/presentation/widgets/video_composition.dart';
import 'package:tilawa/features/share/presentation/widgets/video_content_renderer.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockShareCubit extends Mock implements ShareCubit {}

final ByteData _kEmptyAssetManifestBin = const StandardMessageCodec()
    .encodeMessage(<Object?, Object?>{})!;

Uint8List? _qpcV4Bytes;
Uint8List? _pageIndexBytes;

Future<void> _registerRealMushafAssets() async {
  _qpcV4Bytes ??= await _readRepoAssetBytes(const <String>[
    'packages/quran_qcf/assets/quran_fonts/qpc-v4.json',
    '../packages/quran_qcf/assets/quran_fonts/qpc-v4.json',
    '../../packages/quran_qcf/assets/quran_fonts/qpc-v4.json',
  ]);
  _pageIndexBytes ??= await _readRepoAssetBytes(const <String>[
    'packages/quran_qcf/assets/quran_fonts/quran_page_index.json',
    '../packages/quran_qcf/assets/quran_fonts/quran_page_index.json',
    '../../packages/quran_qcf/assets/quran_fonts/quran_page_index.json',
  ]);

  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    ByteData? message,
  ) async {
    if (message == null) return null;

    final String key = utf8.decode(message.buffer.asUint8List());
    if (key == 'AssetManifest.bin') return _kEmptyAssetManifestBin;
    if (key == 'packages/quran_qcf/assets/quran_fonts/qpc-v4.json') {
      return ByteData.sublistView(_qpcV4Bytes!);
    }
    if (key == 'packages/quran_qcf/assets/quran_fonts/quran_page_index.json') {
      return ByteData.sublistView(_pageIndexBytes!);
    }
    return null;
  });
}

Future<Uint8List> _readRepoAssetBytes(List<String> candidates) async {
  for (final String candidate in candidates) {
    final File file = File(candidate);
    if (await file.exists()) {
      return file.readAsBytes();
    }
  }
  throw StateError(
    'Unable to locate asset file. Tried: ${candidates.join(', ')}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  setUpAll(() async {
    if (kReelComposerSingleTree) {
      await _registerRealMushafAssets();
    }
  });

  setUp(() async {
    cubit = _MockShareCubit();
    controller = StreamController<ShareState>.broadcast();

    if (kReelComposerSingleTree) {
      await QuranQcfLocator.resetForTests();
      QuranQcfLocator.setup();
      await quranQcfLocator<MushafService>().ensureLoaded();
    }

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
    if (kReelComposerSingleTree) {
      await QuranQcfLocator.resetForTests();
    }
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

  testWidgets('save action enters loading state while export is pending', (
    tester,
  ) async {
    final completer = Completer<void>();
    when(() => cubit.savePreparedContent()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final Finder saveButtonFinder = find.byKey(
      const ValueKey('video_review_save_button'),
    );
    expect(saveButtonFinder, findsOneWidget);

    await tester.tap(saveButtonFinder);
    await tester.pump();

    final Finder saveSpinnerFinder = find.descendant(
      of: saveButtonFinder,
      matching: find.byType(CircularProgressIndicator),
    );
    expect(saveSpinnerFinder, findsOneWidget);
    final TextButton savingButton = tester.widget<TextButton>(
      find.descendant(of: saveButtonFinder, matching: find.byType(TextButton)),
    );
    expect(savingButton.onPressed, isNull);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(saveSpinnerFinder, findsNothing);
  });

  testWidgets('live preview uses VideoComposition under the single-tree flag', (
    tester,
  ) async {
    if (!kReelComposerSingleTree) {
      return;
    }

    const idleState = ShareState(
      status: ShareStatus.idle,
      fromAyah: 1,
      toAyah: 7,
      reciterName: 'Test Reciter',
      videoPageSpecs: [
        VideoPageSpec(
          pageNumber: 1,
          fromAyah: 1,
          toAyah: 7,
          isInitialSelection: true,
        ),
      ],
    );
    when(() => cubit.state).thenReturn(idleState);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byType(VideoComposition), findsOneWidget);
    expect(find.byType(VideoContentRenderer), findsNothing);
  });
}
