import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../design_tokens.dart' show kTilawaMinInteractiveDimension;
import 'token_lerp.dart';

@immutable
class TilawaAlphabetScrollbarTokens {
  const TilawaAlphabetScrollbarTokens({
    required this.width,
    required this.itemExtent,
    required this.selectedIndicatorExtent,
    required this.letterFontSize,
    required this.verticalPadding,
    required this.overlaySize,
    required this.overlayFontSize,
    required this.overlayRadius,
    required this.overlayOffset,
    required this.overlayBackgroundColor,
    required this.overlayShadowColor,
    required this.overlayShadowBlur,
    required this.overlayShadowOffset,
  });

  final double width;
  final double itemExtent;
  final double selectedIndicatorExtent;
  final double letterFontSize;
  final EdgeInsetsGeometry verticalPadding;
  final double overlaySize;
  final double overlayFontSize;
  final double overlayRadius;
  final double overlayOffset;

  /// Bubble fill while dragging (matches [ColorScheme.surfaceContainerHighest]).
  final Color overlayBackgroundColor;

  /// Soft shadow under the drag bubble ([Colors.black] with calibrated alpha).
  final Color overlayShadowColor;

  /// Blur radius for the overlay shadow (aligned with [TilawaDesignTokens.blurShadow]).
  final double overlayShadowBlur;

  final Offset overlayShadowOffset;

  factory TilawaAlphabetScrollbarTokens.defaults() {
    return TilawaAlphabetScrollbarTokens.fromColorScheme(
      ColorScheme.fromSeed(seedColor: AppColors.defaultPrimary),
    );
  }

  factory TilawaAlphabetScrollbarTokens.fromColorScheme(
    ColorScheme colorScheme,
  ) {
    return TilawaAlphabetScrollbarTokens(
      width: kTilawaMinInteractiveDimension,
      itemExtent:
          kTilawaMinInteractiveDimension, // fix: Accessibility — Tilawa 44 dp row hit target.
      selectedIndicatorExtent: 40,
      letterFontSize: 14,
      verticalPadding: const EdgeInsets.symmetric(vertical: 12),
      overlaySize: 64,
      overlayFontSize: 32,
      overlayRadius: 16,
      overlayOffset: 48,
      overlayBackgroundColor: colorScheme.surfaceContainerHighest,
      overlayShadowColor: const Color(0xFF000000).withValues(alpha: 0.15),
      overlayShadowBlur: 16,
      overlayShadowOffset: const Offset(0, 8),
    );
  }

  TilawaAlphabetScrollbarTokens copyWith({
    double? width,
    double? itemExtent,
    double? selectedIndicatorExtent,
    double? letterFontSize,
    EdgeInsetsGeometry? verticalPadding,
    double? overlaySize,
    double? overlayFontSize,
    double? overlayRadius,
    double? overlayOffset,
    Color? overlayBackgroundColor,
    Color? overlayShadowColor,
    double? overlayShadowBlur,
    Offset? overlayShadowOffset,
  }) {
    return TilawaAlphabetScrollbarTokens(
      width: width ?? this.width,
      itemExtent: itemExtent ?? this.itemExtent,
      selectedIndicatorExtent:
          selectedIndicatorExtent ?? this.selectedIndicatorExtent,
      letterFontSize: letterFontSize ?? this.letterFontSize,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      overlaySize: overlaySize ?? this.overlaySize,
      overlayFontSize: overlayFontSize ?? this.overlayFontSize,
      overlayRadius: overlayRadius ?? this.overlayRadius,
      overlayOffset: overlayOffset ?? this.overlayOffset,
      overlayBackgroundColor:
          overlayBackgroundColor ?? this.overlayBackgroundColor,
      overlayShadowColor: overlayShadowColor ?? this.overlayShadowColor,
      overlayShadowBlur: overlayShadowBlur ?? this.overlayShadowBlur,
      overlayShadowOffset: overlayShadowOffset ?? this.overlayShadowOffset,
    );
  }

  static TilawaAlphabetScrollbarTokens lerp(
    TilawaAlphabetScrollbarTokens a,
    TilawaAlphabetScrollbarTokens b,
    double t,
  ) {
    return TilawaAlphabetScrollbarTokens(
      width: lerpTokenDouble(a.width, b.width, t),
      itemExtent: lerpTokenDouble(a.itemExtent, b.itemExtent, t),
      selectedIndicatorExtent: lerpTokenDouble(
        a.selectedIndicatorExtent,
        b.selectedIndicatorExtent,
        t,
      ),
      letterFontSize: lerpTokenDouble(a.letterFontSize, b.letterFontSize, t),
      verticalPadding: EdgeInsetsGeometry.lerp(
        a.verticalPadding,
        b.verticalPadding,
        t,
      )!,
      overlaySize: lerpTokenDouble(a.overlaySize, b.overlaySize, t),
      overlayFontSize: lerpTokenDouble(a.overlayFontSize, b.overlayFontSize, t),
      overlayRadius: lerpTokenDouble(a.overlayRadius, b.overlayRadius, t),
      overlayOffset: lerpTokenDouble(a.overlayOffset, b.overlayOffset, t),
      overlayBackgroundColor: Color.lerp(
        a.overlayBackgroundColor,
        b.overlayBackgroundColor,
        t,
      )!,
      overlayShadowColor: Color.lerp(
        a.overlayShadowColor,
        b.overlayShadowColor,
        t,
      )!,
      overlayShadowBlur: lerpTokenDouble(
        a.overlayShadowBlur,
        b.overlayShadowBlur,
        t,
      ),
      overlayShadowOffset: Offset.lerp(
        a.overlayShadowOffset,
        b.overlayShadowOffset,
        t,
      )!,
    );
  }
}

