import 'package:flutter/material.dart';

import 'token_lerp.dart';

@immutable
class TilawaPlayerBackgroundTokens {
  const TilawaPlayerBackgroundTokens({
    required this.cacheWidthScale,
    required this.defaultBlurAmount,
    required this.defaultOverlayOpacity,
    required this.overlayColor,
  });

  final double cacheWidthScale;
  final double defaultBlurAmount;
  final double defaultOverlayOpacity;
  final Color overlayColor;

  factory TilawaPlayerBackgroundTokens.defaults() =>
      const TilawaPlayerBackgroundTokens(
        cacheWidthScale: 2,
        defaultBlurAmount: 0,
        defaultOverlayOpacity: 0.4,
        overlayColor: Colors.black,
      );

  TilawaPlayerBackgroundTokens copyWith({
    double? cacheWidthScale,
    double? defaultBlurAmount,
    double? defaultOverlayOpacity,
    Color? overlayColor,
  }) {
    return TilawaPlayerBackgroundTokens(
      cacheWidthScale: cacheWidthScale ?? this.cacheWidthScale,
      defaultBlurAmount: defaultBlurAmount ?? this.defaultBlurAmount,
      defaultOverlayOpacity:
          defaultOverlayOpacity ?? this.defaultOverlayOpacity,
      overlayColor: overlayColor ?? this.overlayColor,
    );
  }

  static TilawaPlayerBackgroundTokens lerp(
    TilawaPlayerBackgroundTokens a,
    TilawaPlayerBackgroundTokens b,
    double t,
  ) {
    return TilawaPlayerBackgroundTokens(
      cacheWidthScale: lerpTokenDouble(a.cacheWidthScale, b.cacheWidthScale, t),
      defaultBlurAmount: lerpTokenDouble(
        a.defaultBlurAmount,
        b.defaultBlurAmount,
        t,
      ),
      defaultOverlayOpacity: lerpTokenDouble(
        a.defaultOverlayOpacity,
        b.defaultOverlayOpacity,
        t,
      ),
      overlayColor: Color.lerp(a.overlayColor, b.overlayColor, t)!,
    );
  }
}

@immutable
class TilawaShareFooterBarTokens {
  const TilawaShareFooterBarTokens({
    required this.height,
    required this.horizontalPadding,
    required this.contentGap,
    required this.labelFontSize,
    required this.labelFontWeight,
    required this.secondaryLabelFontSize,
    required this.secondaryLabelOpacity,
  });

  final double height;
  final double horizontalPadding;
  final double contentGap;
  final double labelFontSize;
  final FontWeight labelFontWeight;
  final double secondaryLabelFontSize;
  final double secondaryLabelOpacity;

  factory TilawaShareFooterBarTokens.defaults() =>
      const TilawaShareFooterBarTokens(
        height: 56,
        horizontalPadding: 16,
        contentGap: 12,
        labelFontSize: 16,
        labelFontWeight: FontWeight.bold,
        secondaryLabelFontSize: 12,
        secondaryLabelOpacity: 0.7,
      );

  TilawaShareFooterBarTokens copyWith({
    double? height,
    double? horizontalPadding,
    double? contentGap,
    double? labelFontSize,
    FontWeight? labelFontWeight,
    double? secondaryLabelFontSize,
    double? secondaryLabelOpacity,
  }) {
    return TilawaShareFooterBarTokens(
      height: height ?? this.height,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      contentGap: contentGap ?? this.contentGap,
      labelFontSize: labelFontSize ?? this.labelFontSize,
      labelFontWeight: labelFontWeight ?? this.labelFontWeight,
      secondaryLabelFontSize:
          secondaryLabelFontSize ?? this.secondaryLabelFontSize,
      secondaryLabelOpacity:
          secondaryLabelOpacity ?? this.secondaryLabelOpacity,
    );
  }

