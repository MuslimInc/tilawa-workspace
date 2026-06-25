@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';

/// Contract test: every `GestureDetector` in `packages/ui_kit/lib/src/` must
/// either (a) sit in one of the allow-listed files below and use a bare
/// detector intentionally for a non-visible region (pan handlers,
/// pan-to-dismiss layers), or (b) declare `behavior: HitTestBehavior.opaque`
/// so taps on transparent padding still register.
///
/// See [kMeMuslimMinInteractiveDimension] for the companion-rule prose. If you
/// add a new `GestureDetector` site, prefer a Material primitive
/// (`InkWell`, `IconButton`, `ListTile`); if a bare detector is genuinely
/// necessary, add the file to [_allowlist] **and explain why in a code
/// comment at the call site**.
void main() {
  const allowlist = <String>{
    'atoms/tilawa_sheet_handle.dart',
    'molecules/tilawa_alphabet_scrollbar.dart',
    'organisms/tilawa_media_player_bar.dart',
    'organisms/immersive_composer_scaffold.dart',
    // Horizontal drag on the bottom-nav pill ends a long-press session when the
    // finger leaves the thumb rail; `behavior: HitTestBehavior.opaque` keeps
    // transparent padding inside the pill tappable.
    'organisms/tilawa_adaptive_shell.dart',
    // The shared interaction primitive — its GestureDetector declares
    // `behavior: HitTestBehavior.opaque` and is the canonical place the rest of
    // the kit routes taps through (focus ring, press, haptics, state layers).
    'foundation/tilawa_interactive_surface.dart',
  };

  test('GestureDetector call sites stay on the documented allow-list', () {
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
      if (!source.contains('GestureDetector(')) continue;

      final relPath = entity.path.replaceFirst(
        RegExp(r'^lib/src/+'),
        '',
      );
      if (allowlist.contains(relPath)) continue;

      offenders.add(relPath);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These files use `GestureDetector(` but are not on the allow-list:\n'
          '  ${offenders.join('\n  ')}\n\n'
          'Prefer a Material primitive (InkWell, IconButton, ListTile) which '
          'already provides hit-slop and ripple. If a bare detector is '
          'unavoidable, either (a) declare `behavior: HitTestBehavior.opaque` '
          'and add the file to the allow-list in this test with a code-comment '
          'justification, or (b) keep it strictly for non-visible gesture '
          'regions (pan-to-dismiss, edge-of-screen pan handlers). See '
          '`kMeMuslimMinInteractiveDimension` dartdoc and '
          '`specs/014-ergonomic-mobile-ux/spec.md` FR-006.',
    );
  });

  test(
    'minInteractiveDimension is centralized on kMeMuslimMinInteractiveDimension',
    () {
      expect(
        MeMuslimDesignTokens.light().minInteractiveDimension,
        kMeMuslimMinInteractiveDimension,
      );
      expect(
        MeMuslimDesignTokens.dark().minInteractiveDimension,
        kMeMuslimMinInteractiveDimension,
      );
    },
  );
}