@immutable
class TilawaFeedbackStripTokens {
  const TilawaFeedbackStripTokens({
    required this.padding,
    required this.borderRadius,
    required this.spinnerSize,
    required this.spinnerStrokeWidth,
    required this.contentGap,
  });

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double spinnerSize;
  final double spinnerStrokeWidth;
  final double contentGap;

  factory TilawaFeedbackStripTokens.defaults() {
    return const TilawaFeedbackStripTokens(
      padding: EdgeInsets.all(16),
      borderRadius: 18,
      spinnerSize: 18,
      spinnerStrokeWidth: 2.2,
      contentGap: 8,
    );
  }

  TilawaFeedbackStripTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? spinnerSize,
    double? spinnerStrokeWidth,
    double? contentGap,
  }) {
    return TilawaFeedbackStripTokens(
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      spinnerSize: spinnerSize ?? this.spinnerSize,
      spinnerStrokeWidth: spinnerStrokeWidth ?? this.spinnerStrokeWidth,
      contentGap: contentGap ?? this.contentGap,
    );
  }

  static TilawaFeedbackStripTokens lerp(
    TilawaFeedbackStripTokens a,
    TilawaFeedbackStripTokens b,
    double t,
  ) {
    return TilawaFeedbackStripTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      spinnerSize: lerpTokenDouble(a.spinnerSize, b.spinnerSize, t),
      spinnerStrokeWidth: lerpTokenDouble(
        a.spinnerStrokeWidth,
        b.spinnerStrokeWidth,
        t,
      ),
      contentGap: lerpTokenDouble(a.contentGap, b.contentGap, t),
    );
  }
}

@immutable
class TilawaGlassPanelTokens {
  const TilawaGlassPanelTokens({
    required this.padding,
    required this.borderRadiusOffset,
    required this.backgroundOpacity,
  });

  final EdgeInsetsGeometry padding;
  final double borderRadiusOffset;
  final double backgroundOpacity;

  factory TilawaGlassPanelTokens.defaults() {
    return const TilawaGlassPanelTokens(
      padding: EdgeInsets.all(16),
      borderRadiusOffset: 8,
      backgroundOpacity: 0.8,
    );
  }

  TilawaGlassPanelTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? borderRadiusOffset,
    double? backgroundOpacity,
  }) {
    return TilawaGlassPanelTokens(
      padding: padding ?? this.padding,
      borderRadiusOffset: borderRadiusOffset ?? this.borderRadiusOffset,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }

  static TilawaGlassPanelTokens lerp(
    TilawaGlassPanelTokens a,
    TilawaGlassPanelTokens b,
    double t,
  ) {
    return TilawaGlassPanelTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      borderRadiusOffset: lerpTokenDouble(
        a.borderRadiusOffset,
        b.borderRadiusOffset,
        t,
      ),
      backgroundOpacity: lerpTokenDouble(
        a.backgroundOpacity,
        b.backgroundOpacity,
        t,
      ),
    );
  }
}

@immutable
class TilawaIconActionButtonTokens {
  const TilawaIconActionButtonTokens({
    required this.size,
    required this.borderRadius,
    required this.activeBackgroundOpacity,
    required this.activeBorderOpacity,
    required this.inactiveBorderOpacity,
  });

  final double size;
  final double borderRadius;
  final double activeBackgroundOpacity;
  final double activeBorderOpacity;
  final double inactiveBorderOpacity;

  factory TilawaIconActionButtonTokens.defaults() {
    // Size = Tilawa hit-target floor (kTilawaMinInteractiveDimension, 48 dp).
    // At the floor; do not shrink further.
    return const TilawaIconActionButtonTokens(
      size: kTilawaMinInteractiveDimension,
      borderRadius: 16,
      activeBackgroundOpacity: 0.12,
      activeBorderOpacity: 0.35,
      inactiveBorderOpacity: 0.26,
    );
  }

  TilawaIconActionButtonTokens copyWith({
    double? size,
    double? borderRadius,
    double? activeBackgroundOpacity,
    double? activeBorderOpacity,
    double? inactiveBorderOpacity,
  }) {
    return TilawaIconActionButtonTokens(
      size: size ?? this.size,
      borderRadius: borderRadius ?? this.borderRadius,
      activeBackgroundOpacity:
          activeBackgroundOpacity ?? this.activeBackgroundOpacity,
      activeBorderOpacity: activeBorderOpacity ?? this.activeBorderOpacity,
      inactiveBorderOpacity:
          inactiveBorderOpacity ?? this.inactiveBorderOpacity,
    );
  }

  static TilawaIconActionButtonTokens lerp(
    TilawaIconActionButtonTokens a,
    TilawaIconActionButtonTokens b,
    double t,
  ) {
    return TilawaIconActionButtonTokens(
      size: lerpTokenDouble(a.size, b.size, t),
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      activeBackgroundOpacity: lerpTokenDouble(
        a.activeBackgroundOpacity,
        b.activeBackgroundOpacity,
        t,
      ),
      activeBorderOpacity: lerpTokenDouble(
        a.activeBorderOpacity,
        b.activeBorderOpacity,
        t,
      ),
      inactiveBorderOpacity: lerpTokenDouble(
        a.inactiveBorderOpacity,
        b.inactiveBorderOpacity,
        t,
      ),
    );
  }
}