  static TilawaShareFooterBarTokens lerp(
    TilawaShareFooterBarTokens a,
    TilawaShareFooterBarTokens b,
    double t,
  ) {
    return TilawaShareFooterBarTokens(
      height: lerpTokenDouble(a.height, b.height, t),
      horizontalPadding: lerpTokenDouble(
        a.horizontalPadding,
        b.horizontalPadding,
        t,
      ),
      contentGap: lerpTokenDouble(a.contentGap, b.contentGap, t),
      labelFontSize: lerpTokenDouble(a.labelFontSize, b.labelFontSize, t),
      labelFontWeight: t < 0.5 ? a.labelFontWeight : b.labelFontWeight,
      secondaryLabelFontSize: lerpTokenDouble(
        a.secondaryLabelFontSize,
        b.secondaryLabelFontSize,
        t,
      ),
      secondaryLabelOpacity: lerpTokenDouble(
        a.secondaryLabelOpacity,
        b.secondaryLabelOpacity,
        t,
      ),
    );
  }
}

@immutable
class TilawaSettingsGroupTokens {
  const TilawaSettingsGroupTokens({
    required this.groupHeaderPadding,
    required this.groupBorderRadius,
    required this.groupShadowOpacity,
    required this.groupShadowBlur,
    required this.groupShadowOffset,
    required this.groupTitleFontSize,
    required this.groupTitleLetterSpacing,
    required this.tileContentPadding,
    required this.switchTileContentPadding,
    required this.tileIconPadding,
    required this.tileIconBorderRadius,
    required this.tileIconSize,
    required this.tileTitleFontSize,
    required this.tileSubtitleFontSize,
    required this.tileSubtitleOpacity,
    required this.tileSubtitleSpacing,
    required this.tileTrailingSize,
    required this.tileTrailingOpacity,
    required this.tileIconContainerOpacity,
    required this.tileDividerPadding,
    required this.tileDividerHeight,
    required this.tileDividerThickness,
    required this.tileDividerOpacity,
    required this.switchActiveTrackOpacity,
    required this.tileItemGap,
  });

  final EdgeInsetsGeometry groupHeaderPadding;
  final double groupBorderRadius;
  final double groupShadowOpacity;
  final double groupShadowBlur;
  final Offset groupShadowOffset;
  final double groupTitleFontSize;
  final double groupTitleLetterSpacing;
  final EdgeInsetsGeometry tileContentPadding;
  final EdgeInsetsGeometry switchTileContentPadding;
  final EdgeInsetsGeometry tileIconPadding;
  final double tileIconBorderRadius;
  final double tileIconSize;
  final double tileTitleFontSize;
  final double tileSubtitleFontSize;
  final double tileSubtitleOpacity;
  final double tileSubtitleSpacing;
  final double tileTrailingSize;
  final double tileTrailingOpacity;
  final double tileIconContainerOpacity;
  final EdgeInsetsGeometry tileDividerPadding;
  final double tileDividerHeight;
  final double tileDividerThickness;
  final double tileDividerOpacity;
  final double switchActiveTrackOpacity;
  final double tileItemGap;

  factory TilawaSettingsGroupTokens.defaults() =>
      const TilawaSettingsGroupTokens(
        groupHeaderPadding: EdgeInsets.fromLTRB(12, 16, 16, 8),
        groupBorderRadius: 20,
        groupShadowOpacity: 0.06,
        groupShadowBlur: 10,
        groupShadowOffset: Offset(0, 4),
        groupTitleFontSize: 12.5,
        groupTitleLetterSpacing: 1.1,
        tileContentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        switchTileContentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        tileIconPadding: EdgeInsets.all(10),
        tileIconBorderRadius: 12,
        tileIconSize: 22,
        tileTitleFontSize: 15.5,
        tileSubtitleFontSize: 12.5,
        tileSubtitleOpacity: 0.5,
        tileSubtitleSpacing: 4,
        tileTrailingSize: 14,
        tileTrailingOpacity: 0.35,
        tileIconContainerOpacity: 0.1,
        tileDividerPadding: EdgeInsets.only(left: 64, right: 16),
        tileDividerHeight: 1,
        tileDividerThickness: 0.5,
        tileDividerOpacity: 0.05,
        switchActiveTrackOpacity: 0.5,
        tileItemGap: 16,
      );

