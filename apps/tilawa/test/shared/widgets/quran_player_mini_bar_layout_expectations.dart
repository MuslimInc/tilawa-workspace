import 'package:flutter/material.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layout.dart';

/// Horizontal space reserved for transport controls in morph title bounds
/// (matches [QuranPlayerMorphLayout] mini title layout).
const double kQuranPlayerMorphMiniTransportReserve = 120;

/// Expected mini-player artwork rect for [TilawaMediaPlayerBar] content row.
///
/// Mirrors bar padding + artwork size; used to regression-test morph anchors
/// during collapse/expand drag.
Rect quranPlayerExpectedMiniArtRect({
  required Rect miniBarRect,
  required QuranPlayerMorphThemeGeometry geometry,
  required TextDirection textDirection,
}) {
  final EdgeInsets pad = geometry.barContentPadding.resolve(textDirection);
  final double top = miniBarRect.top + geometry.progressHeight + pad.top;
  final double size = geometry.barArtworkSize;
  switch (textDirection) {
    case TextDirection.ltr:
      final double left =
          miniBarRect.left + geometry.shellHorizontalInset + pad.left;
      return Rect.fromLTWH(left, top, size, size);
    case TextDirection.rtl:
      final double right =
          miniBarRect.right - geometry.shellHorizontalInset - pad.right;
      return Rect.fromLTWH(right - size, top, size, size);
  }
}

/// Expected mini title bounds beside artwork (transport reserved on opposite
/// edge).
Rect quranPlayerExpectedMiniTitleRect({
  required Rect miniBarRect,
  required Rect miniArt,
  required QuranPlayerMorphThemeGeometry geometry,
  required TextDirection textDirection,
}) {
  final double top = miniArt.top;
  final double height = miniArt.height;
  switch (textDirection) {
    case TextDirection.ltr:
      final double left = miniArt.right + geometry.barArtworkInfoGap;
      final double right =
          miniBarRect.right -
          geometry.shellHorizontalInset -
          kQuranPlayerMorphMiniTransportReserve;
      return Rect.fromLTRB(left, top, right, top + height);
    case TextDirection.rtl:
      final double right = miniArt.left - geometry.barArtworkInfoGap;
      final double left =
          miniBarRect.left +
          geometry.shellHorizontalInset +
          kQuranPlayerMorphMiniTransportReserve;
      return Rect.fromLTRB(left, top, right, top + height);
  }
}

/// True when morph metadata is in the mini-bar row (beside art), not below it.
bool quranPlayerMorphMetadataIsBesideArt({
  required Rect artRect,
  required Rect titleRect,
  required TextDirection textDirection,
}) {
  switch (textDirection) {
    case TextDirection.ltr:
      return titleRect.left >= artRect.right - 1;
    case TextDirection.rtl:
      return titleRect.right <= artRect.left + 1;
  }
}

/// True when title band shares the artwork row (not stacked vertically).
bool quranPlayerMorphMetadataSharesArtRow({
  required Rect artRect,
  required Rect titleRect,
}) {
  return (titleRect.top - artRect.top).abs() < 6 &&
      titleRect.bottom <= artRect.bottom + 6;
}