@immutable
class TilawaChipTokens {
  const TilawaChipTokens({
    required this.padding,
    required this.inlinePadding,
    required this.backgroundColor,
    required this.defaultBorderColor,
    required this.selectionSelectedBackgroundColor,
    required this.selectionUnselectedBackgroundColor,
    required this.contentGap,
    required this.iconSize,
    required this.inlineIconSize,
    required this.borderWidth,
    required this.pillRadius,
    required this.roundedRadius,
    required this.selectedShadowOpacity,
    required this.selectedShadowBlur,
    required this.selectionFontWeight,
    required this.statusFontWeight,
    required this.statusLetterSpacing,
  });

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry inlinePadding;
  final Color backgroundColor;

  /// Default stroke for [TilawaChip] / [TilawaMetadataChip] ([TilawaDesignTokens.opacityMedium] on [ColorScheme.outlineVariant]).
  final Color defaultBorderColor;

  final Color selectionSelectedBackgroundColor;
  final Color selectionUnselectedBackgroundColor;
  final double contentGap;
  final double iconSize;
  final double inlineIconSize;
  final double borderWidth;
  final double pillRadius;
  final double roundedRadius;
  final double selectedShadowOpacity;
  final double selectedShadowBlur;
  final FontWeight selectionFontWeight;
  final FontWeight statusFontWeight;
  final double statusLetterSpacing;

  factory TilawaChipTokens.defaults() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.defaultPrimary,
    );
    return TilawaChipTokens.fromColorScheme(colorScheme);
  }

  factory TilawaChipTokens.fromColorScheme(ColorScheme colorScheme) {
    final backgroundColor = _backgroundColor(colorScheme);
    final selectionSelectedBackgroundColor = _selectionSelectedBackgroundColor(
      colorScheme,
    );
    final selectionUnselectedBackgroundColor =
        _selectionUnselectedBackgroundColor(colorScheme);
    final defaultBorderColor = _defaultBorderColor(colorScheme);
    return TilawaChipTokens(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      inlinePadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      backgroundColor: backgroundColor,
      defaultBorderColor: defaultBorderColor,
      selectionSelectedBackgroundColor: selectionSelectedBackgroundColor,
      selectionUnselectedBackgroundColor: selectionUnselectedBackgroundColor,
      contentGap: 8,
      iconSize: 16,
      inlineIconSize: 14,
      borderWidth: 0.5,
      pillRadius: 999,
      roundedRadius: 8,
      selectedShadowOpacity: 0.18,
      selectedShadowBlur: 12,
      selectionFontWeight: FontWeight.w700,
      statusFontWeight: FontWeight.w900,
      statusLetterSpacing: 0.5,
    );
  }

  static Color _backgroundColor(ColorScheme colorScheme) {
    final blendAmount = colorScheme.brightness == Brightness.dark ? 0.18 : 0.30;
    return Color.lerp(
      colorScheme.surface,
      colorScheme.surfaceContainer,
      blendAmount,
    )!;
  }

  static Color _defaultBorderColor(ColorScheme colorScheme) {
    return colorScheme.outlineVariant.withValues(alpha: 0.3);
  }

  static Color _selectionSelectedBackgroundColor(ColorScheme colorScheme) {
    final blendAmount = colorScheme.brightness == Brightness.dark ? 0.12 : 0.10;
    return Color.lerp(
      colorScheme.primaryContainer,
      colorScheme.primary,
      blendAmount,
    )!;
  }

  static Color _selectionUnselectedBackgroundColor(ColorScheme colorScheme) {
    final blendAmount = colorScheme.brightness == Brightness.dark ? 0.22 : 0.38;
    return Color.lerp(
      colorScheme.surface,
      colorScheme.surfaceContainer,
      blendAmount,
    )!;
  }

  TilawaChipTokens copyWith({
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? inlinePadding,
    Color? backgroundColor,
    Color? defaultBorderColor,
    Color? selectionSelectedBackgroundColor,
    Color? selectionUnselectedBackgroundColor,
    double? contentGap,
    double? iconSize,
    double? inlineIconSize,
    double? borderWidth,
    double? pillRadius,
    double? roundedRadius,
    double? selectedShadowOpacity,
    double? selectedShadowBlur,
    FontWeight? selectionFontWeight,
    FontWeight? statusFontWeight,
    double? statusLetterSpacing,
  }) {
    return TilawaChipTokens(
      padding: padding ?? this.padding,
      inlinePadding: inlinePadding ?? this.inlinePadding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      defaultBorderColor: defaultBorderColor ?? this.defaultBorderColor,
      selectionSelectedBackgroundColor:
          selectionSelectedBackgroundColor ??
          this.selectionSelectedBackgroundColor,
      selectionUnselectedBackgroundColor:
          selectionUnselectedBackgroundColor ??
          this.selectionUnselectedBackgroundColor,
      contentGap: contentGap ?? this.contentGap,
      iconSize: iconSize ?? this.iconSize,
      inlineIconSize: inlineIconSize ?? this.inlineIconSize,
      borderWidth: borderWidth ?? this.borderWidth,
      pillRadius: pillRadius ?? this.pillRadius,
      roundedRadius: roundedRadius ?? this.roundedRadius,
      selectedShadowOpacity:
          selectedShadowOpacity ?? this.selectedShadowOpacity,
      selectedShadowBlur: selectedShadowBlur ?? this.selectedShadowBlur,
      selectionFontWeight: selectionFontWeight ?? this.selectionFontWeight,
      statusFontWeight: statusFontWeight ?? this.statusFontWeight,
      statusLetterSpacing: statusLetterSpacing ?? this.statusLetterSpacing,
    );
  }

  static TilawaChipTokens lerp(
    TilawaChipTokens a,
    TilawaChipTokens b,
    double t,
  ) {
    return TilawaChipTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      inlinePadding: EdgeInsetsGeometry.lerp(
        a.inlinePadding,
        b.inlinePadding,
        t,
      )!,
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      defaultBorderColor: Color.lerp(
        a.defaultBorderColor,
        b.defaultBorderColor,
        t,
      )!,
      selectionSelectedBackgroundColor: Color.lerp(
        a.selectionSelectedBackgroundColor,
        b.selectionSelectedBackgroundColor,
        t,
      )!,
      selectionUnselectedBackgroundColor: Color.lerp(
        a.selectionUnselectedBackgroundColor,
        b.selectionUnselectedBackgroundColor,
        t,
      )!,
      contentGap: lerpTokenDouble(a.contentGap, b.contentGap, t),
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      inlineIconSize: lerpTokenDouble(a.inlineIconSize, b.inlineIconSize, t),
      borderWidth: lerpTokenDouble(a.borderWidth, b.borderWidth, t),
      pillRadius: lerpTokenDouble(a.pillRadius, b.pillRadius, t),
      roundedRadius: lerpTokenDouble(a.roundedRadius, b.roundedRadius, t),
      selectedShadowOpacity: lerpTokenDouble(
        a.selectedShadowOpacity,
        b.selectedShadowOpacity,
        t,
      ),
      selectedShadowBlur: lerpTokenDouble(
        a.selectedShadowBlur,
        b.selectedShadowBlur,
        t,
      ),
      selectionFontWeight: FontWeight.lerp(
        a.selectionFontWeight,
        b.selectionFontWeight,
        t,
      )!,
      statusFontWeight: FontWeight.lerp(
        a.statusFontWeight,
        b.statusFontWeight,
        t,
      )!,
      statusLetterSpacing: lerpTokenDouble(
        a.statusLetterSpacing,
        b.statusLetterSpacing,
        t,
      ),
    );
  }
}