  TilawaSettingsGroupTokens copyWith({
    EdgeInsetsGeometry? groupHeaderPadding,
    double? groupBorderRadius,
    double? groupShadowOpacity,
    double? groupShadowBlur,
    Offset? groupShadowOffset,
    double? groupTitleFontSize,
    double? groupTitleLetterSpacing,
    EdgeInsetsGeometry? tileContentPadding,
    EdgeInsetsGeometry? switchTileContentPadding,
    EdgeInsetsGeometry? tileIconPadding,
    double? tileIconBorderRadius,
    double? tileIconSize,
    double? tileTitleFontSize,
    double? tileSubtitleFontSize,
    double? tileSubtitleOpacity,
    double? tileSubtitleSpacing,
    double? tileTrailingSize,
    double? tileTrailingOpacity,
    double? tileIconContainerOpacity,
    EdgeInsetsGeometry? tileDividerPadding,
    double? tileDividerHeight,
    double? tileDividerThickness,
    double? tileDividerOpacity,
    double? switchActiveTrackOpacity,
    double? tileItemGap,
  }) {
    return TilawaSettingsGroupTokens(
      groupHeaderPadding: groupHeaderPadding ?? this.groupHeaderPadding,
      groupBorderRadius: groupBorderRadius ?? this.groupBorderRadius,
      groupShadowOpacity: groupShadowOpacity ?? this.groupShadowOpacity,
      groupShadowBlur: groupShadowBlur ?? this.groupShadowBlur,
      groupShadowOffset: groupShadowOffset ?? this.groupShadowOffset,
      groupTitleFontSize: groupTitleFontSize ?? this.groupTitleFontSize,
      groupTitleLetterSpacing:
          groupTitleLetterSpacing ?? this.groupTitleLetterSpacing,
      tileContentPadding: tileContentPadding ?? this.tileContentPadding,
      switchTileContentPadding:
          switchTileContentPadding ?? this.switchTileContentPadding,
      tileIconPadding: tileIconPadding ?? this.tileIconPadding,
      tileIconBorderRadius: tileIconBorderRadius ?? this.tileIconBorderRadius,
      tileIconSize: tileIconSize ?? this.tileIconSize,
      tileTitleFontSize: tileTitleFontSize ?? this.tileTitleFontSize,
      tileSubtitleFontSize: tileSubtitleFontSize ?? this.tileSubtitleFontSize,
      tileSubtitleOpacity: tileSubtitleOpacity ?? this.tileSubtitleOpacity,
      tileSubtitleSpacing: tileSubtitleSpacing ?? this.tileSubtitleSpacing,
      tileTrailingSize: tileTrailingSize ?? this.tileTrailingSize,
      tileTrailingOpacity: tileTrailingOpacity ?? this.tileTrailingOpacity,
      tileIconContainerOpacity:
          tileIconContainerOpacity ?? this.tileIconContainerOpacity,
      tileDividerPadding: tileDividerPadding ?? this.tileDividerPadding,
      tileDividerHeight: tileDividerHeight ?? this.tileDividerHeight,
      tileDividerThickness: tileDividerThickness ?? this.tileDividerThickness,
      tileDividerOpacity: tileDividerOpacity ?? this.tileDividerOpacity,
      switchActiveTrackOpacity:
          switchActiveTrackOpacity ?? this.switchActiveTrackOpacity,
      tileItemGap: tileItemGap ?? this.tileItemGap,
    );
  }

