import 'package:flutter/material.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Warm Behance catalog chrome for reciter surah rows (parchment / brown).
abstract final class ReciterCatalogChrome {
  static bool _alignsWithCollapsedMiniPlayer(BuildContext context) =>
      QuranPlayerWidget.shellFooterShowsMiniPlayer(context);

  static Color _collapsedMiniPlayerFill(BuildContext context) =>
      Theme.of(context).componentTokens.mediaPlayerBar.shellBackgroundColor;

  static Color _collapsedMiniPlayerOutline(BuildContext context) =>
      Theme.of(context).componentTokens.mediaPlayerBar.shellOutlineColor;

  /// Control chrome (moshaf picker, download-all) aligned with the collapsed
  /// mini-player when it is visible in the shell footer.
  static Color controlIdleFill(BuildContext context, ColorScheme scheme) {
    if (_alignsWithCollapsedMiniPlayer(context)) {
      return _collapsedMiniPlayerFill(context);
    }
    return idleFill(scheme);
  }

  static Color controlBorder(
    BuildContext context,
    ColorScheme scheme,
    MeMuslimDesignTokens tokens,
  ) {
    if (_alignsWithCollapsedMiniPlayer(context)) {
      return _collapsedMiniPlayerOutline(context);
    }
    return hairline(scheme, tokens);
  }

  static Color controlDownloadingFill(
    BuildContext context,
    ColorScheme scheme,
  ) {
    if (_alignsWithCollapsedMiniPlayer(context)) {
      return _collapsedMiniPlayerFill(context);
    }
    return downloadingFill(scheme);
  }

  static Color idleFill(ColorScheme scheme) => scheme.surfaceContainerHigh;

  static Color cardFill(ColorScheme scheme) => scheme.surface;

  static Color activeFill(ColorScheme scheme) => scheme.primary;

  static Color activeOnFill(ColorScheme scheme) => scheme.onPrimary;

  static Color hairline(ColorScheme scheme, MeMuslimDesignTokens tokens) =>
      scheme.outlineVariant.withValues(alpha: tokens.opacitySubtle);

  static Color activeRowFill(ColorScheme scheme) =>
      scheme.surfaceContainer.withValues(alpha: 0.72);

  /// Opaque pill fill for the batch-download control while active.
  ///
  /// Uses [surfaceContainerHigh] — not [surfaceContainer] — because on the
  /// light theme canvas scaffold, `surfaceContainer` is the same porcelain
  /// as the page background and the chip reads as borderless text.
  static Color downloadingFill(ColorScheme scheme) =>
      scheme.surfaceContainerHigh;
}
