import 'package:flutter/material.dart';

import '../density.dart';
import 'token_lerp.dart';

@immutable
class TilawaSectionTitleTokens {
  const TilawaSectionTitleTokens({required this.fontWeight});

  final FontWeight fontWeight;

  factory TilawaSectionTitleTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    // No-op: TilawaSectionTitle has only a fontWeight; nothing dimensional
    // to compact. Density param kept for API uniformity.
    return const TilawaSectionTitleTokens(fontWeight: .w800);
  }

  TilawaSectionTitleTokens copyWith({FontWeight? fontWeight}) {
    return TilawaSectionTitleTokens(fontWeight: fontWeight ?? this.fontWeight);
  }

  static TilawaSectionTitleTokens lerp(
    TilawaSectionTitleTokens a,
    TilawaSectionTitleTokens b,
    double t,
  ) {
    return TilawaSectionTitleTokens(
      fontWeight: FontWeight.lerp(a.fontWeight, b.fontWeight, t)!,
    );
  }
}

@immutable
class TilawaSheetHandleTokens {
  const TilawaSheetHandleTokens({
    required this.width,
    required this.height,
    required this.marginBottom,
    required this.cornerRadius,
    required this.colorOpacity,
  });

  final double width;
  final double height;
  final double marginBottom;
  final double cornerRadius;
  final double colorOpacity;

  factory TilawaSheetHandleTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    if (density.isCompact) {
      return const TilawaSheetHandleTokens(
        width: 46,
        height: 5,
        marginBottom: 12,
        cornerRadius: 999,
        colorOpacity: 0.22,
      );
    }
    return const TilawaSheetHandleTokens(
      width: 46,
      height: 5,
      marginBottom: 16,
      cornerRadius: 999,
      colorOpacity: 0.22,
    );
  }

  TilawaSheetHandleTokens copyWith({
    double? width,
    double? height,
    double? marginBottom,
    double? cornerRadius,
    double? colorOpacity,
  }) {
    return TilawaSheetHandleTokens(
      width: width ?? this.width,
      height: height ?? this.height,
      marginBottom: marginBottom ?? this.marginBottom,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      colorOpacity: colorOpacity ?? this.colorOpacity,
    );
  }

  static TilawaSheetHandleTokens lerp(
    TilawaSheetHandleTokens a,
    TilawaSheetHandleTokens b,
    double t,
  ) {
    return TilawaSheetHandleTokens(
      width: lerpTokenDouble(a.width, b.width, t),
      height: lerpTokenDouble(a.height, b.height, t),
      marginBottom: lerpTokenDouble(a.marginBottom, b.marginBottom, t),
      cornerRadius: lerpTokenDouble(a.cornerRadius, b.cornerRadius, t),
      colorOpacity: lerpTokenDouble(a.colorOpacity, b.colorOpacity, t),
    );
  }
}

/// Component tokens for [TilawaCard].
///
/// Defaults match the existing behavior where the card reads
/// `radiusLarge`, `borderWidthThin`, and `spaceMedium` from
/// [TilawaDesignTokens].
@immutable
class TilawaCardTokens {
  const TilawaCardTokens({
    required this.borderRadius,
    required this.borderWidth,
    required this.padding,
  });

  /// Corner radius of the card.
  final double borderRadius;

  /// Border width of the card outline.
  final double borderWidth;

  /// Default inner padding.
  final EdgeInsets padding;

  factory TilawaCardTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    if (density.isCompact) {
      return const TilawaCardTokens(
        borderRadius: 14.0,
        borderWidth: 0.5,
        padding: EdgeInsets.all(8.0),
      );
    }
    return const TilawaCardTokens(
      borderRadius: 16.0,
      borderWidth: 0.5,
      padding: EdgeInsets.all(12.0),
    );
  }

  TilawaCardTokens copyWith({
    double? borderRadius,
    double? borderWidth,
    EdgeInsets? padding,
  }) {
    return TilawaCardTokens(
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      padding: padding ?? this.padding,
    );
  }

  static TilawaCardTokens lerp(
    TilawaCardTokens a,
    TilawaCardTokens b,
    double t,
  ) {
    return TilawaCardTokens(
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      borderWidth: lerpTokenDouble(a.borderWidth, b.borderWidth, t),
      padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
    );
  }
}

