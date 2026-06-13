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
    required this.titleScaleAlignment,
    required this.horizontalIdentity,
    required this.textDirection,
    required this.showMorphSubtitle,
  });

  /// Layout progress after easing (0 collapsed → 1 expanded).
  static const double horizontalIdentityEndT = 0.48;

  final Rect artRect;
  final double artBorderRadius;
  final Rect titleRect;
  final double titleScale;
  final TextAlign titleAlign;
  final int titleMaxLines;

  /// Scale origin for morph metadata during mini-anchored phase.
  final Alignment titleScaleAlignment;

  /// Mini-bar style row (art beside metadata), not art stacked above text.
  final bool horizontalIdentity;

  final TextDirection textDirection;

  /// Subtitle shown in morph metadata (horizontal band matches mini bar).
  final bool showMorphSubtitle;

  /// Union of [artRect] and [titleRect] for the horizontal identity band.
  Rect get identityBandRect {
    return Rect.fromLTRB(
      artRect.left < titleRect.left ? artRect.left : titleRect.left,
      artRect.top,
      artRect.right > titleRect.right ? artRect.right : titleRect.right,
      artRect.bottom > titleRect.bottom ? artRect.bottom : titleRect.bottom,
    );
  }

  /// True when metadata sits under artwork (expanded-style stack).
  bool get metadataIsVerticallyStacked => titleRect.top >= artRect.bottom - 4;

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
    TextDirection textDirection = TextDirection.ltr,
    double expandedArtWidthFactor = 0.62,
    double expandedArtCenterYFactor = 0.38,
  }) {
    final double t = progress.clamp(0.0, 1.0);
    final double layoutT = Curves.easeInOut.transform(t);

    final Rect miniArt = _miniArtRect(
      miniBarRect: miniBarRect,
      geometry: geometry,
      textDirection: textDirection,
    );
    final Rect expandedArt = _expandedArtRect(
      viewport: viewport,
      sheetOffsetY: sheetOffsetY,
      geometry: geometry,
      widthFactor: expandedArtWidthFactor,
      centerYFactor: expandedArtCenterYFactor,
    );
    final Rect artRect = Rect.lerp(miniArt, expandedArt, layoutT)!;

    final _TitleLayout expandedTitle = _expandedTitleLayout(
      viewport: viewport,
      expandedArt: expandedArt,
      geometry: geometry,
    );

    final bool horizontalIdentity = layoutT < horizontalIdentityEndT;
    final Rect titleRect = horizontalIdentity
        ? _titleRectBesideArt(
            artRect: artRect,
            miniBarRect: miniBarRect,
            geometry: geometry,
            textDirection: textDirection,
          )
        : Rect.lerp(
            _titleRectBesideArt(
              artRect: Rect.lerp(
                miniArt,
                expandedArt,
                horizontalIdentityEndT,
              )!,
              miniBarRect: miniBarRect,
              geometry: geometry,
              textDirection: textDirection,
            ),
            expandedTitle.bounds,
            ((layoutT - horizontalIdentityEndT) / (1 - horizontalIdentityEndT))
                .clamp(0.0, 1.0),
          )!;
    final double titleScale = horizontalIdentity
        ? 1.0
        : lerpDouble(
            1.0,
            expandedTitle.scale,
            ((layoutT - horizontalIdentityEndT) / (1 - horizontalIdentityEndT))
                .clamp(0.0, 1.0),
          )!;
    final TextAlign titleAlign = horizontalIdentity
        ? TextAlign.start
        : TextAlign.center;
    final int titleMaxLines = horizontalIdentity ? 1 : 2;
    final Alignment titleScaleAlignment = horizontalIdentity
        ? switch (textDirection) {
            TextDirection.rtl => Alignment.topRight,
            TextDirection.ltr => Alignment.topLeft,
          }
        : Alignment.topCenter;
    final bool showMorphSubtitle = true;

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
      titleScaleAlignment: titleScaleAlignment,
      horizontalIdentity: horizontalIdentity,
      textDirection: textDirection,
      showMorphSubtitle: showMorphSubtitle,
    );
  }

  static Rect _miniArtRect({
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

  static Rect _expandedArtRect({
    required Size viewport,
    required double sheetOffsetY,
    required QuranPlayerMorphThemeGeometry geometry,
    required double widthFactor,
    required double centerYFactor,
  }) {
    final double width =
        (viewport.width - geometry.spaceLarge * 2) *
        widthFactor.clamp(0.45, 0.85);
    final double height = width * 9 / 16;
    final double centerX = viewport.width / 2;
    final double centerY = viewport.height * centerYFactor + sheetOffsetY;
    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: width,
      height: height,
    );
  }

  /// Metadata slot beside [artRect] (matches [TilawaMediaPlayerBar] row).
  static Rect _titleRectBesideArt({
    required Rect artRect,
    required Rect miniBarRect,
    required QuranPlayerMorphThemeGeometry geometry,
    required TextDirection textDirection,
  }) {
    const double transportReserve = 120;
    final double top = artRect.top;
    final double height = artRect.height;
    switch (textDirection) {
      case TextDirection.ltr:
        final double left = artRect.right + geometry.barArtworkInfoGap;
        final double right =
            miniBarRect.right -
            geometry.shellHorizontalInset -
            transportReserve;
        return Rect.fromLTRB(left, top, right, top + height);
      case TextDirection.rtl:
        final double right = artRect.left - geometry.barArtworkInfoGap;
        final double left =
            miniBarRect.left + geometry.shellHorizontalInset + transportReserve;
        return Rect.fromLTRB(left, top, right, top + height);
    }
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
