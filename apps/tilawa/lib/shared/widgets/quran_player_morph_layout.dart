import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Geometry inputs for [QuranPlayerMorphLayout.compute] (theme-derived).
@immutable
class QuranPlayerMorphThemeGeometry {
  const QuranPlayerMorphThemeGeometry({
    required this.spaceLarge,
    required this.progressHeight,
    required this.shellHorizontalInset,
    required this.barContentPadding,
    required this.barArtworkSize,
    required this.barArtworkRadius,
    required this.barArtworkInfoGap,
    required this.expandedArtBorderRadius,
  });

  final double spaceLarge;
  final double progressHeight;
  final double shellHorizontalInset;
  final EdgeInsetsGeometry barContentPadding;
  final double barArtworkSize;
  final double barArtworkRadius;
  final double barArtworkInfoGap;
  final double expandedArtBorderRadius;

  factory QuranPlayerMorphThemeGeometry.fromBarTokens({
    required double spaceLarge,
    required double progressHeight,
    required EdgeInsetsGeometry barContentPadding,
    required TilawaMediaPlayerBarTokens barTokens,
    required double expandedArtBorderRadius,
  }) {
    return QuranPlayerMorphThemeGeometry(
      spaceLarge: spaceLarge,
      progressHeight: progressHeight,
      shellHorizontalInset: spaceLarge,
      barContentPadding: barContentPadding,
      barArtworkSize: barTokens.artworkSize,
      barArtworkRadius: barTokens.artworkRadius,
      barArtworkInfoGap: barTokens.artworkInfoGap,
      expandedArtBorderRadius: expandedArtBorderRadius,
    );
  }
}

/// Interpolated layout for the shared artwork + title during expand/collapse.
@immutable
class QuranPlayerMorphLayout {
  const QuranPlayerMorphLayout({
    required this.artRect,
    required this.artBorderRadius,
    required this.titleRect,
    required this.titleScale,
    required this.titleAlign,
    required this.titleMaxLines,
  });

  final Rect artRect;
  final double artBorderRadius;
  final Rect titleRect;
  final double titleScale;
  final TextAlign titleAlign;
  final int titleMaxLines;

  /// Computes morph geometry in overlay coordinates.
  ///
  /// [miniBarRect] is the mini player shell in the overlay. [sheetOffsetY] is
  /// the expanded sheet translate (same as [_ExpandedPlayerMotion]).
  static QuranPlayerMorphLayout compute({
    required double progress,
    required Size viewport,
    required Rect miniBarRect,
    required double sheetOffsetY,
    required QuranPlayerMorphThemeGeometry geometry,
    double expandedArtWidthFactor = 0.62,
    double expandedArtCenterYFactor = 0.38,
  }) {
    final double t = progress.clamp(0.0, 1.0);
    final double layoutT = Curves.easeInOut.transform(t);

    final Rect miniArt = _miniArtRect(
      miniBarRect: miniBarRect,
      geometry: geometry,
    );
    final Rect expandedArt = _expandedArtRect(
      viewport: viewport,
      sheetOffsetY: sheetOffsetY,
      geometry: geometry,
      widthFactor: expandedArtWidthFactor,
      centerYFactor: expandedArtCenterYFactor,
    );
    final Rect artRect = Rect.lerp(miniArt, expandedArt, layoutT)!;

    final _TitleLayout miniTitle = _miniTitleLayout(
      miniBarRect: miniBarRect,
      miniArt: miniArt,
      geometry: geometry,
    );
    final _TitleLayout expandedTitle = _expandedTitleLayout(
      viewport: viewport,
      expandedArt: expandedArt,
      geometry: geometry,
    );

    final Rect titleRect = Rect.lerp(
      miniTitle.bounds,
      expandedTitle.bounds,
      layoutT,
    )!;
    final double titleScale = lerpDouble(
      miniTitle.scale,
      expandedTitle.scale,
      layoutT,
    )!;
    final TextAlign titleAlign = layoutT < 0.5
        ? TextAlign.start
        : TextAlign.center;
    final int titleMaxLines = layoutT < 0.55 ? 1 : 2;

    return QuranPlayerMorphLayout(
      artRect: artRect,
      artBorderRadius: lerpDouble(
        geometry.barArtworkRadius,
        geometry.expandedArtBorderRadius,
        layoutT,
      )!,
      titleRect: titleRect,
      titleScale: titleScale,
      titleAlign: titleAlign,
      titleMaxLines: titleMaxLines,
    );
  }

  static Rect _miniArtRect({
    required Rect miniBarRect,
    required QuranPlayerMorphThemeGeometry geometry,
  }) {
    final EdgeInsets pad = geometry.barContentPadding.resolve(
      TextDirection.ltr,
    );
    final double left =
        miniBarRect.left +
        geometry.shellHorizontalInset +
        pad.left;
    final double top =
        miniBarRect.top +
        geometry.progressHeight +
        pad.top;
    final double size = geometry.barArtworkSize;
    return Rect.fromLTWH(left, top, size, size);
  }

  static Rect _expandedArtRect({
    required Size viewport,
    required double sheetOffsetY,
    required QuranPlayerMorphThemeGeometry geometry,
    required double widthFactor,
    required double centerYFactor,
  }) {
    final double width = (viewport.width - geometry.spaceLarge * 2) *
        widthFactor.clamp(0.45, 0.85);
    final double height = width * 9 / 16;
    final double centerX = viewport.width / 2;
    final double centerY =
        viewport.height * centerYFactor + sheetOffsetY;
    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: width,
      height: height,
    );
  }

  static _TitleLayout _miniTitleLayout({
    required Rect miniBarRect,
    required Rect miniArt,
    required QuranPlayerMorphThemeGeometry geometry,
  }) {
    final double left = miniArt.right + geometry.barArtworkInfoGap;
    final double right =
        miniBarRect.right - geometry.shellHorizontalInset - 120;
    final double top = miniArt.top;
    final double height = miniArt.height;
    return _TitleLayout(
      bounds: Rect.fromLTRB(left, top, right, top + height),
      scale: 1.0,
    );
  }

  static _TitleLayout _expandedTitleLayout({
    required Size viewport,
    required Rect expandedArt,
    required QuranPlayerMorphThemeGeometry geometry,
  }) {
    final double width = viewport.width - geometry.spaceLarge * 2;
    final double top = expandedArt.bottom + geometry.spaceLarge;
    final double height = 56;
    return _TitleLayout(
      bounds: Rect.fromCenter(
        center: Offset(
          viewport.width / 2,
          top + height / 2,
        ),
        width: width,
        height: height,
      ),
      scale: 1.08,
    );
  }
}

@immutable
class _TitleLayout {
  const _TitleLayout({required this.bounds, required this.scale});

  final Rect bounds;
  final double scale;
}