@immutable
class TilawaSegmentedControlTokens {
  const TilawaSegmentedControlTokens({
    required this.containerPadding,
    required this.itemPadding,
    required this.itemSpacing,
    required this.containerBackgroundColor,
    required this.selectedBackgroundColor,
    required this.containerBorderColor,
    required this.containerRadius,
    required this.itemRadius,
    required this.containerOpacity,
    required this.minItemWidth,
    required this.selectedFontWeight,
    required this.unselectedFontWeight,
    required this.selectedItemShadowColor,
    required this.selectedItemShadowBlur,
    required this.selectedItemShadowOffset,
  });

  final EdgeInsetsGeometry containerPadding;
  final EdgeInsetsGeometry itemPadding;

  /// Logical gap between adjacent segment buttons. Lets the selected pill read
  /// as its own surface instead of butting up against the next segment.
  final double itemSpacing;
  final Color containerBackgroundColor;
  final Color selectedBackgroundColor;

  /// Outer border ([Border.all]) around the control track.
  final Color containerBorderColor;

  final double containerRadius;
  final double itemRadius;
  final double containerOpacity;
  final double minItemWidth;
  final FontWeight selectedFontWeight;
  final FontWeight unselectedFontWeight;

  final Color selectedItemShadowColor;
  final double selectedItemShadowBlur;
  final Offset selectedItemShadowOffset;

