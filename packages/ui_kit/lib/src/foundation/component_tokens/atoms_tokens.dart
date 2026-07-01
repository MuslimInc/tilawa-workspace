import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../design_tokens.dart';
import 'token_lerp.dart';

@immutable
class TilawaSectionTitleTokens {
  const TilawaSectionTitleTokens({required this.fontWeight});

  final FontWeight fontWeight;

  factory TilawaSectionTitleTokens.defaults() {
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
    required this.marginTop,
    required this.marginBottom,
    required this.colorOpacity,
  });

  final double width;
  final double height;

  /// Space above the drag pill; matches [MeMuslimDesignTokens.spaceMedium].
  final double marginTop;
  final double marginBottom;
  final double colorOpacity;

  factory TilawaSheetHandleTokens.defaults() {
    return const TilawaSheetHandleTokens(
      width: 36,
      height: 5,
      marginTop: 12,
      marginBottom: 16,
      colorOpacity: 0.22,
    );
  }

  TilawaSheetHandleTokens copyWith({
    double? width,
    double? height,
    double? marginTop,
    double? marginBottom,
    double? colorOpacity,
  }) {
    return TilawaSheetHandleTokens(
      width: width ?? this.width,
      height: height ?? this.height,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
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
      marginTop: lerpTokenDouble(a.marginTop, b.marginTop, t),
      marginBottom: lerpTokenDouble(a.marginBottom, b.marginBottom, t),
      colorOpacity: lerpTokenDouble(a.colorOpacity, b.colorOpacity, t),
    );
  }
}

/// Component tokens for [TilawaCard].
///
/// Border width and padding for [TilawaCard]. Corner radius comes from
/// [TilawaRadiusFamily.card] via [MeMuslimDesignTokens.resolveRadius].
@immutable
class TilawaCardTokens {
  const TilawaCardTokens({
    required this.borderWidth,
    required this.padding,
  });

  /// Border width of the card outline.
  final double borderWidth;

  /// Default inner padding.
  final EdgeInsets padding;

  factory TilawaCardTokens.defaults() {
    return const TilawaCardTokens(
      borderWidth: 0.5,
      padding: EdgeInsets.all(16.0),
    );
  }

  TilawaCardTokens copyWith({
    double? borderWidth,
    EdgeInsets? padding,
  }) {
    return TilawaCardTokens(
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
      borderWidth: lerpTokenDouble(a.borderWidth, b.borderWidth, t),
      padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
    );
  }
}

/// Component tokens for [TilawaIconBox].
///
/// Defaults match icon size, padding, and border opacity for [TilawaIconBox].
/// Corner radius comes from [TilawaRadiusFamily.decorative].
@immutable
class TilawaIconBoxTokens {
  const TilawaIconBoxTokens({
    required this.iconSize,
    required this.backgroundColor,
    required this.padding,
    required this.borderOpacity,
  });

  /// Default icon size inside the box.
  final double iconSize;

  /// Default background color for icon containers.
  final Color backgroundColor;

  /// Inner padding around the icon.
  final double padding;

  /// Alpha applied to the icon colour for the hairline container border.
  final double borderOpacity;

  factory TilawaIconBoxTokens.defaults() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.defaultPrimary,
    );
    return TilawaIconBoxTokens.fromColorScheme(colorScheme);
  }

  factory TilawaIconBoxTokens.fromColorScheme(ColorScheme colorScheme) {
    final backgroundColor = _backgroundColor(colorScheme);
    return TilawaIconBoxTokens(
      iconSize: 24.0,
      backgroundColor: backgroundColor,
      padding: 8.0,
      borderOpacity: 0.15,
    );
  }

  static Color _backgroundColor(ColorScheme colorScheme) {
    final blendAmount = colorScheme.brightness == Brightness.dark ? 0.26 : 0.44;
    return Color.lerp(
      colorScheme.surface,
      colorScheme.surfaceContainer,
      blendAmount,
    )!;
  }

  TilawaIconBoxTokens copyWith({
    double? iconSize,
    Color? backgroundColor,
    double? padding,
    double? borderOpacity,
  }) {
    return TilawaIconBoxTokens(
      iconSize: iconSize ?? this.iconSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      borderOpacity: borderOpacity ?? this.borderOpacity,
    );
  }

  static TilawaIconBoxTokens lerp(
    TilawaIconBoxTokens a,
    TilawaIconBoxTokens b,
    double t,
  ) {
    return TilawaIconBoxTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      padding: lerpTokenDouble(a.padding, b.padding, t),
      borderOpacity: lerpTokenDouble(a.borderOpacity, b.borderOpacity, t),
    );
  }
}

/// Component tokens for [TilawaLoadingIndicator].
@immutable
class TilawaLoadingIndicatorTokens {
  const TilawaLoadingIndicatorTokens({required this.defaultStrokeWidth});

  /// Default stroke width for the circular progress indicator.
  ///
  /// Callers that need a thinner arc (e.g. inside a small tap target) should
  /// pass [TilawaLoadingIndicator.strokeWidth] instead of extending tokens.
  final double defaultStrokeWidth;