/// Component tokens for [TilawaIconBox].
///
/// Defaults match the existing behavior where the icon box reads
/// `iconSizeLarge`, `spaceSmall`, and `radiusMedium` from
/// [TilawaDesignTokens].
@immutable
class TilawaIconBoxTokens {
  const TilawaIconBoxTokens({
    required this.iconSize,
    required this.padding,
    required this.borderRadius,
  });

  /// Default icon size inside the box.
  final double iconSize;

  /// Inner padding around the icon.
  final double padding;

  /// Corner radius of the container.
  final double borderRadius;

  factory TilawaIconBoxTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    if (density.isCompact) {
      return const TilawaIconBoxTokens(
        iconSize: 20.0,
        padding: 6.0,
        borderRadius: 10.0,
      );
    }
    return const TilawaIconBoxTokens(
      iconSize: 24.0,
      padding: 8.0,
      borderRadius: 12.0,
    );
  }

  TilawaIconBoxTokens copyWith({
    double? iconSize,
    double? padding,
    double? borderRadius,
  }) {
    return TilawaIconBoxTokens(
      iconSize: iconSize ?? this.iconSize,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  static TilawaIconBoxTokens lerp(
    TilawaIconBoxTokens a,
    TilawaIconBoxTokens b,
    double t,
  ) {
    return TilawaIconBoxTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      padding: lerpTokenDouble(a.padding, b.padding, t),
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
    );
  }
}

/// Component tokens for [TilawaLoadingIndicator].
@immutable
class TilawaLoadingIndicatorTokens {
  const TilawaLoadingIndicatorTokens({
    required this.defaultStrokeWidth,
    required this.compactStrokeWidth,
  });

  /// Default stroke width for the circular progress indicator.
  final double defaultStrokeWidth;

  /// Compact stroke width used in smaller contexts.
  final double compactStrokeWidth;

  factory TilawaLoadingIndicatorTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    // No-op: stroke widths are already small/display-only. Density param kept
    // for API uniformity.
    return const TilawaLoadingIndicatorTokens(
      defaultStrokeWidth: 4.0,
      compactStrokeWidth: 2.0,
    );
  }

  TilawaLoadingIndicatorTokens copyWith({
    double? defaultStrokeWidth,
    double? compactStrokeWidth,
  }) {
    return TilawaLoadingIndicatorTokens(
      defaultStrokeWidth: defaultStrokeWidth ?? this.defaultStrokeWidth,
      compactStrokeWidth: compactStrokeWidth ?? this.compactStrokeWidth,
    );
  }

  static TilawaLoadingIndicatorTokens lerp(
    TilawaLoadingIndicatorTokens a,
    TilawaLoadingIndicatorTokens b,
    double t,
  ) {
    return TilawaLoadingIndicatorTokens(
      defaultStrokeWidth: lerpTokenDouble(
        a.defaultStrokeWidth,
        b.defaultStrokeWidth,
        t,
      ),
      compactStrokeWidth: lerpTokenDouble(
        a.compactStrokeWidth,
        b.compactStrokeWidth,
        t,
      ),
    );
  }
}

/// Component tokens for [TilawaIconToggle].
@immutable
class TilawaIconToggleTokens {
  const TilawaIconToggleTokens({
    required this.iconSize,
    required this.padding,
    required this.borderRadius,
  });

  final double iconSize;
  final double padding;
  final double borderRadius;

  factory TilawaIconToggleTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    // No-op: total tap area today is 36dp (iconSize 20 + padding 8*2),
    // already below the 48dp guideline. Do not shrink further; flagged for
    // a separate accessibility refactor outside this work.
    return const TilawaIconToggleTokens(
      iconSize: 20.0,
      padding: 8.0,
      borderRadius: 12.0,
    );
  }

  TilawaIconToggleTokens copyWith({
    double? iconSize,
    double? padding,
    double? borderRadius,
  }) {
    return TilawaIconToggleTokens(
      iconSize: iconSize ?? this.iconSize,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  static TilawaIconToggleTokens lerp(
    TilawaIconToggleTokens a,
    TilawaIconToggleTokens b,
    double t,
  ) {
    return TilawaIconToggleTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      padding: lerpTokenDouble(a.padding, b.padding, t),
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
    );
  }
}

