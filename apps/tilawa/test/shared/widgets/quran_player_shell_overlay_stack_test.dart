import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layer.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layout.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

const AudioEntity _testAudio = AudioEntity(
  id: '1',
  title: 'Al-Fatiha',
  url: 'https://example.com/001.mp3',
  duration: Duration(minutes: 1),
  artist: 'Test Reciter',
);

QuranPlayerMorphLayout _testMorphLayout() {
  final barTokens = TilawaMediaPlayerBarTokens.defaults();
  return QuranPlayerMorphLayout.compute(
    progress: 0.5,
    viewport: const Size(400, 800),
    miniBarRect: const Rect.fromLTWH(0, 692, 400, 108),
    sheetOffsetY: 200,
    geometry: QuranPlayerMorphThemeGeometry.fromBarTokens(
      spaceLarge: 16,
      progressHeight: 3,
      barContentPadding: barTokens.contentPadding,
      barTokens: barTokens,
      expandedArtBorderRadius: 12,
    ),
  );
}

/// Mirrors shell overlay morph slot in [QuranPlayerWidget._buildPlayerTree].
Widget _validMorphStackSlot({required Widget morphLayer}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: morphLayer,
        ),
      ),
    ],
  );
}

/// Invalid layout that threw during expand (regression guard).
Widget _invalidMorphStackSlot({required Widget morphLayer}) {
  return Stack(
    fit: StackFit.expand,
    children: [
      IgnorePointer(
        child: Positioned.fill(child: morphLayer),
      ),
    ],
  );
}

void main() {
  group('Shell overlay morph stack', () {
    testWidgets('Positioned.fill is a direct Stack child', (tester) async {
      final Widget morph = QuranPlayerMorphLayer(
        audio: _testAudio,
        handoffT: 0.5,
        layout: _testMorphLayout(),
        onImageBackdrop: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: const Color(0xFF2E7D6F)),
          home: Scaffold(
            body: _validMorphStackSlot(morphLayer: morph),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuranPlayerMorphLayer), findsOneWidget);
    });

    testWidgets('IgnorePointer wrapping Positioned throws ParentData error', (
      tester,
    ) async {
      final Widget morph = QuranPlayerMorphLayer(
        audio: _testAudio,
        handoffT: 0.5,
        layout: _testMorphLayout(),
        onImageBackdrop: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: const Color(0xFF2E7D6F)),
          home: Scaffold(
            body: _invalidMorphStackSlot(morphLayer: morph),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isFlutterError);
    });
  });
}
