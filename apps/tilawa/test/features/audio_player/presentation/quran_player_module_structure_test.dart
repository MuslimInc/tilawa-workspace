import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/quran_player/quran_player_widget.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart'
    as shared_export;

void main() {
  group('Quran player module layout', () {
    final String libRoot =
        'lib/features/audio_player/presentation/widgets/quran_player';

    test('canonical library lives under audio_player presentation', () {
      expect(
        File('$libRoot/quran_player_widget.dart').existsSync(),
        isTrue,
      );
    });

    test('widget implementation is split into part files', () {
      final File mainLib = File('$libRoot/quran_player_widget.dart');
      final String mainSource = mainLib.readAsStringSync();
      const List<String> expectedParts = <String>[
        "part 'quran_player_organisms.dart';",
        "part 'quran_player_controls.dart';",
        "part 'quran_player_mini.dart';",
        "part 'quran_player_queue.dart';",
        "part 'quran_player_route_page.dart';",
      ];
      for (final String part in expectedParts) {
        expect(mainSource, contains(part), reason: part);
      }
    });

    test('no single part file exceeds 2200 lines', () {
      final Directory dir = Directory(libRoot);
      final Iterable<File> dartFiles = dir.listSync().whereType<File>().where(
        (File f) => f.path.endsWith('.dart'),
      );
      for (final File file in dartFiles) {
        final int lines = file.readAsLinesSync().length;
        expect(
          lines,
          lessThan(2200),
          reason: '${file.path} has $lines lines',
        );
      }
    });

    test('shared export re-exports feature library', () {
      expect(shared_export.QuranPlayerWidget, QuranPlayerWidget);
      expect(
        shared_export.QuranPlayerExpandedPageContent,
        QuranPlayerExpandedPageContent,
      );
    });
  });
}