  factory TilawaLoadingIndicatorTokens.defaults() {
    return const TilawaLoadingIndicatorTokens(defaultStrokeWidth: 3.0);
  }

  TilawaLoadingIndicatorTokens copyWith({double? defaultStrokeWidth}) {
    return TilawaLoadingIndicatorTokens(
      defaultStrokeWidth: defaultStrokeWidth ?? this.defaultStrokeWidth,
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
    );
  }
}

/// Component tokens for [TilawaIconToggle].
@immutable
class TilawaIconToggleTokens {
  const TilawaIconToggleTokens({
    required this.iconSize,
    required this.activeBackgroundColor,
    required this.inactiveBackgroundColor,
    required this.padding,
  });

  final double iconSize;
  final Color activeBackgroundColor;
  final Color inactiveBackgroundColor;
  final double padding;

  factory TilawaIconToggleTokens.defaults() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.defaultPrimary,
    );
    return TilawaIconToggleTokens.fromColorScheme(colorScheme);
  }

  factory TilawaIconToggleTokens.fromColorScheme(ColorScheme colorScheme) {
    return TilawaIconToggleTokens(
      iconSize: 18.0,
      activeBackgroundColor: _activeBackgroundColor(colorScheme),
      inactiveBackgroundColor: _inactiveBackgroundColor(colorScheme),
      padding: 8.0,
    );
  }

  static Color _activeBackgroundColor(ColorScheme colorScheme) {
    final blendAmount = colorScheme.brightness == Brightness.dark ? 0.10 : 0.08;
    return Color.lerp(
      colorScheme.primaryContainer,
      colorScheme.primary,
      blendAmount,
    )!;
  }

  static Color _inactiveBackgroundColor(ColorScheme colorScheme) {
    final blendAmount = colorScheme.brightness == Brightness.dark ? 0.24 : 0.40;
    return Color.lerp(
      colorScheme.surface,
      colorScheme.surfaceContainer,
      blendAmount,
    )!;
  }

  TilawaIconToggleTokens copyWith({
    double? iconSize,
    Color? activeBackgroundColor,
    Color? inactiveBackgroundColor,
    double? padding,
  }) {
    return TilawaIconToggleTokens(
      iconSize: iconSize ?? this.iconSize,
      activeBackgroundColor:
          activeBackgroundColor ?? this.activeBackgroundColor,
      inactiveBackgroundColor:
          inactiveBackgroundColor ?? this.inactiveBackgroundColor,
      padding: padding ?? this.padding,
    );
  }

  static TilawaIconToggleTokens lerp(
    TilawaIconToggleTokens a,
    TilawaIconToggleTokens b,
    double t,
  ) {
    return TilawaIconToggleTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      activeBackgroundColor: Color.lerp(
        a.activeBackgroundColor,
        b.activeBackgroundColor,
        t,
      )!,
      inactiveBackgroundColor: Color.lerp(
        a.inactiveBackgroundColor,
        b.inactiveBackgroundColor,
        t,
      )!,
      padding: lerpTokenDouble(a.padding, b.padding, t),
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

  factory TilawaDividerTokens.defaults() {
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

  factory TilawaEmptyStateTokens.defaults() {
    return const TilawaEmptyStateTokens(
      iconSize: kMeMuslimMinInteractiveDimension,
      iconOpacity: 0.56,
      titleSpacing: 24.0,
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

/// Component tokens for [TilawaSkeleton] shimmer bones.
@immutable
class TilawaSkeletonTokens {
  const TilawaSkeletonTokens({
    required this.baseAlpha,
    required this.highlightAlpha,
    required this.shimmerBandWidth,
  });

  /// Alpha applied to `onSurface` for the resting bone fill.
  final double baseAlpha;

  /// Alpha applied to `onSurface` at the shimmer band's brightest point.
  final double highlightAlpha;

  /// Half-width of the travelling shimmer band, in alignment units
  /// (`0.3` ≈ a band covering 30% of the bone at any instant).
  final double shimmerBandWidth;

  factory TilawaSkeletonTokens.defaults() {
    return const TilawaSkeletonTokens(
      baseAlpha: 0.08,
      highlightAlpha: 0.16,
      shimmerBandWidth: 0.3,
    );
  }

  TilawaSkeletonTokens copyWith({
    double? baseAlpha,
    double? highlightAlpha,
    double? shimmerBandWidth,
  }) {
    return TilawaSkeletonTokens(
      baseAlpha: baseAlpha ?? this.baseAlpha,
      highlightAlpha: highlightAlpha ?? this.highlightAlpha,
      shimmerBandWidth: shimmerBandWidth ?? this.shimmerBandWidth,
    );
  }

  static TilawaSkeletonTokens lerp(
    TilawaSkeletonTokens a,
    TilawaSkeletonTokens b,
    double t,
  ) {
    return TilawaSkeletonTokens(
      baseAlpha: lerpTokenDouble(a.baseAlpha, b.baseAlpha, t),
      highlightAlpha: lerpTokenDouble(a.highlightAlpha, b.highlightAlpha, t),
      shimmerBandWidth: lerpTokenDouble(
        a.shimmerBandWidth,
        b.shimmerBandWidth,
        t,
      ),
    );
  }
}
