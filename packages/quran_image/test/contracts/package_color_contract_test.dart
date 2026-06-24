@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bans raw Material palette colours and inline hex in `quran_image` lib/.
void main() {
  final RegExp materialPalettePattern = RegExp(
    r'Colors\.(red|green|blue|grey|gray|white|black|amber|orange|'
    r'purple|teal|cyan|brown|pink|yellow|indigo|black\d+|white\d+)',
  );

  final RegExp inlineHexPattern = RegExp(r'Color\(0x[0-9A-Fa-f]+\)');

  test('lib avoids raw Colors.* and inline hex', () {
    final libRoot = Directory('lib');
    expect(libRoot.existsSync(), isTrue);

    final offenders = <String>[];

    for (final entity in libRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final relativePath = entity.path.replaceFirst(RegExp(r'^lib/'), '');
      final source = entity
          .readAsStringSync()
          .replaceAll(
            RegExp(r'/\*[\s\S]*?\*/'),
            '',
          )
          .replaceAll(RegExp(r'//.*'), '');

      if (materialPalettePattern.hasMatch(source) ||
          inlineHexPattern.hasMatch(source)) {
        offenders.add(relativePath);
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