/// Component tokens for [TilawaDivider].
@immutable
class TilawaDividerTokens {
  const TilawaDividerTokens({
    required this.height,
    required this.thickness,
    required this.colorOpacity,
  });

  /// Default divider height (includes spacing above and below).
  final double height;

  /// Line thickness.
  final double thickness;

  /// Opacity applied to the default divider color.
  final double colorOpacity;

  factory TilawaDividerTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    // No-op: divider is a 1px line; nothing to compact. Density param kept
    // for API uniformity.
    return const TilawaDividerTokens(
      height: 1.0,
      thickness: 0.5,
      colorOpacity: 1.0,
    );
  }

  TilawaDividerTokens copyWith({
    double? height,
    double? thickness,
    double? colorOpacity,
  }) {
    return TilawaDividerTokens(
      height: height ?? this.height,
      thickness: thickness ?? this.thickness,
      colorOpacity: colorOpacity ?? this.colorOpacity,
    );
  }

  static TilawaDividerTokens lerp(
    TilawaDividerTokens a,
    TilawaDividerTokens b,
    double t,
  ) {
    return TilawaDividerTokens(
      height: lerpTokenDouble(a.height, b.height, t),
      thickness: lerpTokenDouble(a.thickness, b.thickness, t),
      colorOpacity: lerpTokenDouble(a.colorOpacity, b.colorOpacity, t),
    );
  }
}

/// Component tokens for [TilawaEmptyState].
@immutable
class TilawaEmptyStateTokens {
  const TilawaEmptyStateTokens({
    required this.iconSize,
    required this.iconOpacity,
    required this.titleSpacing,
    required this.subtitleSpacing,
    required this.actionSpacing,
    required this.padding,
  });

  /// Size of the empty-state icon.
  final double iconSize;

  /// Opacity applied to the icon color.
  final double iconOpacity;

  /// Spacing between the icon and the title.
  final double titleSpacing;

  /// Spacing between the title and the subtitle.
  final double subtitleSpacing;

  /// Spacing between the subtitle and the action widget.
  final double actionSpacing;

  /// Outer padding around the whole empty-state layout.
  final EdgeInsets padding;

  factory TilawaEmptyStateTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    if (density.isCompact) {
      return const TilawaEmptyStateTokens(
        iconSize: 40.0,
        iconOpacity: 0.4,
        titleSpacing: 12.0,
        subtitleSpacing: 4.0,
        actionSpacing: 16.0,
        padding: EdgeInsets.all(16.0),
      );
    }
    return const TilawaEmptyStateTokens(
      iconSize: 48.0,
      iconOpacity: 0.4,
      titleSpacing: 16.0,
      subtitleSpacing: 8.0,
      actionSpacing: 24.0,
      padding: EdgeInsets.all(24.0),
    );
  }

  TilawaEmptyStateTokens copyWith({
    double? iconSize,
    double? iconOpacity,
    double? titleSpacing,
    double? subtitleSpacing,
    double? actionSpacing,
    EdgeInsets? padding,
  }) {
    return TilawaEmptyStateTokens(
      iconSize: iconSize ?? this.iconSize,
      iconOpacity: iconOpacity ?? this.iconOpacity,
      titleSpacing: titleSpacing ?? this.titleSpacing,
      subtitleSpacing: subtitleSpacing ?? this.subtitleSpacing,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      padding: padding ?? this.padding,
    );
  }

  static TilawaEmptyStateTokens lerp(
    TilawaEmptyStateTokens a,
    TilawaEmptyStateTokens b,
    double t,
  ) {
    return TilawaEmptyStateTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      iconOpacity: lerpTokenDouble(a.iconOpacity, b.iconOpacity, t),
      titleSpacing: lerpTokenDouble(a.titleSpacing, b.titleSpacing, t),
      subtitleSpacing: lerpTokenDouble(a.subtitleSpacing, b.subtitleSpacing, t),
      actionSpacing: lerpTokenDouble(a.actionSpacing, b.actionSpacing, t),
      padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
    );
  }
}