  factory TilawaSegmentedControlTokens.defaults() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.defaultPrimary,
    );
    return TilawaSegmentedControlTokens.fromColorScheme(colorScheme);
  }

  factory TilawaSegmentedControlTokens.fromColorScheme(
    ColorScheme colorScheme,
  ) {
    final containerBackgroundColor = _containerBackgroundColor(colorScheme);
    final selectedBackgroundColor = _selectedBackgroundColor(colorScheme);
    final containerBorderColor = _containerBorderColor(colorScheme);
    return TilawaSegmentedControlTokens(
      containerPadding: EdgeInsets.all(4),
      itemPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemSpacing: 4,
      containerBackgroundColor: containerBackgroundColor,
      selectedBackgroundColor: selectedBackgroundColor,
      containerBorderColor: containerBorderColor,
      containerRadius: 12,
      itemRadius: 8,
      containerOpacity: 0.3,
      minItemWidth: 100,
      selectedFontWeight: FontWeight.bold,
      unselectedFontWeight: FontWeight.normal,
      selectedItemShadowColor: const Color(0xFF000000).withValues(alpha: 0.05),
      selectedItemShadowBlur: 4,
      selectedItemShadowOffset: const Offset(0, 2),
    );
  }

  static Color _containerBackgroundColor(ColorScheme colorScheme) {
    final blendAmount = colorScheme.brightness == Brightness.dark ? 0.18 : 0.30;
    return Color.lerp(
      colorScheme.surface,
      colorScheme.surfaceContainer,
      blendAmount,
    )!;
  }

  static Color _selectedBackgroundColor(ColorScheme colorScheme) {
    final a = colorScheme.brightness == Brightness.dark ? 0.16 : 0.12;
    return Color.alphaBlend(
      colorScheme.primary.withValues(alpha: a),
      colorScheme.surfaceContainerHighest,
    );
  }

  static Color _containerBorderColor(ColorScheme colorScheme) {
    return colorScheme.outlineVariant.withValues(alpha: 0.72);
  }

  TilawaSegmentedControlTokens copyWith({
    EdgeInsetsGeometry? containerPadding,
    EdgeInsetsGeometry? itemPadding,
    double? itemSpacing,
    Color? containerBackgroundColor,
    Color? selectedBackgroundColor,
    Color? containerBorderColor,
    double? containerRadius,
    double? itemRadius,
    double? containerOpacity,
    double? minItemWidth,
    FontWeight? selectedFontWeight,
    FontWeight? unselectedFontWeight,
    Color? selectedItemShadowColor,
    double? selectedItemShadowBlur,
    Offset? selectedItemShadowOffset,
  }) {
    return TilawaSegmentedControlTokens(
      containerPadding: containerPadding ?? this.containerPadding,
      itemPadding: itemPadding ?? this.itemPadding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      containerBackgroundColor:
          containerBackgroundColor ?? this.containerBackgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      containerBorderColor: containerBorderColor ?? this.containerBorderColor,
      containerRadius: containerRadius ?? this.containerRadius,
      itemRadius: itemRadius ?? this.itemRadius,
      containerOpacity: containerOpacity ?? this.containerOpacity,
      minItemWidth: minItemWidth ?? this.minItemWidth,
      selectedFontWeight: selectedFontWeight ?? this.selectedFontWeight,
      unselectedFontWeight: unselectedFontWeight ?? this.unselectedFontWeight,
      selectedItemShadowColor:
          selectedItemShadowColor ?? this.selectedItemShadowColor,
      selectedItemShadowBlur:
          selectedItemShadowBlur ?? this.selectedItemShadowBlur,
      selectedItemShadowOffset:
          selectedItemShadowOffset ?? this.selectedItemShadowOffset,
    );
  }

  static TilawaSegmentedControlTokens lerp(
    TilawaSegmentedControlTokens a,
    TilawaSegmentedControlTokens b,
    double t,
  ) {
    return TilawaSegmentedControlTokens(
      containerPadding: EdgeInsetsGeometry.lerp(
        a.containerPadding,
        b.containerPadding,
        t,
      )!,
      itemPadding: EdgeInsetsGeometry.lerp(a.itemPadding, b.itemPadding, t)!,
      itemSpacing: lerpTokenDouble(a.itemSpacing, b.itemSpacing, t),
      containerBackgroundColor: Color.lerp(
        a.containerBackgroundColor,
        b.containerBackgroundColor,
        t,
      )!,
      selectedBackgroundColor: Color.lerp(
        a.selectedBackgroundColor,
        b.selectedBackgroundColor,
        t,
      )!,
      containerBorderColor: Color.lerp(
        a.containerBorderColor,
        b.containerBorderColor,
        t,
      )!,
      containerRadius: lerpTokenDouble(a.containerRadius, b.containerRadius, t),
      itemRadius: lerpTokenDouble(a.itemRadius, b.itemRadius, t),
      containerOpacity: lerpTokenDouble(
        a.containerOpacity,
        b.containerOpacity,
        t,
      ),
      minItemWidth: lerpTokenDouble(a.minItemWidth, b.minItemWidth, t),
      selectedFontWeight: FontWeight.lerp(
        a.selectedFontWeight,
        b.selectedFontWeight,
        t,
      )!,
      unselectedFontWeight: FontWeight.lerp(
        a.unselectedFontWeight,
        b.unselectedFontWeight,
        t,
      )!,
      selectedItemShadowColor: Color.lerp(
        a.selectedItemShadowColor,
        b.selectedItemShadowColor,
        t,
      )!,
      selectedItemShadowBlur: lerpTokenDouble(
        a.selectedItemShadowBlur,
        b.selectedItemShadowBlur,
        t,
      ),
      selectedItemShadowOffset: Offset.lerp(
        a.selectedItemShadowOffset,
        b.selectedItemShadowOffset,
        t,
      )!,
    );
  }
}

@immutable
class TilawaSeekBarTokens {
  const TilawaSeekBarTokens({
    required this.touchExtent,
    required this.horizontalMargin,
    required this.trackHeight,
    required this.thumbRadius,
    required this.bufferedTrackOpacity,
    required this.inactiveTrackOpacity,
  });

  final double touchExtent;
  final double horizontalMargin;
  final double trackHeight;
  final double thumbRadius;
  final double bufferedTrackOpacity;
  final double inactiveTrackOpacity;

  factory TilawaSeekBarTokens.defaults() {
    // fix: Accessibility — Tilawa 44 dp touch strip for seek interaction.
    return const TilawaSeekBarTokens(
      touchExtent: kTilawaMinInteractiveDimension,
      horizontalMargin: 16,
      trackHeight: 8,
      thumbRadius: 12,
      bufferedTrackOpacity: 0.3,
      inactiveTrackOpacity: 0.1,
    );
  }

  TilawaSeekBarTokens copyWith({
    double? touchExtent,
    double? horizontalMargin,
    double? trackHeight,
    double? thumbRadius,
    double? bufferedTrackOpacity,
    double? inactiveTrackOpacity,
  }) {
    return TilawaSeekBarTokens(
      touchExtent: touchExtent ?? this.touchExtent,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      trackHeight: trackHeight ?? this.trackHeight,
      thumbRadius: thumbRadius ?? this.thumbRadius,
      bufferedTrackOpacity: bufferedTrackOpacity ?? this.bufferedTrackOpacity,
      inactiveTrackOpacity: inactiveTrackOpacity ?? this.inactiveTrackOpacity,
    );
  }

