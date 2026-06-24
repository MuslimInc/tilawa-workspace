@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contract: app `lib/` must not use raw Material palette colours or inline
/// hex literals outside documented exceptions.
///
/// `Colors.transparent` is allowed (hit-test / chrome idiom, not a palette).
/// Comment bodies are stripped before matching so doc examples do not false-positive.
///
/// Allowed: entire `features/color_picker/` tree (dev tool).
void main() {
  const allowlistedPathPrefixes = <String>[
    'features/color_picker/',
  ];

  final RegExp materialPalettePattern = RegExp(
    r'Colors\.(red|green|blue|grey|gray|white|black|amber|orange|'
    r'purple|teal|cyan|brown|pink|yellow|indigo|black\d+|white\d+)',
  );

  final RegExp inlineHexPattern = RegExp(r'Color\(0x[0-9A-Fa-f]+\)');

  test('libRelativePath normalizes Windows separators', () {
    expect(_libRelativePath('lib/foo/bar.dart'), 'foo/bar.dart');
    expect(_libRelativePath(r'lib\foo\bar.dart'), 'foo/bar.dart');
  });

  test('lib avoids raw Colors.* and inline hex outside allowlist', () {
    final libRoot = Directory('lib');
    expect(
      libRoot.existsSync(),
      isTrue,
      reason:
          'Run from apps/tilawa/. Current directory: ${Directory.current.path}',
    );

    final offenders = <String>[];

    for (final entity in libRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      final relativePath = _libRelativePath(entity.path);
      if (_isAllowlisted(relativePath, allowlistedPathPrefixes)) {
        continue;
      }

      final source = _stripDartComments(entity.readAsStringSync());
      if (materialPalettePattern.hasMatch(source) ||
          inlineHexPattern.hasMatch(source)) {
        offenders.add(relativePath);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use Theme.of(context).colorScheme, theme.productColors, '
          'theme.componentTokens, or a documented palette in ui_kit '
          '(AppShareComposerColors, AppQuranReaderLegacyColors, …):\n'
          '  ${offenders.join('\n  ')}\n\n'
          'See docs/design/color_architecture.md.',
    );
  });
}

String _libRelativePath(String entityPath) {
  final normalizedPath = entityPath.replaceAll('\\', '/');
  return normalizedPath.replaceFirst(RegExp(r'^lib/'), '');
}

bool _isAllowlisted(String relativePath, List<String> prefixes) {
  for (final prefix in prefixes) {
    if (relativePath.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

String _stripDartComments(String source) {
  var withoutBlocks = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  return withoutBlocks.replaceAll(RegExp(r'//.*'), '');
}