/// Component tokens for [TilawaErrorState].
@immutable
class TilawaErrorStateTokens {
  const TilawaErrorStateTokens({
    required this.iconSize,
    required this.iconOpacity,
    required this.titleSpacing,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.subtitleSpacing,
    required this.subtitleFontSize,
    required this.subtitleOpacity,
    required this.actionSpacing,
    required this.padding,
    required this.retryButtonPadding,
    required this.retryButtonBorderRadius,
    this.retryButtonBackgroundColor,
    this.retryButtonForegroundColor,
  });

  /// Size of the error-state icon.
  final double iconSize;

  /// Opacity applied to the icon color.
  final double iconOpacity;

  /// Spacing between the icon and the title.
  final double titleSpacing;

  /// Font size of the title text.
  final double titleFontSize;

  /// Font weight of the title text.
  final FontWeight titleFontWeight;

  /// Spacing between the title and the subtitle.
  final double subtitleSpacing;

  /// Font size of the subtitle text.
  final double subtitleFontSize;

  /// Opacity applied to the subtitle color.
  final double subtitleOpacity;

  /// Spacing between the subtitle and the action button.
  final double actionSpacing;

  /// Outer padding around the whole error-state layout.
  final EdgeInsets padding;

  /// Padding inside the retry button.
  final EdgeInsets retryButtonPadding;

  /// Border radius of the retry button.
  final double retryButtonBorderRadius;

  /// Background color of the retry button. If null, uses colorScheme.onSurface.
  final Color? retryButtonBackgroundColor;

  /// Foreground color of the retry button. If null, uses colorScheme.surface.
  final Color? retryButtonForegroundColor;

  factory TilawaErrorStateTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    if (density.isCompact) {
      return const TilawaErrorStateTokens(
        iconSize: 64.0,
        iconOpacity: 0.8,
        titleSpacing: 16.0,
        titleFontSize: 24.0,
        titleFontWeight: FontWeight.bold,
        subtitleSpacing: 8.0,
        subtitleFontSize: 16.0,
        subtitleOpacity: 0.7,
        actionSpacing: 20.0,
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        retryButtonPadding: EdgeInsets.symmetric(
          horizontal: 32.0,
          vertical: 12.0,
        ),
        retryButtonBorderRadius: 30.0,
      );
    }
    return const TilawaErrorStateTokens(
      iconSize: 80.0,
      iconOpacity: 0.8,
      titleSpacing: 24.0,
      titleFontSize: 24.0,
      titleFontWeight: FontWeight.bold,
      subtitleSpacing: 12.0,
      subtitleFontSize: 16.0,
      subtitleOpacity: 0.7,
      actionSpacing: 32.0,
      padding: EdgeInsets.symmetric(horizontal: 40.0),
      retryButtonPadding: EdgeInsets.symmetric(
        horizontal: 32.0,
        vertical: 12.0,
      ),
      retryButtonBorderRadius: 30.0,
    );
  }

  TilawaErrorStateTokens copyWith({
    double? iconSize,
    double? iconOpacity,
    double? titleSpacing,
    double? titleFontSize,
    FontWeight? titleFontWeight,
    double? subtitleSpacing,
    double? subtitleFontSize,
    double? subtitleOpacity,
    double? actionSpacing,
    EdgeInsets? padding,
    EdgeInsets? retryButtonPadding,
    double? retryButtonBorderRadius,
    Color? retryButtonBackgroundColor,
    Color? retryButtonForegroundColor,
  }) {
    return TilawaErrorStateTokens(
      iconSize: iconSize ?? this.iconSize,
      iconOpacity: iconOpacity ?? this.iconOpacity,
      titleSpacing: titleSpacing ?? this.titleSpacing,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      titleFontWeight: titleFontWeight ?? this.titleFontWeight,
      subtitleSpacing: subtitleSpacing ?? this.subtitleSpacing,
      subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
      subtitleOpacity: subtitleOpacity ?? this.subtitleOpacity,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      padding: padding ?? this.padding,
      retryButtonPadding: retryButtonPadding ?? this.retryButtonPadding,
      retryButtonBorderRadius:
          retryButtonBorderRadius ?? this.retryButtonBorderRadius,
      retryButtonBackgroundColor:
          retryButtonBackgroundColor ?? this.retryButtonBackgroundColor,
      retryButtonForegroundColor:
          retryButtonForegroundColor ?? this.retryButtonForegroundColor,
    );
  }

  static TilawaErrorStateTokens lerp(
    TilawaErrorStateTokens a,
    TilawaErrorStateTokens b,
    double t,
  ) {
    return TilawaErrorStateTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      iconOpacity: lerpTokenDouble(a.iconOpacity, b.iconOpacity, t),
      titleSpacing: lerpTokenDouble(a.titleSpacing, b.titleSpacing, t),
      titleFontSize: lerpTokenDouble(a.titleFontSize, b.titleFontSize, t),
      titleFontWeight:
          FontWeight.lerp(a.titleFontWeight, b.titleFontWeight, t) ??
          a.titleFontWeight,
      subtitleSpacing: lerpTokenDouble(a.subtitleSpacing, b.subtitleSpacing, t),
      subtitleFontSize: lerpTokenDouble(
        a.subtitleFontSize,
        b.subtitleFontSize,
        t,
      ),
      subtitleOpacity: lerpTokenDouble(a.subtitleOpacity, b.subtitleOpacity, t),
      actionSpacing: lerpTokenDouble(a.actionSpacing, b.actionSpacing, t),
      padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
      retryButtonPadding: EdgeInsets.lerp(
        a.retryButtonPadding,
        b.retryButtonPadding,
        t,
      )!,
      retryButtonBorderRadius: lerpTokenDouble(
        a.retryButtonBorderRadius,
        b.retryButtonBorderRadius,
        t,
      ),
      retryButtonBackgroundColor: Color.lerp(
        a.retryButtonBackgroundColor,
        b.retryButtonBackgroundColor,
        t,
      ),
      retryButtonForegroundColor: Color.lerp(
        a.retryButtonForegroundColor,
        b.retryButtonForegroundColor,
        t,
      ),
    );
  }
}

