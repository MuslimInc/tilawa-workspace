import 'dart:math' as math;
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'shell_padding.dart';

extension TilawaSafeAreaX on BuildContext {
  // ---------------------------------------------------------------------------
  // Raw device safe area: MediaQuery.viewPadding
  // ---------------------------------------------------------------------------

  EdgeInsets get systemSafeArea => MediaQuery.viewPaddingOf(this);

  double get systemTopSafeArea => systemSafeArea.top;

  double get systemBottomSafeArea => systemSafeArea.bottom;

  double get systemLeftSafeArea => systemSafeArea.left;

  double get systemRightSafeArea => systemSafeArea.right;

  // ---------------------------------------------------------------------------
  // Current content safe padding: MediaQuery.padding
  // ---------------------------------------------------------------------------

  EdgeInsets get contentSafePadding => MediaQuery.paddingOf(this);

  double get contentTopSafePadding => contentSafePadding.top;

  double get contentBottomSafePadding => contentSafePadding.bottom;

  // ---------------------------------------------------------------------------
  // Keyboard/system obstruction: MediaQuery.viewInsets
  // ---------------------------------------------------------------------------

  EdgeInsets get systemViewInsets => MediaQuery.viewInsetsOf(this);

  double get keyboardInset => systemViewInsets.bottom;

  /// Keyboard obstruction height, including when a parent [Scaffold] strips
  /// bottom [MediaQuery.viewInsets] after resizing its body.
  double get effectiveKeyboardInset {
    if (keyboardInset > 0) {
      return keyboardInset;
    }
    final FlutterView? view = View.maybeOf(this);
    if (view == null) {
      return 0;
    }
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  bool get isKeyboardVisible => effectiveKeyboardInset > 0;

  // ---------------------------------------------------------------------------
  // Design-aware bottom spacing
  // ---------------------------------------------------------------------------

  /// For floating bottom widgets that should not be glued to the screen edge.
  ///
  /// Uses:
  /// - system bottom safe area + buffer when available
  /// - fallback spacing when Android reports 0 bottom safe area
  double get floatingBottomPadding {
    final buffer = theme.tokens.spaceSmall;
    final fallback = theme.tokens.spaceExtraLarge;

    if (systemBottomSafeArea > 0) {
      return systemBottomSafeArea + buffer;
    }

    return fallback;
  }

  /// For widgets that must stay above the keyboard.
  ///
  /// Uses:
  /// - keyboard height + buffer when keyboard is visible
  /// - floating bottom padding when keyboard is hidden
  double get keyboardAwareBottomPadding {
    if (isKeyboardVisible) {
      return effectiveKeyboardInset + theme.tokens.spaceSmall;
    }

    return floatingBottomPadding;
  }

  /// For cases where you want direct control over minimum spacing.
  double floatingBottomPaddingWithMin(double minSpacing) {
    return math.max(floatingBottomPadding, minSpacing);
  }

  /// For cases where you want direct control over keyboard buffer and fallback.
  double keyboardAwarePadding({
    double? keyboardBuffer,
    double? fallbackMinSpacing,
  }) {
    final buffer = keyboardBuffer ?? theme.tokens.spaceSmall;

    if (isKeyboardVisible) {
      return effectiveKeyboardInset + buffer;
    }

    if (fallbackMinSpacing != null) {
      return math.max(floatingBottomPadding, fallbackMinSpacing);
    }

    return floatingBottomPadding;
  }

  /// Bottom padding for scroll content hosted in [TilawaAdaptiveShell] tabs.
  ///
  /// Returns `0` when not under [TilawaShellPadding] — use app-layer helpers
  /// (e.g. mini-player footprint) on standalone routes.
  double get shellHostedScrollBottomPadding {
    final double shell = TilawaShellPadding.of(this);
    if (shell <= 0) {
      return 0;
    }
    return shell + theme.tokens.spaceLarge;
  }
}