  static TilawaSeekBarTokens lerp(
    TilawaSeekBarTokens a,
    TilawaSeekBarTokens b,
    double t,
  ) {
    return TilawaSeekBarTokens(
      touchExtent: lerpTokenDouble(a.touchExtent, b.touchExtent, t),
      horizontalMargin: lerpTokenDouble(
        a.horizontalMargin,
        b.horizontalMargin,
        t,
      ),
      trackHeight: lerpTokenDouble(a.trackHeight, b.trackHeight, t),
      thumbRadius: lerpTokenDouble(a.thumbRadius, b.thumbRadius, t),
      bufferedTrackOpacity: lerpTokenDouble(
        a.bufferedTrackOpacity,
        b.bufferedTrackOpacity,
        t,
      ),
      inactiveTrackOpacity: lerpTokenDouble(
        a.inactiveTrackOpacity,
        b.inactiveTrackOpacity,
        t,
      ),
    );
  }
}

@immutable
class TilawaSearchFieldTokens {
  const TilawaSearchFieldTokens({
    required this.height,
    required this.backgroundColor,
    required this.borderRadius,
    required this.contentPadding,
    required this.scrollPadding, // fix: Spacing & alignment — tokenized scroll inset
    required this.iconSize,
    required this.focusedBorderOpacity,
    required this.unfocusedBorderOpacity,
    required this.shadowOpacity,
    required this.hintOpacity,
    required this.iconOpacity,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.focusedBorderColor,
    required this.unfocusedBorderColor,
    required this.boxShadowColor,
    required this.hintTextColor,
    required this.prefixIconMutedColor,
    required this.prefixIconFocusedColor,
  });

  final double height;
  final Color backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;

  /// Padding passed to [TextField.scrollPadding] when the field is focused.
  final EdgeInsets scrollPadding;

  final double iconSize;
  final double focusedBorderOpacity;
  final double unfocusedBorderOpacity;
  final double shadowOpacity;
  final double hintOpacity;
  final double iconOpacity;
  final double shadowBlur;
  final Offset shadowOffset;

  final Color focusedBorderColor;
  final Color unfocusedBorderColor;
  final Color boxShadowColor;
  final Color hintTextColor;
  final Color prefixIconMutedColor;
  final Color prefixIconFocusedColor;

  factory TilawaSearchFieldTokens.defaults() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.defaultPrimary,
    );
    return TilawaSearchFieldTokens.fromColorScheme(colorScheme);
  }

  factory TilawaSearchFieldTokens.fromColorScheme(ColorScheme colorScheme) {
    final backgroundColor = _backgroundColor(colorScheme);
    const focusedBorderOpacity = 0.28;
    const unfocusedBorderOpacity = 0.26;
    const shadowOpacity = 0.04;
    // Slightly higher floor for hint vs surface (readability / WCAG-ish headroom).
    const hintOpacity = 0.62;
    const iconOpacity = 0.72;
    final focusedBorderColor = colorScheme.primary.withValues(
      alpha: focusedBorderOpacity,
    );
    final unfocusedBorderColor = colorScheme.outlineVariant.withValues(
      alpha: unfocusedBorderOpacity,
    );
    final boxShadowColor = colorScheme.primary.withValues(alpha: shadowOpacity);
    final hintTextColor = colorScheme.onSurfaceVariant.withValues(
      alpha: hintOpacity,
    );
    final prefixIconMutedColor = colorScheme.onSurfaceVariant.withValues(
      alpha: iconOpacity,
    );
    final prefixIconFocusedColor = colorScheme.primary;
    return TilawaSearchFieldTokens(
      height: kTilawaMinInteractiveDimension,
      backgroundColor: backgroundColor,
      borderRadius: 16,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      scrollPadding: const EdgeInsets.all(
        16,
      ), // fix: Spacing & alignment — tokenized (2×8dp)
      iconSize: 18,
      focusedBorderOpacity: focusedBorderOpacity,
      unfocusedBorderOpacity: unfocusedBorderOpacity,
      shadowOpacity: shadowOpacity,
      hintOpacity: hintOpacity,
      iconOpacity: iconOpacity,
      shadowBlur: 12,
      shadowOffset: Offset(0, 4),
      focusedBorderColor: focusedBorderColor,
      unfocusedBorderColor: unfocusedBorderColor,
      boxShadowColor: boxShadowColor,
      hintTextColor: hintTextColor,
      prefixIconMutedColor: prefixIconMutedColor,
      prefixIconFocusedColor: prefixIconFocusedColor,
    );
  }

  static Color _backgroundColor(ColorScheme colorScheme) {
    final blendAmount = colorScheme.brightness == Brightness.dark ? 0.24 : 0.42;
    return Color.lerp(
      colorScheme.surface,
      colorScheme.surfaceContainer,
      blendAmount,
    )!;
  }

  TilawaSearchFieldTokens copyWith({
    double? height,
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsets? scrollPadding,
    double? iconSize,
    double? focusedBorderOpacity,
    double? unfocusedBorderOpacity,
    double? shadowOpacity,
    double? hintOpacity,
    double? iconOpacity,
    double? shadowBlur,
    Offset? shadowOffset,
    Color? focusedBorderColor,
    Color? unfocusedBorderColor,
    Color? boxShadowColor,
    Color? hintTextColor,
    Color? prefixIconMutedColor,
    Color? prefixIconFocusedColor,
  }) {
    return TilawaSearchFieldTokens(
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      iconSize: iconSize ?? this.iconSize,
      focusedBorderOpacity: focusedBorderOpacity ?? this.focusedBorderOpacity,
      unfocusedBorderOpacity:
          unfocusedBorderOpacity ?? this.unfocusedBorderOpacity,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      hintOpacity: hintOpacity ?? this.hintOpacity,
      iconOpacity: iconOpacity ?? this.iconOpacity,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
      unfocusedBorderColor: unfocusedBorderColor ?? this.unfocusedBorderColor,
      boxShadowColor: boxShadowColor ?? this.boxShadowColor,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      prefixIconMutedColor: prefixIconMutedColor ?? this.prefixIconMutedColor,
      prefixIconFocusedColor:
          prefixIconFocusedColor ?? this.prefixIconFocusedColor,
    );
  }

  static TilawaSearchFieldTokens lerp(
    TilawaSearchFieldTokens a,
    TilawaSearchFieldTokens b,
    double t,
  ) {
    return TilawaSearchFieldTokens(
      height: lerpTokenDouble(a.height, b.height, t),
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      contentPadding: EdgeInsetsGeometry.lerp(
        a.contentPadding,
        b.contentPadding,
        t,
      )!,
      scrollPadding: EdgeInsets.lerp(a.scrollPadding, b.scrollPadding, t)!,
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      focusedBorderOpacity: lerpTokenDouble(
        a.focusedBorderOpacity,
        b.focusedBorderOpacity,
        t,
      ),
      unfocusedBorderOpacity: lerpTokenDouble(
        a.unfocusedBorderOpacity,
        b.unfocusedBorderOpacity,
        t,
      ),
      shadowOpacity: lerpTokenDouble(a.shadowOpacity, b.shadowOpacity, t),
      hintOpacity: lerpTokenDouble(a.hintOpacity, b.hintOpacity, t),
      iconOpacity: lerpTokenDouble(a.iconOpacity, b.iconOpacity, t),
      shadowBlur: lerpTokenDouble(a.shadowBlur, b.shadowBlur, t),
      shadowOffset: Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
      focusedBorderColor: Color.lerp(
        a.focusedBorderColor,
        b.focusedBorderColor,
        t,
      )!,
      unfocusedBorderColor: Color.lerp(
        a.unfocusedBorderColor,
        b.unfocusedBorderColor,
        t,
      )!,
      boxShadowColor: Color.lerp(a.boxShadowColor, b.boxShadowColor, t)!,
      hintTextColor: Color.lerp(a.hintTextColor, b.hintTextColor, t)!,
      prefixIconMutedColor: Color.lerp(
        a.prefixIconMutedColor,
        b.prefixIconMutedColor,
        t,
      )!,
      prefixIconFocusedColor: Color.lerp(
        a.prefixIconFocusedColor,
        b.prefixIconFocusedColor,
        t,
      )!,
    );
  }
}