/// Component tokens for [TilawaSkeletonBlock].
@immutable
class TilawaSkeletonTokens {
  const TilawaSkeletonTokens({
    required this.baseColor,
    required this.highlightColor,
    required this.borderRadius,
    required this.animationDuration,
    required this.pulseDuration,
  });

  /// Background color of the skeleton block.
  /// Derived from [ColorScheme.surfaceContainerHighest].
  final Color baseColor;

  /// Highlight color for shimmer animation.
  /// Derived from [ColorScheme.surfaceContainerHigh].
  final Color highlightColor;

  /// Border radius for rounded rectangle shapes.
  final double borderRadius;

  /// Duration of one complete shimmer animation cycle.
  final Duration animationDuration;

  /// Duration of pulse animation for reduced motion mode.
  final Duration pulseDuration;

  factory TilawaSkeletonTokens.defaults({
    required ColorScheme colorScheme,
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    final isCompact = density.isCompact;

    return TilawaSkeletonTokens(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerHigh,
      borderRadius: isCompact ? 8.0 : 12.0,
      animationDuration: const Duration(milliseconds: 1500),
      pulseDuration: const Duration(milliseconds: 1000),
    );
  }

  TilawaSkeletonTokens copyWith({
    Color? baseColor,
    Color? highlightColor,
    double? borderRadius,
    Duration? animationDuration,
    Duration? pulseDuration,
  }) {
    return TilawaSkeletonTokens(
      baseColor: baseColor ?? this.baseColor,
      highlightColor: highlightColor ?? this.highlightColor,
      borderRadius: borderRadius ?? this.borderRadius,
      animationDuration: animationDuration ?? this.animationDuration,
      pulseDuration: pulseDuration ?? this.pulseDuration,
    );
  }

  static TilawaSkeletonTokens lerp(
    TilawaSkeletonTokens a,
    TilawaSkeletonTokens b,
    double t,
  ) {
    return TilawaSkeletonTokens(
      baseColor: Color.lerp(a.baseColor, b.baseColor, t)!,
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t)!,
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      pulseDuration: t < 0.5 ? a.pulseDuration : b.pulseDuration,
    );
  }
}
