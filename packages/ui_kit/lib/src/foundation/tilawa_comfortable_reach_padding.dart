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
  /// Bottom inset when the keyboard is hidden (comfortable thumb reach).
  static double resolveClosed(
    BuildContext context, {
    TilawaComfortableReachKind kind = TilawaComfortableReachKind.screen,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return switch (kind) {
      TilawaComfortableReachKind.floating => context.floatingBottomPadding,
      TilawaComfortableReachKind.sheet || TilawaComfortableReachKind.screen =>
        context.systemBottomSafeArea > 0
            ? context.systemBottomSafeArea + tokens.spaceExtraLarge
            : tokens.spaceHuge,
    };
  }

  /// Bottom inset when the keyboard is open and the parent already resized.
  static double resolveKeyboardOpen(
    BuildContext context, {
    double keyboardBuffer = 0,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    return keyboardBuffer > 0 ? keyboardBuffer : tokens.spaceSmall;
  }

  /// Interpolates between [resolveKeyboardOpen] and [resolveClosed] while the
  /// keyboard animates. [maxKeyboardInset] should track the peak inset for the
  /// current open/close cycle (see [TilawaBottomActionArea]).
  static double resolveTransitioning(
    BuildContext context, {
    TilawaComfortableReachKind kind = TilawaComfortableReachKind.screen,
    required double maxKeyboardInset,
    double keyboardBuffer = 0,
  }) {
    final double inset = context.effectiveKeyboardInset;
    if (inset <= 0) {
      return resolveClosed(context, kind: kind);
    }

    final double open = resolveKeyboardOpen(
      context,
      keyboardBuffer: keyboardBuffer,
    );
    if (maxKeyboardInset <= 0) {
      return open;
    }

    final double progress = (inset / maxKeyboardInset).clamp(0.0, 1.0);
    final double closed = resolveClosed(context, kind: kind);
    return open + (closed - open) * (1.0 - progress);
  }

  /// Resolves bottom inset for a pinned primary action.
  static double resolve(
    BuildContext context, {
    TilawaComfortableReachKind kind = TilawaComfortableReachKind.screen,
    bool keyboardAware = true,
    double keyboardBuffer = 0,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    if (context.isKeyboardVisible) {
      if (keyboardAware) {
        final double buffer = keyboardBuffer > 0
            ? keyboardBuffer
            : tokens.spaceSmall;
        return context.effectiveKeyboardInset + buffer;
      }

      // Parent already resized (e.g. [Scaffold.resizeToAvoidBottomInset]).
      return resolveKeyboardOpen(context, keyboardBuffer: keyboardBuffer);
    }

    return resolveClosed(context, kind: kind);
  }
}