  static TilawaSettingsGroupTokens lerp(
    TilawaSettingsGroupTokens a,
    TilawaSettingsGroupTokens b,
    double t,
  ) {
    return TilawaSettingsGroupTokens(
      groupHeaderPadding: EdgeInsetsGeometry.lerp(
        a.groupHeaderPadding,
        b.groupHeaderPadding,
        t,
      )!,
      groupBorderRadius: lerpTokenDouble(
        a.groupBorderRadius,
        b.groupBorderRadius,
        t,
      ),
      groupShadowOpacity: lerpTokenDouble(
        a.groupShadowOpacity,
        b.groupShadowOpacity,
        t,
      ),
      groupShadowBlur: lerpTokenDouble(a.groupShadowBlur, b.groupShadowBlur, t),
      groupShadowOffset: Offset.lerp(
        a.groupShadowOffset,
        b.groupShadowOffset,
        t,
      )!,
      groupTitleFontSize: lerpTokenDouble(
        a.groupTitleFontSize,
        b.groupTitleFontSize,
        t,
      ),
      groupTitleLetterSpacing: lerpTokenDouble(
        a.groupTitleLetterSpacing,
        b.groupTitleLetterSpacing,
        t,
      ),
      tileContentPadding: EdgeInsetsGeometry.lerp(
        a.tileContentPadding,
        b.tileContentPadding,
        t,
      )!,
      switchTileContentPadding: EdgeInsetsGeometry.lerp(
        a.switchTileContentPadding,
        b.switchTileContentPadding,
        t,
      )!,
      tileIconPadding: EdgeInsetsGeometry.lerp(
        a.tileIconPadding,
        b.tileIconPadding,
        t,
      )!,
      tileIconBorderRadius: lerpTokenDouble(
        a.tileIconBorderRadius,
        b.tileIconBorderRadius,
        t,
      ),
      tileIconSize: lerpTokenDouble(a.tileIconSize, b.tileIconSize, t),
      tileTitleFontSize: lerpTokenDouble(
        a.tileTitleFontSize,
        b.tileTitleFontSize,
        t,
      ),
      tileSubtitleFontSize: lerpTokenDouble(
        a.tileSubtitleFontSize,
        b.tileSubtitleFontSize,
        t,
      ),
      tileSubtitleOpacity: lerpTokenDouble(
        a.tileSubtitleOpacity,
        b.tileSubtitleOpacity,
        t,
      ),
      tileSubtitleSpacing: lerpTokenDouble(
        a.tileSubtitleSpacing,
        b.tileSubtitleSpacing,
        t,
      ),
      tileTrailingSize: lerpTokenDouble(
        a.tileTrailingSize,
        b.tileTrailingSize,
        t,
      ),
      tileTrailingOpacity: lerpTokenDouble(
        a.tileTrailingOpacity,
        b.tileTrailingOpacity,
        t,
      ),
      tileIconContainerOpacity: lerpTokenDouble(
        a.tileIconContainerOpacity,
        b.tileIconContainerOpacity,
        t,
      ),
      tileDividerPadding: EdgeInsetsGeometry.lerp(
        a.tileDividerPadding,
        b.tileDividerPadding,
        t,
      )!,
      tileDividerHeight: lerpTokenDouble(
        a.tileDividerHeight,
        b.tileDividerHeight,
        t,
      ),
      tileDividerThickness: lerpTokenDouble(
        a.tileDividerThickness,
        b.tileDividerThickness,
        t,
      ),
      tileDividerOpacity: lerpTokenDouble(
        a.tileDividerOpacity,
        b.tileDividerOpacity,
        t,
      ),
      switchActiveTrackOpacity: lerpTokenDouble(
        a.switchActiveTrackOpacity,
        b.switchActiveTrackOpacity,
        t,
      ),
      tileItemGap: lerpTokenDouble(a.tileItemGap, b.tileItemGap, t),
    );
  }
}

@immutable
class TilawaImmersiveComposerTokens {
  const TilawaImmersiveComposerTokens({
    required this.backgroundBlurScale,
    required this.backgroundOverlayOpacity,
    required this.compactHeightBreakpoint,
    required this.compactPanelHeightFactor,
    required this.regularPanelHeightFactor,
    required this.compactPreviewHeightFactor,
    required this.regularPreviewHeightFactor,
    required this.panelMinHeight,
    required this.previewMaxHeight,
    required this.headerButtonSize,
    required this.headerIconSizeOffset,
  });

  final double backgroundBlurScale;
  final double backgroundOverlayOpacity;
  final double compactHeightBreakpoint;
  final double compactPanelHeightFactor;
  final double regularPanelHeightFactor;
  final double compactPreviewHeightFactor;
  final double regularPreviewHeightFactor;
  final double panelMinHeight;
  final double previewMaxHeight;
  final double headerButtonSize;
  final double headerIconSizeOffset;

