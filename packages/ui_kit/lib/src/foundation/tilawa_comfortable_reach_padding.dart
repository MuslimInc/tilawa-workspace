import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'safe_area_ext.dart';

/// Which comfortable-reach bottom spacing profile to apply.
enum TilawaComfortableReachKind {
  /// Sticky modal sheet footer ([TilawaBottomSheetScaffold]).
  sheet,

  /// Sticky full-screen footer ([TilawaBottomActionArea]).
  screen,

  /// Light floating chrome ([TilawaBottomActionInset] default).
  floating,
}

/// Single source of truth for thumb-zone bottom spacing.
///
/// Sheet and screen sticky footers share the same fallback: [spaceHuge] when
/// the device reports no system bottom inset, otherwise safe area +
/// [spaceExtraLarge]. [floating] delegates to [TilawaSafeAreaX.floatingBottomPadding].
abstract final class TilawaComfortableReachPadding {
  /// Resolves bottom inset for a pinned primary action.
  static double resolve(
    BuildContext context, {
    TilawaComfortableReachKind kind = TilawaComfortableReachKind.screen,
    bool keyboardAware = true,
    double keyboardBuffer = 0,
  }) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;

    if (keyboardAware && context.isKeyboardVisible) {
      final double buffer = keyboardBuffer > 0
          ? keyboardBuffer
          : tokens.spaceSmall;
      return context.keyboardInset + buffer;
    }

    return switch (kind) {
      TilawaComfortableReachKind.floating => context.floatingBottomPadding,
      TilawaComfortableReachKind.sheet || TilawaComfortableReachKind.screen =>
        context.systemBottomSafeArea > 0
            ? context.systemBottomSafeArea + tokens.spaceExtraLarge
            : tokens.spaceHuge,
    };
  }
}