@immutable
class TilawaCountProgressRingTokens {
  const TilawaCountProgressRingTokens({
    required this.outerSize,
    required this.innerSize,
    required this.ringStrokeWidth,
    required this.doneIconSize,
    required this.countFontSize,
    required this.countLineHeight,
    required this.countHorizontalPadding,
    required this.doneBorderWidth,
    required this.doneBorderOpacity,
    required this.activeGradientEndOpacity,
    required this.doneGradientEndOpacity,
    required this.progressLabelSpacing,
    required this.progressLabelPadding,
    required this.progressLabelBorderRadius,
    required this.progressLabelBackgroundOpacity,
  });

  final double outerSize;
  final double innerSize;
  final double ringStrokeWidth;
  final double doneIconSize;
  final double countFontSize;
  final double countLineHeight;
  final double countHorizontalPadding;
  final double doneBorderWidth;
  final double doneBorderOpacity;
  final double activeGradientEndOpacity;
  final double doneGradientEndOpacity;
  final double progressLabelSpacing;
  final EdgeInsetsGeometry progressLabelPadding;
  final double progressLabelBorderRadius;
  final double progressLabelBackgroundOpacity;

  factory TilawaCountProgressRingTokens.defaults() {
    return const TilawaCountProgressRingTokens(
      outerSize: 72,
      innerSize: 62,
      ringStrokeWidth: 10,
      doneIconSize: 50,
      countFontSize: 36,
      countLineHeight: 1,
      countHorizontalPadding: 6,
      doneBorderWidth: 2,
      doneBorderOpacity: 0.3,
      activeGradientEndOpacity: 0.8,
      doneGradientEndOpacity: 0.7,
      progressLabelSpacing: 16,
      progressLabelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      progressLabelBorderRadius: 24,
      progressLabelBackgroundOpacity: 0.3,
    );
  }

  TilawaCountProgressRingTokens copyWith({
    double? outerSize,
    double? innerSize,
    double? ringStrokeWidth,
    double? doneIconSize,
    double? countFontSize,
    double? countLineHeight,
    double? countHorizontalPadding,
    double? doneBorderWidth,
    double? doneBorderOpacity,
    double? activeGradientEndOpacity,
    double? doneGradientEndOpacity,
    double? progressLabelSpacing,
    EdgeInsetsGeometry? progressLabelPadding,
    double? progressLabelBorderRadius,
    double? progressLabelBackgroundOpacity,
  }) {
    return TilawaCountProgressRingTokens(
      outerSize: outerSize ?? this.outerSize,
      innerSize: innerSize ?? this.innerSize,
      ringStrokeWidth: ringStrokeWidth ?? this.ringStrokeWidth,
      doneIconSize: doneIconSize ?? this.doneIconSize,
      countFontSize: countFontSize ?? this.countFontSize,
      countLineHeight: countLineHeight ?? this.countLineHeight,
      countHorizontalPadding:
          countHorizontalPadding ?? this.countHorizontalPadding,
      doneBorderWidth: doneBorderWidth ?? this.doneBorderWidth,
      doneBorderOpacity: doneBorderOpacity ?? this.doneBorderOpacity,
      activeGradientEndOpacity:
          activeGradientEndOpacity ?? this.activeGradientEndOpacity,
      doneGradientEndOpacity:
          doneGradientEndOpacity ?? this.doneGradientEndOpacity,
      progressLabelSpacing: progressLabelSpacing ?? this.progressLabelSpacing,
      progressLabelPadding: progressLabelPadding ?? this.progressLabelPadding,
      progressLabelBorderRadius:
          progressLabelBorderRadius ?? this.progressLabelBorderRadius,
      progressLabelBackgroundOpacity:
          progressLabelBackgroundOpacity ?? this.progressLabelBackgroundOpacity,
    );
  }