  factory TilawaImmersiveComposerTokens.defaults() =>
      const TilawaImmersiveComposerTokens(
        backgroundBlurScale: 0.9,
        backgroundOverlayOpacity: 0.42,
        compactHeightBreakpoint: 760,
        compactPanelHeightFactor: 0.5,
        regularPanelHeightFactor: 0.44,
        compactPreviewHeightFactor: 0.42,
        regularPreviewHeightFactor: 0.5,
        panelMinHeight: 220,
        previewMaxHeight: 460,
        headerButtonSize: 44,
        headerIconSizeOffset: 2,
      );

  TilawaImmersiveComposerTokens copyWith({
    double? backgroundBlurScale,
    double? backgroundOverlayOpacity,
    double? compactHeightBreakpoint,
    double? compactPanelHeightFactor,
    double? regularPanelHeightFactor,
    double? compactPreviewHeightFactor,
    double? regularPreviewHeightFactor,
    double? panelMinHeight,
    double? previewMaxHeight,
    double? headerButtonSize,
    double? headerIconSizeOffset,
  }) {
    return TilawaImmersiveComposerTokens(
      backgroundBlurScale: backgroundBlurScale ?? this.backgroundBlurScale,
      backgroundOverlayOpacity:
          backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      compactHeightBreakpoint:
          compactHeightBreakpoint ?? this.compactHeightBreakpoint,
      compactPanelHeightFactor:
          compactPanelHeightFactor ?? this.compactPanelHeightFactor,
      regularPanelHeightFactor:
          regularPanelHeightFactor ?? this.regularPanelHeightFactor,
      compactPreviewHeightFactor:
          compactPreviewHeightFactor ?? this.compactPreviewHeightFactor,
      regularPreviewHeightFactor:
          regularPreviewHeightFactor ?? this.regularPreviewHeightFactor,
      panelMinHeight: panelMinHeight ?? this.panelMinHeight,
      previewMaxHeight: previewMaxHeight ?? this.previewMaxHeight,
      headerButtonSize: headerButtonSize ?? this.headerButtonSize,
      headerIconSizeOffset: headerIconSizeOffset ?? this.headerIconSizeOffset,
    );
  }

  static TilawaImmersiveComposerTokens lerp(
    TilawaImmersiveComposerTokens a,
    TilawaImmersiveComposerTokens b,
    double t,
  ) {
    return TilawaImmersiveComposerTokens(
      backgroundBlurScale: lerpTokenDouble(
        a.backgroundBlurScale,
        b.backgroundBlurScale,
        t,
      ),
      backgroundOverlayOpacity: lerpTokenDouble(
        a.backgroundOverlayOpacity,
        b.backgroundOverlayOpacity,
        t,
      ),
      compactHeightBreakpoint: lerpTokenDouble(
        a.compactHeightBreakpoint,
        b.compactHeightBreakpoint,
        t,
      ),
      compactPanelHeightFactor: lerpTokenDouble(
        a.compactPanelHeightFactor,
        b.compactPanelHeightFactor,
        t,
      ),
      regularPanelHeightFactor: lerpTokenDouble(
        a.regularPanelHeightFactor,
        b.regularPanelHeightFactor,
        t,
      ),
      compactPreviewHeightFactor: lerpTokenDouble(
        a.compactPreviewHeightFactor,
        b.compactPreviewHeightFactor,
        t,
      ),
      regularPreviewHeightFactor: lerpTokenDouble(
        a.regularPreviewHeightFactor,
        b.regularPreviewHeightFactor,
        t,
      ),
      panelMinHeight: lerpTokenDouble(a.panelMinHeight, b.panelMinHeight, t),
      previewMaxHeight: lerpTokenDouble(
        a.previewMaxHeight,
        b.previewMaxHeight,
        t,
      ),
      headerButtonSize: lerpTokenDouble(
        a.headerButtonSize,
        b.headerButtonSize,
        t,
      ),
      headerIconSizeOffset: lerpTokenDouble(
        a.headerIconSizeOffset,
        b.headerIconSizeOffset,
        t,
      ),
    );
  }
}
