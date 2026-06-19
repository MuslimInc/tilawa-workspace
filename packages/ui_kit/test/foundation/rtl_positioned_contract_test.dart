@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contract test: components in `packages/ui_kit/lib/src/` must not pin content
/// to a single *physical* horizontal edge with `Positioned(left:` / `right:`.
///
/// Arabic is a first-class language for Tilawa, so absolute `left`/`right`
/// placement does not mirror in RTL — a button pinned `right:` stays on the
/// right in Arabic when it should move to the leading edge. Use
/// [PositionedDirectional] (`start:` / `end:`) instead, which resolves against
/// the ambient [TextDirection].
///
/// **Symmetric pairs are fine.** `Positioned(left: 0, right: 0, …)` (and any
/// block that sets *both* `left:` and `right:`) is full-width and mirror-
/// invariant, so it is allowed. Only *single-sided* horizontal placement is
/// flagged.
///
/// **Allow-list** is for placements that are genuinely mirror-invariant but
/// can't be proven so by the both-sides heuristic — e.g. an overlay centered
/// via `left: (screenWidth - size) / 2`. Add a file with a code-comment
/// justification at the call site.
void main() {
  const allowlist = <String>{
    // Scrub-letter overlay is horizontally *centered*
    // (`left = (screenWidth - overlaySize) / 2`), so it is mirror-invariant
    // despite using `left:`. See the OverlayPortal builder.
    'molecules/tilawa_alphabet_scrollbar.dart',
    // Long-press radial/vertical nav overlays position children by computed
    // center coordinates (`circleCenter.dx`, `stackPivot.dx`, `thumbPivot.dx`
    // +/- half-size). The dx values are already derived from RTL-aware layout,
    // so the resulting placement is horizontally centered and mirror-invariant.
    'organisms/tilawa_adaptive_shell.dart',
  };

  test('Positioned uses directional placement for horizontal edges', () {
    final libSrc = Directory('lib/src');
    expect(
      libSrc.existsSync(),
      isTrue,
      reason:
          'Test must run with `flutter test` from the package root '
          '(packages/ui_kit/). Current working directory: '
          '${Directory.current.path}',
    );

    final offenders = <String>[];
    for (final entity in libSrc.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (!source.contains('Positioned(')) continue;

      final relPath = entity.path.replaceFirst(RegExp(r'^lib/src/+'), '');
      if (allowlist.contains(relPath)) continue;

      for (final block in _positionedBlocks(source)) {
        final bool hasLeft = _hasArg(block, 'left');
        final bool hasRight = _hasArg(block, 'right');
        // Single-sided horizontal placement is the RTL hazard. Both-sided
        // (full-width) and purely vertical placement are safe.
        if (hasLeft != hasRight) {
          offenders.add(relPath);
          break;
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These files pin content to a single physical horizontal edge with '
          '`Positioned(left:` or `right:`, which does not mirror in RTL '
          '(Arabic):\n  ${offenders.join('\n  ')}\n\n'
          'Use `PositionedDirectional(start:` / `end:` instead. If the '
          'placement is genuinely mirror-invariant (e.g. horizontally '
          'centered), add the file to the allow-list in this test with a '
          'code-comment justification at the call site.',
    );
  });
}

/// Returns the argument text of each `Positioned(` invocation, balanced on
/// parentheses so nested calls (e.g. `child: Foo(...)`) are included rather
/// than truncated.
Iterable<String> _positionedBlocks(String source) sync* {
  const marker = 'Positioned(';
  var index = source.indexOf(marker);
  while (index != -1) {
    final start = index + marker.length;
    var depth = 1;
    var i = start;
    while (i < source.length && depth > 0) {
      final ch = source[i];
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        depth--;
      }
      i++;
    }
    yield source.substring(start, i - 1);
    index = source.indexOf(marker, i);
  }
}

/// Whether [block] passes a top-level `name:` argument. Matches at line start
/// or after a comma/brace so substrings like `overlayLeft:` don't false-match
/// `left:`. Good enough for a lint-style contract test.
bool _hasArg(String block, String name) {
  return RegExp('(^|[,{(\\s])$name\\s*:').hasMatch(block);
}
