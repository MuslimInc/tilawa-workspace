import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_semantics_ids.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/shared/widgets/quran_player_expand_physics.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layer.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layout.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

const AudioEntity _audio = AudioEntity(
  id: '1',
  title: 'Al-Fatiha',
  url: 'https://example.com/1.mp3',
  duration: Duration(minutes: 1),
  artist: 'Reciter',
);

QuranPlayerMorphLayout _layout({
  required double progress,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final barTokens = TilawaMediaPlayerBarTokens.defaults();
  return QuranPlayerMorphLayout.compute(
    progress: progress,
    viewport: const Size(400, 800),
    miniBarRect: const Rect.fromLTWH(16, 620, 368, 76),
    sheetOffsetY: 0,
    geometry: QuranPlayerMorphThemeGeometry.fromBarTokens(
      spaceLarge: 16,
      progressHeight: 3,
      barContentPadding: barTokens.contentPadding,
      barTokens: barTokens,
      expandedArtBorderRadius: 16,
    ),
    textDirection: textDirection,
  );
}

Widget _pumpMorph({
  required double handoffT,
  required QuranPlayerMorphLayout layout,
  bool onImageBackdrop = false,
  AudioEntity audio = _audio,
}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: const Color(0xFF2E7D6F)),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: QuranPlayerMorphLayer(
        audio: audio,
        handoffT: handoffT,
        layout: layout,
        onImageBackdrop: onImageBackdrop,
      ),
    ),
  );
}

void main() {
  group('PlayerExpandMetricsScope', () {
    testWidgets('maybeOf returns metrics and notifies on handoff change', (
      tester,
    ) async {
      const PlayerExpandTransitionMetrics collapsed =
          PlayerExpandTransitionMetrics(
            miniOpacity: 1,
            expandedOpacity: 0,
            handoffT: 0,
            stageChromeOpacity: 1,
            miniIdentityOpacity: 1,
            sheetPresentationOpacity: 0,
            backdropOpacity: 0,
            scrimOpacity: 0,
            miniSlideY: 0,
            sheetMotionT: 0,
            queueChromeT: 0,
            showMiniPlayer: true,
            showExpandedSheet: false,
            showMorphLayer: false,
          );
      const PlayerExpandTransitionMetrics mid = PlayerExpandTransitionMetrics(
        miniOpacity: 0.5,
        expandedOpacity: 0.5,
        handoffT: 0.5,
        stageChromeOpacity: 0.5,
        miniIdentityOpacity: 0.5,
        sheetPresentationOpacity: 0.5,
        backdropOpacity: 0,
        scrimOpacity: 0.1,
        miniSlideY: 0,
        sheetMotionT: 0.5,
        queueChromeT: 0,
        showMiniPlayer: true,
        showExpandedSheet: true,
        showMorphLayer: true,
      );

      PlayerExpandTransitionMetrics? seen;

      await tester.pumpWidget(
        PlayerExpandMetricsScope(
          metrics: collapsed,
          child: Builder(
            builder: (context) {
              seen = PlayerExpandMetricsScope.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(seen, collapsed);

      await tester.pumpWidget(
        PlayerExpandMetricsScope(
          metrics: mid,
          child: Builder(
            builder: (context) {
              seen = PlayerExpandMetricsScope.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(seen?.handoffT, 0.5);
    });
  });

  group('QuranPlayerMorphLayer', () {
    testWidgets('handoff below threshold renders empty', (tester) async {
      await tester.pumpWidget(
        _pumpMorph(handoffT: 0.01, layout: _layout(progress: 0.5)),
      );
      await tester.pump();

      expect(find.byType(QuranPlayerMorphLayer), findsOneWidget);
      expect(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.expandedArtwork),
        findsNothing,
      );
    });

    testWidgets('vertical identity shows title under artwork', (tester) async {
      final QuranPlayerMorphLayout layout = _layout(progress: 0.9);
      expect(layout.horizontalIdentity, isFalse);
      expect(layout.metadataIsVerticallyStacked, isTrue);

      await tester.pumpWidget(
        _pumpMorph(handoffT: 0.6, layout: layout),
      );
      await tester.pump();

      expect(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.expandedArtwork),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.expandedTrackTitle),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier(QuranPlayerSemanticsIds.expandedTrackArtist),
        findsOneWidget,
      );
    });

    testWidgets('null artUri uses placeholder', (tester) async {
      await tester.pumpWidget(
        _pumpMorph(
          handoffT: 0.5,
          layout: _layout(progress: 0.2),
          audio: const AudioEntity(
            id: '2',
            title: 'Al-Fatiha',
            url: 'https://example.com/2.mp3',
            duration: Duration(minutes: 1),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(FluentIcons.music_note_2_24_filled), findsOneWidget);
    });

    testWidgets('onImageBackdrop adjusts subtitle opacity', (tester) async {
      await tester.pumpWidget(
        _pumpMorph(
          handoffT: 0.5,
          layout: _layout(progress: 0.2),
          onImageBackdrop: true,
        ),
      );
      await tester.pump();
      expect(find.text('Reciter'), findsOneWidget);
    });

    testWidgets('RTL Arabic metadata fits at 1.4x during morph transition', (
      tester,
    ) async {
      const audio = AudioEntity(
        id: '1',
        title: 'سورة الفاتحة',
        url: 'https://example.com/1.mp3',
        duration: Duration(minutes: 1),
        artist: 'محمد البراك',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: const Color(0xFF2E7D6F)),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            );
          },
          home: Scaffold(
            body: QuranPlayerMorphLayer(
              audio: audio,
              handoffT: 0.6,
              layout: _layout(
                progress: 0.55,
                textDirection: TextDirection.rtl,
              ),
              onImageBackdrop: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('سورة الفاتحة'), findsOneWidget);
      expect(find.text('محمد البراك'), findsOneWidget);
    });

    testWidgets('RTL Arabic metadata fits at 1.4x in tight mini band', (
      tester,
    ) async {
      const audio = AudioEntity(
        id: '1',
        title: 'سورة الفاتحة',
        url: 'https://example.com/1.mp3',
        duration: Duration(minutes: 1),
        artist: 'محمد البراك',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: const Color(0xFF2E7D6F)),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            );
          },
          home: Scaffold(
            body: QuranPlayerMorphLayer(
              audio: audio,
              handoffT: 0.6,
              layout: _layout(
                progress: 0.05,
                textDirection: TextDirection.rtl,
              ),
              onImageBackdrop: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('سورة الفاتحة'), findsOneWidget);
      expect(find.text('محمد البراك'), findsOneWidget);
    });
  });
}