  static TilawaCountProgressRingTokens lerp(
    TilawaCountProgressRingTokens a,
    TilawaCountProgressRingTokens b,
    double t,
  ) {
    return TilawaCountProgressRingTokens(
      outerSize: lerpTokenDouble(a.outerSize, b.outerSize, t),
      innerSize: lerpTokenDouble(a.innerSize, b.innerSize, t),
      ringStrokeWidth: lerpTokenDouble(a.ringStrokeWidth, b.ringStrokeWidth, t),
      doneIconSize: lerpTokenDouble(a.doneIconSize, b.doneIconSize, t),
      countFontSize: lerpTokenDouble(a.countFontSize, b.countFontSize, t),
      countLineHeight: lerpTokenDouble(a.countLineHeight, b.countLineHeight, t),
      countHorizontalPadding: lerpTokenDouble(
        a.countHorizontalPadding,
        b.countHorizontalPadding,
        t,
      ),
      doneBorderWidth: lerpTokenDouble(a.doneBorderWidth, b.doneBorderWidth, t),
      doneBorderOpacity: lerpTokenDouble(
        a.doneBorderOpacity,
        b.doneBorderOpacity,
        t,
      ),
      activeGradientEndOpacity: lerpTokenDouble(
        a.activeGradientEndOpacity,
        b.activeGradientEndOpacity,
        t,
      ),
      doneGradientEndOpacity: lerpTokenDouble(
        a.doneGradientEndOpacity,
        b.doneGradientEndOpacity,
        t,
      ),
      progressLabelSpacing: lerpTokenDouble(
        a.progressLabelSpacing,
        b.progressLabelSpacing,
        t,
      ),
      progressLabelPadding: EdgeInsetsGeometry.lerp(
        a.progressLabelPadding,
        b.progressLabelPadding,
        t,
      )!,
      progressLabelBorderRadius: lerpTokenDouble(
        a.progressLabelBorderRadius,
        b.progressLabelBorderRadius,
        t,
      ),
      progressLabelBackgroundOpacity: lerpTokenDouble(
        a.progressLabelBackgroundOpacity,
        b.progressLabelBackgroundOpacity,
        t,
      ),
    );
  }
}

/// Component tokens for [TilawaPermissionBanner].
@immutable
class TilawaPermissionBannerTokens {
  const TilawaPermissionBannerTokens({
    required this.padding,
    required this.borderRadius,
    required this.iconSize,
    required this.iconSpacing,
    required this.actionSpacing,
  });

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double iconSize;
  final double iconSpacing;
  final double actionSpacing;

  factory TilawaPermissionBannerTokens.defaults() {
    return const TilawaPermissionBannerTokens(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 12,
      iconSize: 16,
      iconSpacing: 8,
      actionSpacing: 8,
    );
  }

  TilawaPermissionBannerTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? iconSize,
    double? iconSpacing,
    double? actionSpacing,
  }) {
    return TilawaPermissionBannerTokens(
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      iconSize: iconSize ?? this.iconSize,
      iconSpacing: iconSpacing ?? this.iconSpacing,
      actionSpacing: actionSpacing ?? this.actionSpacing,
    );
  }

  static TilawaPermissionBannerTokens lerp(
    TilawaPermissionBannerTokens a,
    TilawaPermissionBannerTokens b,
    double t,
  ) {
    return TilawaPermissionBannerTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      iconSpacing: lerpTokenDouble(a.iconSpacing, b.iconSpacing, t),
      actionSpacing: lerpTokenDouble(a.actionSpacing, b.actionSpacing, t),
    );
  }
}

/// Component tokens for [TilawaPrayerAlertRow].
@immutable
class TilawaPrayerAlertRowTokens {
  const TilawaPrayerAlertRowTokens({
    required this.verticalPadding,
    required this.toggleSpacing,
  });

  final double verticalPadding;
  final double toggleSpacing;

  factory TilawaPrayerAlertRowTokens.defaults() {
    return const TilawaPrayerAlertRowTokens(
      verticalPadding: 4,
      toggleSpacing: 8,
    );
  }

  TilawaPrayerAlertRowTokens copyWith({
    double? verticalPadding,
    double? toggleSpacing,
  }) {
    return TilawaPrayerAlertRowTokens(
      verticalPadding: verticalPadding ?? this.verticalPadding,
      toggleSpacing: toggleSpacing ?? this.toggleSpacing,
    );
  }

  static TilawaPrayerAlertRowTokens lerp(
    TilawaPrayerAlertRowTokens a,
    TilawaPrayerAlertRowTokens b,
    double t,
  ) {
    return TilawaPrayerAlertRowTokens(
      verticalPadding: lerpTokenDouble(a.verticalPadding, b.verticalPadding, t),
      toggleSpacing: lerpTokenDouble(a.toggleSpacing, b.toggleSpacing, t),
    );
  }
}
