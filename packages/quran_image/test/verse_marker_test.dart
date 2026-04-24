import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/domain/entities/verse_marker_data.dart';
import 'package:quran_image/qcf_marker_path.dart';
import 'package:quran_image/verse_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getQcfMarkerPath returns a non-empty bounded path', () {
    final path = getQcfMarkerPath(const Size(24, 32));
    final bounds = path.getBounds();

    expect(bounds.isEmpty, isFalse);
    expect(bounds.width, greaterThan(0));
    expect(bounds.height, greaterThan(0));
  });

  test(
    'warmUpNumbers completes for clamped and duplicate ayah numbers',
    () async {
      await VerseMarker.warmUpNumbers(
        markerWidth: 20,
        verseNumbers: const <int>[0, 1, 5, 5, 999],
        batchSize: 2,
      );

      await VerseMarker.warmUpAll(markerWidth: 20, batchSize: 50);
    },
  );

  testWidgets('VerseMarker builds marker paint and glyph text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: VerseMarker(verseNumber: 7, width: 24, height: 30.5),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(VerseMarker),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(VerseMarker),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
  });

  testWidgets('VerseMarkersOverlay paints empty and non-empty marker sets', (
    tester,
  ) async {
    final markers = <VerseMarkerData>[
      const VerseMarkerData(sura: 1, ayah: 1, line: 0, centerX: 0.1),
      const VerseMarkerData(sura: 2, ayah: 255, line: 20, centerX: 0.95),
    ];

    Future<void> pumpOverlay(List<VerseMarkerData> data) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: VerseMarkersOverlay(
                markers: data,
                pageWidth: 300,
                lineHeight: 24,
                yOffsets: List<double>.generate(15, (index) => index * 24),
              ),
            ),
          ),
        ),
      );
    }

    await pumpOverlay(const <VerseMarkerData>[]);
    expect(
      find.descendant(
        of: find.byType(VerseMarkersOverlay),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    await pumpOverlay(markers);
    expect(
      find.descendant(
        of: find.byType(VerseMarkersOverlay),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
