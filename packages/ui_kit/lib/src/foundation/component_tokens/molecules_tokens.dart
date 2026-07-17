import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../color_scheme_ext.dart';
import '../design_tokens.dart';
import '../tilawa_text_roles.dart';
import 'token_lerp.dart';

@immutable
class TilawaAlphabetScrollbarTokens {
  const TilawaAlphabetScrollbarTokens({
    required this.width,
    required this.itemExtent,
    required this.selectedIndicatorExtent,
    required this.letterTextRole,
    required this.verticalPadding,
    required this.overlaySize,
    required this.overlayTextRole,
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
  final TilawaTextRole letterTextRole;
  final EdgeInsetsGeometry verticalPadding;
  final double overlaySize;
  final TilawaTextRole overlayTextRole;
  final double overlayRadius;
  final double overlayOffset;

  /// Bubble fill while dragging (matches [ColorScheme.surfaceContainerHighest]).
  final Color overlayBackgroundColor;

  /// Soft shadow under the drag bubble ([Colors.black] with calibrated alpha).
  final Color overlayShadowColor;

  /// Blur radius for the overlay shadow (aligned with [MeMuslimDesignTokens.blurShadow]).
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
      // Slim index rail (just clears the selected disk). Vertical drag still
      // owns the hit path; list gutter adds outer thumb room.
      width: 24,
      // Slot taller than the glyph so letters breathe (was 18).
      itemExtent: 22,
      selectedIndicatorExtent: 20,
      letterTextRole: TilawaTextRole.labelSmall,
      // Inset A/Z from the pill ends.
      verticalPadding: const EdgeInsets.symmetric(vertical: 8),
      overlaySize: 72,
      overlayTextRole: TilawaTextRole.displaySmall,
      overlayRadius: 16,
      overlayOffset: 48,
      overlayBackgroundColor: colorScheme.surfaceContainerHighest,
      overlayShadowColor: const Color(
        0xFF000000,
      ).withValues(alpha: 0.15 * kElevationMultiplier),
      overlayShadowBlur: 16 * kElevationMultiplier,
      overlayShadowOffset: const Offset(0, 8 * kElevationMultiplier),
    );
  }

  TilawaAlphabetScrollbarTokens copyWith({
    double? width,
    double? itemExtent,
    double? selectedIndicatorExtent,
    TilawaTextRole? letterTextRole,
    EdgeInsetsGeometry? verticalPadding,
    double? overlaySize,
    TilawaTextRole? overlayTextRole,
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
      letterTextRole: letterTextRole ?? this.letterTextRole,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      overlaySize: overlaySize ?? this.overlaySize,
      overlayTextRole: overlayTextRole ?? this.overlayTextRole,
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
      letterTextRole: lerpTilawaTextRole(
        a.letterTextRole,
        b.letterTextRole,
        t,
      ),
      verticalPadding: EdgeInsetsGeometry.lerp(
        a.verticalPadding,
        b.verticalPadding,
        t,
      )!,
      overlaySize: lerpTokenDouble(a.overlaySize, b.overlaySize, t),
      overlayTextRole: lerpTilawaTextRole(
        a.overlayTextRole,
        b.overlayTextRole,
        t,
      ),
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
    required this.spinnerSize,
    required this.spinnerStrokeWidth,
    required this.contentGap,
    required this.leadingSlotSize,
    required this.toastMessageMaxLines,
    required this.infoAccentOpacity,
    required this.successAccentOpacity,
    required this.warningAccentOpacity,
    required this.errorAccentOpacity,
  });

  final EdgeInsetsGeometry padding;
  final double spinnerSize;
  final double spinnerStrokeWidth;
  final double contentGap;

  /// Square box for the leading icon or spinner so toast height stays stable.
  final double leadingSlotSize;

  /// Maximum visible message lines on [TilawaToast].
  final int toastMessageMaxLines;

  /// Border-accent alphas per [TilawaFeedbackVariant]. Error is strongest so
  /// the most urgent strip reads loudest; info is a quiet outline tint.
  final double infoAccentOpacity;
  final double successAccentOpacity;
  final double warningAccentOpacity;
  final double errorAccentOpacity;

  factory TilawaFeedbackStripTokens.defaults() {
    return const TilawaFeedbackStripTokens(
      padding: EdgeInsets.all(16),
      spinnerSize: 18,
      spinnerStrokeWidth: 2.2,
      contentGap: 8,
      leadingSlotSize: 24,
      toastMessageMaxLines: 2,
      infoAccentOpacity: 0.35,
      successAccentOpacity: 0.55,
      warningAccentOpacity: 0.55,
      errorAccentOpacity: 0.72,
    );
  }

  TilawaFeedbackStripTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? spinnerSize,
    double? spinnerStrokeWidth,
    double? contentGap,
    double? leadingSlotSize,
    int? toastMessageMaxLines,
    double? infoAccentOpacity,
    double? successAccentOpacity,
    double? warningAccentOpacity,
    double? errorAccentOpacity,
  }) {
    return TilawaFeedbackStripTokens(
      padding: padding ?? this.padding,
      spinnerSize: spinnerSize ?? this.spinnerSize,
      spinnerStrokeWidth: spinnerStrokeWidth ?? this.spinnerStrokeWidth,
      contentGap: contentGap ?? this.contentGap,
      leadingSlotSize: leadingSlotSize ?? this.leadingSlotSize,
      toastMessageMaxLines: toastMessageMaxLines ?? this.toastMessageMaxLines,
      infoAccentOpacity: infoAccentOpacity ?? this.infoAccentOpacity,
      successAccentOpacity: successAccentOpacity ?? this.successAccentOpacity,
      warningAccentOpacity: warningAccentOpacity ?? this.warningAccentOpacity,
      errorAccentOpacity: errorAccentOpacity ?? this.errorAccentOpacity,
    );
  }

  static TilawaFeedbackStripTokens lerp(
    TilawaFeedbackStripTokens a,
    TilawaFeedbackStripTokens b,
    double t,
  ) {
    return TilawaFeedbackStripTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      spinnerSize: lerpTokenDouble(a.spinnerSize, b.spinnerSize, t),
      spinnerStrokeWidth: lerpTokenDouble(
        a.spinnerStrokeWidth,
        b.spinnerStrokeWidth,
        t,
      ),
      contentGap: lerpTokenDouble(a.contentGap, b.contentGap, t),
      leadingSlotSize: lerpTokenDouble(
        a.leadingSlotSize,
        b.leadingSlotSize,
        t,
      ),
      toastMessageMaxLines: t < 0.5
          ? a.toastMessageMaxLines
          : b.toastMessageMaxLines,
      infoAccentOpacity: lerpTokenDouble(
        a.infoAccentOpacity,
        b.infoAccentOpacity,
        t,
      ),
      successAccentOpacity: lerpTokenDouble(
        a.successAccentOpacity,
        b.successAccentOpacity,
        t,
      ),
      warningAccentOpacity: lerpTokenDouble(
        a.warningAccentOpacity,
        b.warningAccentOpacity,
        t,
      ),
      errorAccentOpacity: lerpTokenDouble(
        a.errorAccentOpacity,
        b.errorAccentOpacity,
        t,
      ),
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
    required this.activeBackgroundOpacity,
    required this.activeBorderOpacity,
    required this.inactiveBorderOpacity,
  });

  final double size;
  final double activeBackgroundOpacity;
  final double activeBorderOpacity;
  final double inactiveBorderOpacity;

  factory TilawaIconActionButtonTokens.defaults() {
    // Size = Tilawa hit-target floor (kMeMuslimMinInteractiveDimension, 48 dp).
    // At the floor; do not shrink further.
    return const TilawaIconActionButtonTokens(
      size: kMeMuslimMinInteractiveDimension,
      activeBackgroundOpacity: 0.12,
      activeBorderOpacity: 0.35,
      inactiveBorderOpacity: 0.26,
    );
  }

  TilawaIconActionButtonTokens copyWith({
    double? size,
    double? activeBackgroundOpacity,
    double? activeBorderOpacity,
    double? inactiveBorderOpacity,
  }) {
    return TilawaIconActionButtonTokens(
      size: size ?? this.size,
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

/// Behance lifestyle filter: brown active pill + white label (light);
/// lifted warm tier on dark.
Color catalogFilterSelectedBackground(ColorScheme colorScheme) {
  if (colorScheme.brightness == Brightness.light) {
    return colorScheme.primary;
  }
  return Color.alphaBlend(
    colorScheme.primary.withValues(alpha: 0.16),
    colorScheme.surfaceContainerHighest,
  );
}

Color catalogFilterSelectedForeground(ColorScheme colorScheme) {
  return colorScheme.brightness == Brightness.light
      ? colorScheme.onPrimary
      : colorScheme.onSurface;
}

@immutable
class TilawaChipTokens {
  const TilawaChipTokens({
    required this.padding,
    required this.inlinePadding,
    required this.backgroundColor,
    required this.defaultBorderColor,
    required this.catalogSelectedBackgroundColor,
    required this.catalogSelectedForegroundColor,
    required this.selectionSelectedBackgroundColor,
    required this.selectionUnselectedBackgroundColor,
    required this.contentGap,
    required this.iconSize,
    required this.inlineIconSize,
    required this.borderWidth,
    required this.selectedShadowOpacity,
    required this.selectedShadowBlur,
    required this.selectionFontWeight,
    required this.statusFontWeight,
    required this.statusLetterSpacing,
  });

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry inlinePadding;
  final Color backgroundColor;

  /// Default stroke for [TilawaChip] / [TilawaMetadataChip] ([MeMuslimDesignTokens.opacityMedium] on [ColorScheme.outlineVariant]).
  final Color defaultBorderColor;

  /// Catalog [TilawaSelectionPillStyle.catalog] selected fill/label.
  final Color catalogSelectedBackgroundColor;
  final Color catalogSelectedForegroundColor;

  final Color selectionSelectedBackgroundColor;
  final Color selectionUnselectedBackgroundColor;
  final double contentGap;
  final double iconSize;
  final double inlineIconSize;
  final double borderWidth;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      inlinePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      backgroundColor: backgroundColor,
      defaultBorderColor: defaultBorderColor,
      catalogSelectedBackgroundColor: catalogFilterSelectedBackground(
        colorScheme,
      ),
      catalogSelectedForegroundColor: catalogFilterSelectedForeground(
        colorScheme,
      ),
      selectionSelectedBackgroundColor: selectionSelectedBackgroundColor,
      selectionUnselectedBackgroundColor: selectionUnselectedBackgroundColor,
      contentGap: 8,
      iconSize: 16,
      inlineIconSize: 14,
      borderWidth: 0.5,
      selectedShadowOpacity: 0.18 * kElevationMultiplier,
      selectedShadowBlur: 12 * kElevationMultiplier,
      selectionFontWeight: FontWeight.w700,
      statusFontWeight: FontWeight.w600,
      statusLetterSpacing: 0.25,
    );
  }

  static Color _backgroundColor(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? Color.lerp(
            colorScheme.surface,
            colorScheme.surfaceContainer,
            0.18,
          )!
        : colorScheme.surface;
  }

  static Color _defaultBorderColor(ColorScheme colorScheme) {
    return colorScheme.outlineVariant.withValues(alpha: 0.3);
  }

  static Color _selectionSelectedBackgroundColor(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return colorScheme.primary;
    }
    const blendAmount = 0.12;
    return Color.lerp(
      colorScheme.primaryContainer,
      colorScheme.primary,
      blendAmount,
    )!;
  }

  static Color _selectionUnselectedBackgroundColor(ColorScheme colorScheme) {
    return colorScheme.surfaceContainerHigh;
  }

  TilawaChipTokens copyWith({
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? inlinePadding,
    Color? backgroundColor,
    Color? defaultBorderColor,
    Color? catalogSelectedBackgroundColor,
    Color? catalogSelectedForegroundColor,
    Color? selectionSelectedBackgroundColor,
    Color? selectionUnselectedBackgroundColor,
    double? contentGap,
    double? iconSize,
    double? inlineIconSize,
    double? borderWidth,
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
      catalogSelectedBackgroundColor:
          catalogSelectedBackgroundColor ?? this.catalogSelectedBackgroundColor,
      catalogSelectedForegroundColor:
          catalogSelectedForegroundColor ?? this.catalogSelectedForegroundColor,
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
      catalogSelectedBackgroundColor: Color.lerp(
        a.catalogSelectedBackgroundColor,
        b.catalogSelectedBackgroundColor,
        t,
      )!,
      catalogSelectedForegroundColor: Color.lerp(
        a.catalogSelectedForegroundColor,
        b.catalogSelectedForegroundColor,
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
      containerPadding: const EdgeInsets.all(4),
      itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemSpacing: 4,
      containerBackgroundColor: containerBackgroundColor,
      selectedBackgroundColor: selectedBackgroundColor,
      containerBorderColor: containerBorderColor,
      containerOpacity: 0.3,
      minItemWidth: 100,
      selectedFontWeight: FontWeight.bold,
      unselectedFontWeight: FontWeight.normal,
      selectedItemShadowColor: const Color(
        0xFF000000,
      ).withValues(alpha: 0.05 * kElevationMultiplier),
      selectedItemShadowBlur: 4 * kElevationMultiplier,
      selectedItemShadowOffset: const Offset(0, 2 * kElevationMultiplier),
    );
  }

  static Color _containerBackgroundColor(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return colorScheme.surfaceContainerHigh;
    }
    const blendAmount = 0.18;
    return Color.lerp(
      colorScheme.surface,
      colorScheme.surfaceContainer,
      blendAmount,
    )!;
  }

  static Color _selectedBackgroundColor(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return colorScheme.primary;
    }
    return catalogFilterSelectedBackground(colorScheme);
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
    // fix: Accessibility — Tilawa 48 dp touch strip for seek interaction.
    return const TilawaSeekBarTokens(
      touchExtent: kMeMuslimMinInteractiveDimension,
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
    final MeMuslimDesignTokens tokens =
        colorScheme.brightness == Brightness.dark
        ? MeMuslimDesignTokens.dark()
        : MeMuslimDesignTokens.light();
    final backgroundColor = colorScheme.surface;
    const focusedBorderOpacity = 0.28;
    const unfocusedBorderOpacity = 0.26;
    const shadowOpacity = 0.04 * kElevationMultiplier;
    // Slightly higher floor for hint vs surface (readability / WCAG-ish headroom).
    const hintOpacity = 0.62;
    const iconOpacity = 0.72;
    final focusedBorderColor = colorScheme.onSurface.withValues(
      alpha: focusedBorderOpacity,
    );
    final unfocusedBorderColor = colorScheme.outlineVariant.withValues(
      alpha: unfocusedBorderOpacity,
    );
    final boxShadowColor = colorScheme.shadow.withValues(alpha: shadowOpacity);
    final hintTextColor = colorScheme.onSurfaceVariant.withValues(
      alpha: hintOpacity,
    );
    final prefixIconMutedColor = colorScheme.onSurfaceVariant.withValues(
      alpha: iconOpacity,
    );
    final prefixIconFocusedColor = colorScheme.onSurfaceVariant;
    return TilawaSearchFieldTokens(
      height: kMeMuslimMinInteractiveDimension,
      backgroundColor: backgroundColor,
      contentPadding: EdgeInsets.symmetric(vertical: tokens.spaceMedium),
      scrollPadding: EdgeInsets.all(tokens.spaceLarge),
      iconSize: 18,
      focusedBorderOpacity: focusedBorderOpacity,
      unfocusedBorderOpacity: unfocusedBorderOpacity,
      shadowOpacity: shadowOpacity,
      hintOpacity: hintOpacity,
      iconOpacity: iconOpacity,
      shadowBlur: 12 * kElevationMultiplier,
      shadowOffset: const Offset(0, 4 * kElevationMultiplier),
      focusedBorderColor: focusedBorderColor,
      unfocusedBorderColor: unfocusedBorderColor,
      boxShadowColor: boxShadowColor,
      hintTextColor: hintTextColor,
      prefixIconMutedColor: prefixIconMutedColor,
      prefixIconFocusedColor: prefixIconFocusedColor,
    );
  }

  TilawaSearchFieldTokens copyWith({
    double? height,
    Color? backgroundColor,
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
    required this.countTextRole,
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
  final TilawaTextRole countTextRole;
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
      outerSize: 56,
      innerSize: 56,
      ringStrokeWidth: 0,
      doneIconSize: 28,
      countTextRole: TilawaTextRole.titleLarge,
      countLineHeight: 1,
      countHorizontalPadding: 4,
      doneBorderWidth: 1.5,
      doneBorderOpacity: 0.28,
      activeGradientEndOpacity: 1,
      doneGradientEndOpacity: 1,
      progressLabelSpacing: 12,
      progressLabelPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      progressLabelBorderRadius: 24,
      progressLabelBackgroundOpacity: 0.3,
    );
  }

  TilawaCountProgressRingTokens copyWith({
    double? outerSize,
    double? innerSize,
    double? ringStrokeWidth,
    double? doneIconSize,
    TilawaTextRole? countTextRole,
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
      countTextRole: countTextRole ?? this.countTextRole,
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
      countTextRole: lerpTilawaTextRole(a.countTextRole, b.countTextRole, t),
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
    required this.iconSize,
    required this.iconSpacing,
    required this.actionSpacing,
  });

  final EdgeInsetsGeometry padding;
  final double iconSize;
  final double iconSpacing;
  final double actionSpacing;

  factory TilawaPermissionBannerTokens.defaults() {
    return const TilawaPermissionBannerTokens(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      iconSize: 16,
      iconSpacing: 8,
      actionSpacing: 8,
    );
  }

  TilawaPermissionBannerTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? iconSize,
    double? iconSpacing,
    double? actionSpacing,
  }) {
    return TilawaPermissionBannerTokens(
      padding: padding ?? this.padding,
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
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      iconSpacing: lerpTokenDouble(a.iconSpacing, b.iconSpacing, t),
      actionSpacing: lerpTokenDouble(a.actionSpacing, b.actionSpacing, t),
    );
  }
}

/// Component tokens for the Home next-prayer hero card gradient shell.
///
/// Phase-aware Islamic palette — restrained stops in [AppColors].
@immutable
class TilawaHomeNextPrayerHeroTokens {
  const TilawaHomeNextPrayerHeroTokens({
    required this.gradientTopStart,
    required this.gradientBottomEnd,
    this.gradientMidStop,
    required this.foregroundColor,
    required this.locationChipFillOpacity,
    required this.locationChipBorderOpacity,
    required this.locationChipSplashOpacity,
    required this.locationChipHighlightOpacity,
    required this.mutedForegroundOpacity,
    required this.tertiaryForegroundOpacity,
    required this.footerForegroundOpacity,
  });

  /// Top-start gradient stop.
  final Color gradientTopStart;

  /// Bottom-end gradient stop; also used for material fill and card shadow.
  final Color gradientBottomEnd;

  /// Optional middle stop for three-color day ramps; when null the app lerps
  /// between [gradientTopStart] and [gradientBottomEnd].
  final Color? gradientMidStop;

  /// Text and icons on the gradient surface.
  final Color foregroundColor;

  /// Frosted location chip fill alpha on [foregroundColor].
  final double locationChipFillOpacity;

  /// Frosted location chip border alpha on [foregroundColor].
  final double locationChipBorderOpacity;

  final double locationChipSplashOpacity;
  final double locationChipHighlightOpacity;

  /// Secondary copy (countdown, supporting lines) on the gradient.
  final double mutedForegroundOpacity;

  /// Tertiary copy (eyebrows, metadata) on the gradient.
  final double tertiaryForegroundOpacity;

  /// Greeting and prayer-name alpha on [foregroundColor].
  final double footerForegroundOpacity;

  LinearGradient get backgroundGradient => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [gradientTopStart, gradientBottomEnd],
  );

  factory TilawaHomeNextPrayerHeroTokens.defaults() =>
      TilawaHomeNextPrayerHeroTokens.day();

  /// Daytime hero gradient (sunrise through Asr).
  factory TilawaHomeNextPrayerHeroTokens.day() {
    return const TilawaHomeNextPrayerHeroTokens(
      gradientTopStart: AppColors.homeNextPrayerGradientTop,
      gradientBottomEnd: AppColors.homeNextPrayerGradientBottom,
      gradientMidStop: AppColors.homeNextPrayerGradientDayMid,
      foregroundColor: AppColors.homeNextPrayerGradientForeground,
      locationChipFillOpacity: 0.14,
      locationChipBorderOpacity: 0.28,
      locationChipSplashOpacity: 0.1,
      locationChipHighlightOpacity: 0.05,
      mutedForegroundOpacity: 0.64,
      tertiaryForegroundOpacity: 0.56,
      footerForegroundOpacity: 0.88,
    );
  }

  /// Maghrib-through-Isha hero gradient with a subtle warm cast.
  factory TilawaHomeNextPrayerHeroTokens.dusk() {
    return const TilawaHomeNextPrayerHeroTokens(
      gradientTopStart: AppColors.homeNextPrayerGradientDuskTop,
      gradientBottomEnd: AppColors.homeNextPrayerGradientDuskBottom,
      foregroundColor: AppColors.homeNextPrayerGradientForeground,
      locationChipFillOpacity: 0.14,
      locationChipBorderOpacity: 0.28,
      locationChipSplashOpacity: 0.1,
      locationChipHighlightOpacity: 0.05,
      mutedForegroundOpacity: 0.64,
      tertiaryForegroundOpacity: 0.56,
      footerForegroundOpacity: 0.88,
    );
  }

  /// Pre-dawn hero gradient (cool mist before sunrise — always light).
  factory TilawaHomeNextPrayerHeroTokens.preDawn() {
    return const TilawaHomeNextPrayerHeroTokens(
      gradientTopStart: AppColors.homeNextPrayerGradientPreDawnTop,
      gradientBottomEnd: AppColors.homeNextPrayerGradientPreDawnBottom,
      foregroundColor: AppColors.homeNextPrayerGradientForeground,
      locationChipFillOpacity: 0.10,
      locationChipBorderOpacity: 0.22,
      locationChipSplashOpacity: 0.08,
      locationChipHighlightOpacity: 0.04,
      mutedForegroundOpacity: 0.68,
      tertiaryForegroundOpacity: 0.60,
      footerForegroundOpacity: 0.90,
    );
  }

  /// Night hero gradient (Isha through deep night before pre-dawn ease).
  factory TilawaHomeNextPrayerHeroTokens.night() {
    return const TilawaHomeNextPrayerHeroTokens(
      gradientTopStart: AppColors.homeNextPrayerGradientNightTop,
      gradientBottomEnd: AppColors.homeNextPrayerGradientNightBottom,
      foregroundColor: AppColors.homeNextPrayerGradientNightForeground,
      locationChipFillOpacity: 0.12,
      locationChipBorderOpacity: 0.24,
      locationChipSplashOpacity: 0.1,
      locationChipHighlightOpacity: 0.05,
      mutedForegroundOpacity: 0.68,
      tertiaryForegroundOpacity: 0.58,
      footerForegroundOpacity: 0.90,
    );
  }

  TilawaHomeNextPrayerHeroTokens copyWith({
    Color? gradientTopStart,
    Color? gradientBottomEnd,
    Color? gradientMidStop,
    Color? foregroundColor,
    double? locationChipFillOpacity,
    double? locationChipBorderOpacity,
    double? locationChipSplashOpacity,
    double? locationChipHighlightOpacity,
    double? mutedForegroundOpacity,
    double? tertiaryForegroundOpacity,
    double? footerForegroundOpacity,
  }) {
    return TilawaHomeNextPrayerHeroTokens(
      gradientTopStart: gradientTopStart ?? this.gradientTopStart,
      gradientBottomEnd: gradientBottomEnd ?? this.gradientBottomEnd,
      gradientMidStop: gradientMidStop ?? this.gradientMidStop,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      locationChipFillOpacity:
          locationChipFillOpacity ?? this.locationChipFillOpacity,
      locationChipBorderOpacity:
          locationChipBorderOpacity ?? this.locationChipBorderOpacity,
      locationChipSplashOpacity:
          locationChipSplashOpacity ?? this.locationChipSplashOpacity,
      locationChipHighlightOpacity:
          locationChipHighlightOpacity ?? this.locationChipHighlightOpacity,
      mutedForegroundOpacity:
          mutedForegroundOpacity ?? this.mutedForegroundOpacity,
      tertiaryForegroundOpacity:
          tertiaryForegroundOpacity ?? this.tertiaryForegroundOpacity,
      footerForegroundOpacity:
          footerForegroundOpacity ?? this.footerForegroundOpacity,
    );
  }

  static TilawaHomeNextPrayerHeroTokens lerp(
    TilawaHomeNextPrayerHeroTokens a,
    TilawaHomeNextPrayerHeroTokens b,
    double t,
  ) {
    return TilawaHomeNextPrayerHeroTokens(
      gradientTopStart: Color.lerp(a.gradientTopStart, b.gradientTopStart, t)!,
      gradientBottomEnd: Color.lerp(
        a.gradientBottomEnd,
        b.gradientBottomEnd,
        t,
      )!,
      gradientMidStop: Color.lerp(a.gradientMidStop, b.gradientMidStop, t),
      foregroundColor: Color.lerp(a.foregroundColor, b.foregroundColor, t)!,
      locationChipFillOpacity: lerpTokenDouble(
        a.locationChipFillOpacity,
        b.locationChipFillOpacity,
        t,
      ),
      locationChipBorderOpacity: lerpTokenDouble(
        a.locationChipBorderOpacity,
        b.locationChipBorderOpacity,
        t,
      ),
      locationChipSplashOpacity: lerpTokenDouble(
        a.locationChipSplashOpacity,
        b.locationChipSplashOpacity,
        t,
      ),
      locationChipHighlightOpacity: lerpTokenDouble(
        a.locationChipHighlightOpacity,
        b.locationChipHighlightOpacity,
        t,
      ),
      mutedForegroundOpacity: lerpTokenDouble(
        a.mutedForegroundOpacity,
        b.mutedForegroundOpacity,
        t,
      ),
      tertiaryForegroundOpacity: lerpTokenDouble(
        a.tertiaryForegroundOpacity,
        b.tertiaryForegroundOpacity,
        t,
      ),
      footerForegroundOpacity: lerpTokenDouble(
        a.footerForegroundOpacity,
        b.footerForegroundOpacity,
        t,
      ),
    );
  }
}

/// Screen-level Home canvas and next-prayer glass card semantics.
@immutable
class TilawaHomeScreenTokens {
  const TilawaHomeScreenTokens({
    required this.backgroundGradientStart,
    required this.backgroundGradientMiddle,
    required this.backgroundGradientEnd,
    required this.backgroundGlowColor,
    required this.backgroundGlowOpacity,
    required this.homePrayerHeroBackground,
    required this.homePrayerHeroBorder,
    required this.homePrayerHeroShadow,
    required this.homePrayerHeroShadowOpacity,
    required this.homePrayerHeroAccent,
    required this.homePrayerHeroWatermark,
    required this.homePrayerHeroWatermarkOpacity,
    required this.homeHeaderChipBackground,
    required this.homeHeaderSecondaryText,
    required this.homeCollapsedHeaderFill,
    required this.homeCollapsedHeaderBorder,
    required this.homeCollapsedHeaderShadowOpacity,
    required this.homeFeaturedTutorGradientStart,
    required this.homeFeaturedTutorGradientEnd,
    required this.homeFeaturedTutorAccent,
    required this.homeContentSheetSurface,
    required this.homeContentSheetShadowOpacity,
    required this.homeContentSheetTopBorder,
    required this.homeHeroPatternInk,
    required this.homeHeroPatternOpacity,
    required this.homeHeroGoldGlowOpacity,
    required this.homeFeaturedTutorCtaForeground,
    required this.quickActionTileBackground,
  });

  final Color backgroundGradientStart;
  final Color backgroundGradientMiddle;
  final Color backgroundGradientEnd;
  final Color backgroundGlowColor;
  final double backgroundGlowOpacity;
  final Color homePrayerHeroBackground;
  final Color homePrayerHeroBorder;
  final Color homePrayerHeroShadow;
  final double homePrayerHeroShadowOpacity;
  final Color homePrayerHeroAccent;
  final Color homePrayerHeroWatermark;
  final double homePrayerHeroWatermarkOpacity;
  final Color homeHeaderChipBackground;
  final Color homeHeaderSecondaryText;
  final Color homeCollapsedHeaderFill;
  final Color homeCollapsedHeaderBorder;
  final double homeCollapsedHeaderShadowOpacity;
  final Color homeFeaturedTutorGradientStart;
  final Color homeFeaturedTutorGradientEnd;
  final Color homeFeaturedTutorAccent;
  final Color homeContentSheetSurface;
  final double homeContentSheetShadowOpacity;
  final Color homeContentSheetTopBorder;
  final Color homeHeroPatternInk;
  final double homeHeroPatternOpacity;
  final double homeHeroGoldGlowOpacity;
  final Color homeFeaturedTutorCtaForeground;
  final Color quickActionTileBackground;

  /// Overlap between the hero bottom and the content sheet top edge.
  static double contentSheetOverlap(MeMuslimDesignTokens tokens) {
    return tokens.spaceMedium;
  }

  /// Horizontal inset for Home dashboard screen edges.
  ///
  /// Uses [MeMuslimDesignTokens.spaceLarge] — same gutter as other product
  /// screens (prayer times, reciters, history).
  static double screenHorizontalPadding(MeMuslimDesignTokens tokens) {
    return tokens.spaceLarge;
  }

  BoxDecoration contentSheetDecoration({
    required MeMuslimDesignTokens tokens,
    required ColorScheme colorScheme,
    required BorderRadius borderRadius,
  }) {
    return BoxDecoration(
      color: homeContentSheetSurface,
      borderRadius: borderRadius,
      border: Border(
        top: BorderSide(
          color: homeContentSheetTopBorder,
          width: tokens.borderWidthThin,
        ),
      ),
      boxShadow: homeContentSheetShadowOpacity > 0
          ? tokens.elevationSubtle(colorScheme.shadow)
          : null,
    );
  }

  /// Flat dashboard card chrome — hairline border with optional soft shadow.
  BoxDecoration dashboardSurfaceDecoration({
    required MeMuslimDesignTokens tokens,
    required ColorScheme colorScheme,
    required BorderRadius borderRadius,
    Color? color,
    double? shadowOpacity,
  }) {
    final double opacity = shadowOpacity ?? homePrayerHeroShadowOpacity;
    final Color borderColor = Color.alphaBlend(
      homePrayerHeroBorder.withValues(alpha: 0.72),
      colorScheme.outlineVariant.withValues(alpha: 0.28),
    );

    return BoxDecoration(
      color: color ?? homeContentSheetSurface,
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor,
        width: tokens.borderWidthThin,
      ),
      boxShadow: opacity > 0
          ? tokens.elevationRaised(colorScheme.shadow)
          : null,
    );
  }

  LinearGradient featuredTutorGradient() {
    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: <Color>[
        homeFeaturedTutorGradientStart,
        homeFeaturedTutorGradientEnd,
      ],
    );
  }

  LinearGradient backgroundGradient() {
    final Color middle = Color.lerp(
      backgroundGradientStart,
      backgroundGradientEnd,
      0.42,
    )!;

    return LinearGradient(
      begin: AlignmentDirectional.topCenter,
      end: AlignmentDirectional.bottomCenter,
      colors: <Color>[
        backgroundGradientStart,
        middle,
        backgroundGradientEnd,
      ],
      stops: const <double>[0, 0.42, 1],
    );
  }

  /// Theme-aware Home canvas gradient — soft porcelain warmth at top, not a
  /// primary wash. Top stop stays slightly greener than the scaffold porcelain.
  LinearGradient backgroundGradientFor(ColorScheme colorScheme) {
    final Color top = Color.lerp(
      backgroundGradientStart,
      AppColors.brandActionGreen,
      0.04,
    )!;

    return LinearGradient(
      begin: AlignmentDirectional.topCenter,
      end: AlignmentDirectional.bottomCenter,
      colors: <Color>[
        top,
        backgroundGradientMiddle,
        backgroundGradientEnd,
      ],
      stops: const <double>[0, 0.34, 1],
    );
  }

  factory TilawaHomeScreenTokens.light() {
    return const TilawaHomeScreenTokens(
      backgroundGradientStart: AppColors.homeBackgroundGradientStart,
      backgroundGradientMiddle: AppColors.homeBackgroundGradientMiddle,
      backgroundGradientEnd: AppColors.homeBackgroundGradientEnd,
      backgroundGlowColor: AppColors.homeBackgroundGlow,
      backgroundGlowOpacity: 0,
      homePrayerHeroBackground: AppColors.homePrayerHeroBackground,
      homePrayerHeroBorder: AppColors.homePrayerHeroBorder,
      homePrayerHeroShadow: AppColors.homePrayerHeroShadow,
      homePrayerHeroShadowOpacity: 0,
      homePrayerHeroAccent: AppColors.homePrayerHeroAccent,
      homePrayerHeroWatermark: AppColors.homePrayerHeroWatermark,
      homePrayerHeroWatermarkOpacity: 0.07,
      homeHeaderChipBackground: AppColors.homeHeaderChipBackground,
      homeHeaderSecondaryText: AppColors.homeHeaderSecondaryText,
      homeCollapsedHeaderFill: AppColors.homeCollapsedHeaderFill,
      homeCollapsedHeaderBorder: AppColors.homeCollapsedHeaderBorder,
      homeCollapsedHeaderShadowOpacity: 0,
      homeFeaturedTutorGradientStart: AppColors.homeFeaturedTutorGradientStart,
      homeFeaturedTutorGradientEnd: AppColors.homeFeaturedTutorGradientEnd,
      homeFeaturedTutorAccent: AppColors.homeFeaturedTutorAccent,
      homeContentSheetSurface: AppColors.homeContentSheetSurface,
      homeContentSheetShadowOpacity: 0,
      homeContentSheetTopBorder: AppColors.homeContentSheetTopBorder,
      homeHeroPatternInk: AppColors.homeHeroPatternInk,
      homeHeroPatternOpacity: 0,
      homeHeroGoldGlowOpacity: 0,
      homeFeaturedTutorCtaForeground: AppColors.homeFeaturedTutorCtaForeground,
      quickActionTileBackground: AppColors.homeQuickActionTileBackground,
    );
  }

  factory TilawaHomeScreenTokens.dark() {
    return const TilawaHomeScreenTokens(
      backgroundGradientStart: AppColors.homeBackgroundGradientStartDark,
      backgroundGradientMiddle: AppColors.homeBackgroundGradientMiddleDark,
      backgroundGradientEnd: AppColors.homeBackgroundGradientEndDark,
      backgroundGlowColor: AppColors.homeBackgroundGlowDark,
      backgroundGlowOpacity: 0.28,
      homePrayerHeroBackground: AppColors.homePrayerHeroBackgroundDark,
      homePrayerHeroBorder: AppColors.homePrayerHeroBorderDark,
      homePrayerHeroShadow: AppColors.homePrayerHeroShadowDark,
      homePrayerHeroShadowOpacity: 0,
      homePrayerHeroAccent: AppColors.homePrayerHeroAccentDark,
      homePrayerHeroWatermark: AppColors.homePrayerHeroWatermarkDark,
      homePrayerHeroWatermarkOpacity: 0.06,
      homeHeaderChipBackground: AppColors.homeHeaderChipBackgroundDark,
      homeHeaderSecondaryText: AppColors.homeHeaderSecondaryTextDark,
      homeCollapsedHeaderFill: AppColors.homeCollapsedHeaderFillDark,
      homeCollapsedHeaderBorder: AppColors.homeCollapsedHeaderBorderDark,
      homeCollapsedHeaderShadowOpacity: 0,
      homeFeaturedTutorGradientStart:
          AppColors.homeFeaturedTutorGradientStartDark,
      homeFeaturedTutorGradientEnd: AppColors.homeFeaturedTutorGradientEndDark,
      homeFeaturedTutorAccent: AppColors.homeFeaturedTutorAccentDark,
      homeContentSheetSurface: AppColors.homeContentSheetSurfaceDark,
      homeContentSheetShadowOpacity: 0,
      homeContentSheetTopBorder: AppColors.homeContentSheetTopBorderDark,
      homeHeroPatternInk: AppColors.homeHeroPatternInkDark,
      homeHeroPatternOpacity: 0.04,
      homeHeroGoldGlowOpacity: 0.10,
      homeFeaturedTutorCtaForeground:
          AppColors.homeFeaturedTutorCtaForegroundDark,
      quickActionTileBackground: AppColors.homeQuickActionTileBackgroundDark,
    );
  }

  TilawaHomeScreenTokens copyWith({
    Color? backgroundGradientStart,
    Color? backgroundGradientMiddle,
    Color? backgroundGradientEnd,
    Color? backgroundGlowColor,
    double? backgroundGlowOpacity,
    Color? homePrayerHeroBackground,
    Color? homePrayerHeroBorder,
    Color? homePrayerHeroShadow,
    double? homePrayerHeroShadowOpacity,
    Color? homePrayerHeroAccent,
    Color? homePrayerHeroWatermark,
    double? homePrayerHeroWatermarkOpacity,
    Color? homeHeaderChipBackground,
    Color? homeHeaderSecondaryText,
    Color? homeCollapsedHeaderFill,
    Color? homeCollapsedHeaderBorder,
    double? homeCollapsedHeaderShadowOpacity,
    Color? homeFeaturedTutorGradientStart,
    Color? homeFeaturedTutorGradientEnd,
    Color? homeFeaturedTutorAccent,
    Color? homeContentSheetSurface,
    double? homeContentSheetShadowOpacity,
    Color? homeContentSheetTopBorder,
    Color? homeHeroPatternInk,
    double? homeHeroPatternOpacity,
    double? homeHeroGoldGlowOpacity,
    Color? homeFeaturedTutorCtaForeground,
    Color? quickActionTileBackground,
  }) {
    return TilawaHomeScreenTokens(
      backgroundGradientStart:
          backgroundGradientStart ?? this.backgroundGradientStart,
      backgroundGradientMiddle:
          backgroundGradientMiddle ?? this.backgroundGradientMiddle,
      backgroundGradientEnd:
          backgroundGradientEnd ?? this.backgroundGradientEnd,
      backgroundGlowColor: backgroundGlowColor ?? this.backgroundGlowColor,
      backgroundGlowOpacity:
          backgroundGlowOpacity ?? this.backgroundGlowOpacity,
      homePrayerHeroBackground:
          homePrayerHeroBackground ?? this.homePrayerHeroBackground,
      homePrayerHeroBorder: homePrayerHeroBorder ?? this.homePrayerHeroBorder,
      homePrayerHeroShadow: homePrayerHeroShadow ?? this.homePrayerHeroShadow,
      homePrayerHeroShadowOpacity:
          homePrayerHeroShadowOpacity ?? this.homePrayerHeroShadowOpacity,
      homePrayerHeroAccent: homePrayerHeroAccent ?? this.homePrayerHeroAccent,
      homePrayerHeroWatermark:
          homePrayerHeroWatermark ?? this.homePrayerHeroWatermark,
      homePrayerHeroWatermarkOpacity:
          homePrayerHeroWatermarkOpacity ?? this.homePrayerHeroWatermarkOpacity,
      homeHeaderChipBackground:
          homeHeaderChipBackground ?? this.homeHeaderChipBackground,
      homeHeaderSecondaryText:
          homeHeaderSecondaryText ?? this.homeHeaderSecondaryText,
      homeCollapsedHeaderFill:
          homeCollapsedHeaderFill ?? this.homeCollapsedHeaderFill,
      homeCollapsedHeaderBorder:
          homeCollapsedHeaderBorder ?? this.homeCollapsedHeaderBorder,
      homeCollapsedHeaderShadowOpacity:
          homeCollapsedHeaderShadowOpacity ??
          this.homeCollapsedHeaderShadowOpacity,
      homeFeaturedTutorGradientStart:
          homeFeaturedTutorGradientStart ?? this.homeFeaturedTutorGradientStart,
      homeFeaturedTutorGradientEnd:
          homeFeaturedTutorGradientEnd ?? this.homeFeaturedTutorGradientEnd,
      homeFeaturedTutorAccent:
          homeFeaturedTutorAccent ?? this.homeFeaturedTutorAccent,
      homeContentSheetSurface:
          homeContentSheetSurface ?? this.homeContentSheetSurface,
      homeContentSheetShadowOpacity:
          homeContentSheetShadowOpacity ?? this.homeContentSheetShadowOpacity,
      homeContentSheetTopBorder:
          homeContentSheetTopBorder ?? this.homeContentSheetTopBorder,
      homeHeroPatternInk: homeHeroPatternInk ?? this.homeHeroPatternInk,
      homeHeroPatternOpacity:
          homeHeroPatternOpacity ?? this.homeHeroPatternOpacity,
      homeHeroGoldGlowOpacity:
          homeHeroGoldGlowOpacity ?? this.homeHeroGoldGlowOpacity,
      homeFeaturedTutorCtaForeground:
          homeFeaturedTutorCtaForeground ?? this.homeFeaturedTutorCtaForeground,
      quickActionTileBackground:
          quickActionTileBackground ?? this.quickActionTileBackground,
    );
  }

  static TilawaHomeScreenTokens lerp(
    TilawaHomeScreenTokens a,
    TilawaHomeScreenTokens b,
    double t,
  ) {
    return TilawaHomeScreenTokens(
      backgroundGradientStart: Color.lerp(
        a.backgroundGradientStart,
        b.backgroundGradientStart,
        t,
      )!,
      backgroundGradientMiddle: Color.lerp(
        a.backgroundGradientMiddle,
        b.backgroundGradientMiddle,
        t,
      )!,
      backgroundGradientEnd: Color.lerp(
        a.backgroundGradientEnd,
        b.backgroundGradientEnd,
        t,
      )!,
      backgroundGlowColor: Color.lerp(
        a.backgroundGlowColor,
        b.backgroundGlowColor,
        t,
      )!,
      backgroundGlowOpacity: lerpTokenDouble(
        a.backgroundGlowOpacity,
        b.backgroundGlowOpacity,
        t,
      ),
      homePrayerHeroBackground: Color.lerp(
        a.homePrayerHeroBackground,
        b.homePrayerHeroBackground,
        t,
      )!,
      homePrayerHeroBorder: Color.lerp(
        a.homePrayerHeroBorder,
        b.homePrayerHeroBorder,
        t,
      )!,
      homePrayerHeroShadow: Color.lerp(
        a.homePrayerHeroShadow,
        b.homePrayerHeroShadow,
        t,
      )!,
      homePrayerHeroShadowOpacity: lerpTokenDouble(
        a.homePrayerHeroShadowOpacity,
        b.homePrayerHeroShadowOpacity,
        t,
      ),
      homePrayerHeroAccent: Color.lerp(
        a.homePrayerHeroAccent,
        b.homePrayerHeroAccent,
        t,
      )!,
      homePrayerHeroWatermark: Color.lerp(
        a.homePrayerHeroWatermark,
        b.homePrayerHeroWatermark,
        t,
      )!,
      homePrayerHeroWatermarkOpacity: lerpTokenDouble(
        a.homePrayerHeroWatermarkOpacity,
        b.homePrayerHeroWatermarkOpacity,
        t,
      ),
      homeHeaderChipBackground: Color.lerp(
        a.homeHeaderChipBackground,
        b.homeHeaderChipBackground,
        t,
      )!,
      homeHeaderSecondaryText: Color.lerp(
        a.homeHeaderSecondaryText,
        b.homeHeaderSecondaryText,
        t,
      )!,
      homeCollapsedHeaderFill: Color.lerp(
        a.homeCollapsedHeaderFill,
        b.homeCollapsedHeaderFill,
        t,
      )!,
      homeCollapsedHeaderBorder: Color.lerp(
        a.homeCollapsedHeaderBorder,
        b.homeCollapsedHeaderBorder,
        t,
      )!,
      homeCollapsedHeaderShadowOpacity: lerpTokenDouble(
        a.homeCollapsedHeaderShadowOpacity,
        b.homeCollapsedHeaderShadowOpacity,
        t,
      ),
      homeFeaturedTutorGradientStart: Color.lerp(
        a.homeFeaturedTutorGradientStart,
        b.homeFeaturedTutorGradientStart,
        t,
      )!,
      homeFeaturedTutorGradientEnd: Color.lerp(
        a.homeFeaturedTutorGradientEnd,
        b.homeFeaturedTutorGradientEnd,
        t,
      )!,
      homeFeaturedTutorAccent: Color.lerp(
        a.homeFeaturedTutorAccent,
        b.homeFeaturedTutorAccent,
        t,
      )!,
      homeContentSheetSurface: Color.lerp(
        a.homeContentSheetSurface,
        b.homeContentSheetSurface,
        t,
      )!,
      homeContentSheetShadowOpacity: lerpTokenDouble(
        a.homeContentSheetShadowOpacity,
        b.homeContentSheetShadowOpacity,
        t,
      ),
      homeContentSheetTopBorder: Color.lerp(
        a.homeContentSheetTopBorder,
        b.homeContentSheetTopBorder,
        t,
      )!,
      homeHeroPatternInk: Color.lerp(
        a.homeHeroPatternInk,
        b.homeHeroPatternInk,
        t,
      )!,
      homeHeroPatternOpacity: lerpTokenDouble(
        a.homeHeroPatternOpacity,
        b.homeHeroPatternOpacity,
        t,
      ),
      homeHeroGoldGlowOpacity: lerpTokenDouble(
        a.homeHeroGoldGlowOpacity,
        b.homeHeroGoldGlowOpacity,
        t,
      ),
      homeFeaturedTutorCtaForeground: Color.lerp(
        a.homeFeaturedTutorCtaForeground,
        b.homeFeaturedTutorCtaForeground,
        t,
      )!,
      quickActionTileBackground: Color.lerp(
        a.quickActionTileBackground,
        b.quickActionTileBackground,
        t,
      )!,
    );
  }
}

/// Home dashboard card surface — a soft [ColorScheme.primaryContainer] wash so
/// Token-backed featured dashboard cards (Last Read, resume hubs).
///
/// Uses Tilawa warm brand surfaces for featured Home dashboard cards.
@immutable
class TilawaHomeDashboardCardTokens {
  const TilawaHomeDashboardCardTokens({
    required this.gradientStart,
    required this.gradientEnd,
    required this.foregroundColor,
    required this.splashColor,
    required this.highlightColor,
    required this.travelSheetSurface,
    required this.travelSearchFieldFill,
    required this.travelSectionLinkColor,
    required this.travelDestinationIconColor,
    required this.travelDestinationHeaderTints,
    required this.headerWaveAmplitude,
    required this.featureCategoryTileTints,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color foregroundColor;
  final Color splashColor;
  final Color highlightColor;

  /// White sheet panel overlapping the hero gradient.
  final Color travelSheetSurface;

  /// Warm rest fill for the read-only Home search field.
  final Color travelSearchFieldFill;

  /// Accent for section header links (See all).
  final Color travelSectionLinkColor;

  /// Icons on discover / carousel destination header bands.
  final Color travelDestinationIconColor;

  /// Warm tints for travel-style destination card headers.
  final List<Color> travelDestinationHeaderTints;

  /// Scallop height for the Home hero-to-sheet wave transition.
  final double headerWaveAmplitude;

  /// Beige tile fills for the Home feature category grid.
  final List<Color> featureCategoryTileTints;

  Color destinationHeaderTint(int index) {
    if (travelDestinationHeaderTints.isEmpty) {
      return travelSearchFieldFill;
    }
    return travelDestinationHeaderTints[index.abs() %
        travelDestinationHeaderTints.length];
  }

  Color featureCategoryTileTint(int index) {
    if (featureCategoryTileTints.isEmpty) {
      return travelSearchFieldFill;
    }
    return featureCategoryTileTints[index.abs() %
        featureCategoryTileTints.length];
  }

  factory TilawaHomeDashboardCardTokens.fromColorScheme() {
    return TilawaHomeDashboardCardTokens(
      gradientStart: AppColors.featuredGradientStart,
      gradientEnd: AppColors.featuredGradientEnd,
      foregroundColor: AppColors.featuredGradientForeground,
      splashColor: AppColors.defaultPrimary.withValues(alpha: 0.08),
      highlightColor: AppColors.defaultPrimary.withValues(alpha: 0.04),
      travelSheetSurface: AppColors.homeTravelSheetSurface,
      travelSearchFieldFill: AppColors.homeTravelSearchFill,
      travelSectionLinkColor: AppColors.homeTravelSectionLink,
      travelDestinationIconColor: AppColors.homeTravelDestinationIcon,
      travelDestinationHeaderTints: AppColors.homeTravelDestinationHeaderTints,
      headerWaveAmplitude: 14,
      featureCategoryTileTints: AppColors.homeFeatureCategoryTileTints,
    );
  }

  TilawaHomeDashboardCardTokens copyWith({
    Color? gradientStart,
    Color? gradientEnd,
    Color? foregroundColor,
    Color? splashColor,
    Color? highlightColor,
    Color? travelSheetSurface,
    Color? travelSearchFieldFill,
    Color? travelSectionLinkColor,
    Color? travelDestinationIconColor,
    List<Color>? travelDestinationHeaderTints,
    double? headerWaveAmplitude,
    List<Color>? featureCategoryTileTints,
  }) {
    return TilawaHomeDashboardCardTokens(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      splashColor: splashColor ?? this.splashColor,
      highlightColor: highlightColor ?? this.highlightColor,
      travelSheetSurface: travelSheetSurface ?? this.travelSheetSurface,
      travelSearchFieldFill:
          travelSearchFieldFill ?? this.travelSearchFieldFill,
      travelSectionLinkColor:
          travelSectionLinkColor ?? this.travelSectionLinkColor,
      travelDestinationIconColor:
          travelDestinationIconColor ?? this.travelDestinationIconColor,
      travelDestinationHeaderTints:
          travelDestinationHeaderTints ?? this.travelDestinationHeaderTints,
      headerWaveAmplitude: headerWaveAmplitude ?? this.headerWaveAmplitude,
      featureCategoryTileTints:
          featureCategoryTileTints ?? this.featureCategoryTileTints,
    );
  }

  static TilawaHomeDashboardCardTokens lerp(
    TilawaHomeDashboardCardTokens a,
    TilawaHomeDashboardCardTokens b,
    double t,
  ) {
    return TilawaHomeDashboardCardTokens(
      gradientStart: Color.lerp(a.gradientStart, b.gradientStart, t)!,
      gradientEnd: Color.lerp(a.gradientEnd, b.gradientEnd, t)!,
      foregroundColor: Color.lerp(a.foregroundColor, b.foregroundColor, t)!,
      splashColor: Color.lerp(a.splashColor, b.splashColor, t)!,
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t)!,
      travelSheetSurface: Color.lerp(
        a.travelSheetSurface,
        b.travelSheetSurface,
        t,
      )!,
      travelSearchFieldFill: Color.lerp(
        a.travelSearchFieldFill,
        b.travelSearchFieldFill,
        t,
      )!,
      travelSectionLinkColor: Color.lerp(
        a.travelSectionLinkColor,
        b.travelSectionLinkColor,
        t,
      )!,
      travelDestinationIconColor: Color.lerp(
        a.travelDestinationIconColor,
        b.travelDestinationIconColor,
        t,
      )!,
      travelDestinationHeaderTints: a.travelDestinationHeaderTints,
      headerWaveAmplitude: lerpTokenDouble(
        a.headerWaveAmplitude,
        b.headerWaveAmplitude,
        t,
      ),
      featureCategoryTileTints: a.featureCategoryTileTints,
    );
  }
}

/// Token-backed surface for [TilawaCapabilityActionCard].
///
/// Subtle brand wash — not the featured gold dashboard gradient.
@immutable
class TilawaCapabilityActionCardTokens {
  const TilawaCapabilityActionCardTokens({
    required this.gradientStart,
    required this.gradientEnd,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.splashColor,
    required this.highlightColor,
    required this.contentPadding,
    required this.outerPadding,
    required this.leadingIconSize,
    required this.trailingIconSize,
    required this.trailingIconOpacity,
    required this.titleSubtitleSpacing,
    required this.badgeTopSpacing,
    required this.rowGap,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color splashColor;
  final Color highlightColor;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry outerPadding;
  final double leadingIconSize;
  final double trailingIconSize;
  final double trailingIconOpacity;
  final double titleSubtitleSpacing;
  final double badgeTopSpacing;
  final double rowGap;

  factory TilawaCapabilityActionCardTokens.fromColorScheme(
    ColorScheme colorScheme,
  ) {
    const double gradientPrimaryAlpha = 0.10;
    const double gradientSecondaryAlpha = 0.14;
    const double borderAlpha = 0.12;

    return TilawaCapabilityActionCardTokens(
      gradientStart: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: gradientPrimaryAlpha),
        colorScheme.surface,
      ),
      gradientEnd: Color.alphaBlend(
        colorScheme.secondary.withValues(alpha: gradientSecondaryAlpha),
        colorScheme.surfaceContainerLow,
      ),
      borderColor: colorScheme.outlineVariant.withValues(alpha: borderAlpha),
      titleColor: colorScheme.onSurface,
      subtitleColor: colorScheme.onSurfaceVariant,
      splashColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: colorScheme.onSurface.withValues(alpha: 0.04),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 20, 16, 20),
      outerPadding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
      leadingIconSize: 24,
      trailingIconSize: 20,
      trailingIconOpacity: 0.62,
      titleSubtitleSpacing: 6,
      badgeTopSpacing: 10,
      rowGap: 14,
    );
  }

  LinearGradient backgroundGradient({
    AlignmentGeometry begin = AlignmentDirectional.topStart,
    AlignmentGeometry end = AlignmentDirectional.bottomEnd,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: <Color>[gradientStart, gradientEnd],
    );
  }

  TilawaCapabilityActionCardTokens copyWith({
    Color? gradientStart,
    Color? gradientEnd,
    Color? borderColor,
    Color? titleColor,
    Color? subtitleColor,
    Color? splashColor,
    Color? highlightColor,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? outerPadding,
    double? leadingIconSize,
    double? trailingIconSize,
    double? trailingIconOpacity,
    double? titleSubtitleSpacing,
    double? badgeTopSpacing,
    double? rowGap,
  }) {
    return TilawaCapabilityActionCardTokens(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      borderColor: borderColor ?? this.borderColor,
      titleColor: titleColor ?? this.titleColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      splashColor: splashColor ?? this.splashColor,
      highlightColor: highlightColor ?? this.highlightColor,
      contentPadding: contentPadding ?? this.contentPadding,
      outerPadding: outerPadding ?? this.outerPadding,
      leadingIconSize: leadingIconSize ?? this.leadingIconSize,
      trailingIconSize: trailingIconSize ?? this.trailingIconSize,
      trailingIconOpacity: trailingIconOpacity ?? this.trailingIconOpacity,
      titleSubtitleSpacing: titleSubtitleSpacing ?? this.titleSubtitleSpacing,
      badgeTopSpacing: badgeTopSpacing ?? this.badgeTopSpacing,
      rowGap: rowGap ?? this.rowGap,
    );
  }

  static TilawaCapabilityActionCardTokens lerp(
    TilawaCapabilityActionCardTokens a,
    TilawaCapabilityActionCardTokens b,
    double t,
  ) {
    return TilawaCapabilityActionCardTokens(
      gradientStart: Color.lerp(a.gradientStart, b.gradientStart, t)!,
      gradientEnd: Color.lerp(a.gradientEnd, b.gradientEnd, t)!,
      borderColor: Color.lerp(a.borderColor, b.borderColor, t)!,
      titleColor: Color.lerp(a.titleColor, b.titleColor, t)!,
      subtitleColor: Color.lerp(a.subtitleColor, b.subtitleColor, t)!,
      splashColor: Color.lerp(a.splashColor, b.splashColor, t)!,
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t)!,
      contentPadding: EdgeInsetsGeometry.lerp(
        a.contentPadding,
        b.contentPadding,
        t,
      )!,
      outerPadding: EdgeInsetsGeometry.lerp(
        a.outerPadding,
        b.outerPadding,
        t,
      )!,
      leadingIconSize: lerpTokenDouble(
        a.leadingIconSize,
        b.leadingIconSize,
        t,
      ),
      trailingIconSize: lerpTokenDouble(
        a.trailingIconSize,
        b.trailingIconSize,
        t,
      ),
      trailingIconOpacity: lerpTokenDouble(
        a.trailingIconOpacity,
        b.trailingIconOpacity,
        t,
      ),
      titleSubtitleSpacing: lerpTokenDouble(
        a.titleSubtitleSpacing,
        b.titleSubtitleSpacing,
        t,
      ),
      badgeTopSpacing: lerpTokenDouble(
        a.badgeTopSpacing,
        b.badgeTopSpacing,
        t,
      ),
      rowGap: lerpTokenDouble(a.rowGap, b.rowGap, t),
    );
  }
}

/// Component tokens for [TilawaExperimentalBadge].
///
/// Colors are derived from the caution semantic tint (warning hue) at reduced
/// opacity so the badge reads as informational rather than urgent.
@immutable
class TilawaExperimentalBadgeTokens {
  const TilawaExperimentalBadgeTokens({
    required this.padding,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.iconSize,
    required this.iconGap,
    required this.fontWeight,
    required this.letterSpacing,
  });

  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double borderWidth;
  final double iconSize;
  final double iconGap;
  final FontWeight fontWeight;
  final double letterSpacing;

  factory TilawaExperimentalBadgeTokens.fromColorScheme(
    ColorScheme colorScheme,
  ) {
    final warning = colorScheme.warning;
    return TilawaExperimentalBadgeTokens(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      backgroundColor: Color.alphaBlend(
        warning.withValues(alpha: 0.14),
        colorScheme.surface,
      ),
      foregroundColor: warning,
      borderColor: warning.withValues(alpha: 0.28),
      borderWidth: 0.5,
      iconSize: 12,
      iconGap: 4,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
  }

  TilawaExperimentalBadgeTokens copyWith({
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    double? iconSize,
    double? iconGap,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    return TilawaExperimentalBadgeTokens(
      padding: padding ?? this.padding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      iconSize: iconSize ?? this.iconSize,
      iconGap: iconGap ?? this.iconGap,
      fontWeight: fontWeight ?? this.fontWeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  static TilawaExperimentalBadgeTokens lerp(
    TilawaExperimentalBadgeTokens a,
    TilawaExperimentalBadgeTokens b,
    double t,
  ) {
    return TilawaExperimentalBadgeTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      foregroundColor: Color.lerp(a.foregroundColor, b.foregroundColor, t)!,
      borderColor: Color.lerp(a.borderColor, b.borderColor, t)!,
      borderWidth: lerpTokenDouble(a.borderWidth, b.borderWidth, t),
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      iconGap: lerpTokenDouble(a.iconGap, b.iconGap, t),
      fontWeight: FontWeight.lerp(a.fontWeight, b.fontWeight, t)!,
      letterSpacing: lerpTokenDouble(a.letterSpacing, b.letterSpacing, t),
    );
  }
}

/// Component tokens for [TilawaCupertinoWheelPicker] and
/// [TilawaPickerSegmentCard].
@immutable
class TilawaCupertinoWheelPickerTokens {
  const TilawaCupertinoWheelPickerTokens({
    required this.pickerHeight,
    required this.segmentGap,
    required this.segmentPadding,
    required this.segmentBorderRadius,
    required this.segmentSelectedBorderWidth,
    required this.segmentSelectedBackgroundColor,
    required this.segmentUnselectedBackgroundColor,
    required this.segmentSelectedBorderColor,
    required this.segmentUnselectedBorderColor,
    required this.segmentLabelColor,
    required this.segmentSelectedValueColor,
    required this.segmentUnselectedValueColor,
    required this.segmentLabelValueGap,
    required this.selectionOverlayColor,
    required this.selectionOverlayRadius,
    required this.selectionOverlayHorizontalMargin,
    required this.wheelTopSpacing,
    required this.pickerBackgroundColor,
  });

  final double pickerHeight;
  final double segmentGap;
  final EdgeInsetsGeometry segmentPadding;
  final double segmentBorderRadius;
  final double segmentSelectedBorderWidth;
  final Color segmentSelectedBackgroundColor;
  final Color segmentUnselectedBackgroundColor;
  final Color segmentSelectedBorderColor;
  final Color segmentUnselectedBorderColor;
  final Color segmentLabelColor;
  final Color segmentSelectedValueColor;
  final Color segmentUnselectedValueColor;
  final double segmentLabelValueGap;
  final Color selectionOverlayColor;
  final double selectionOverlayRadius;
  final double selectionOverlayHorizontalMargin;
  final double wheelTopSpacing;
  final Color pickerBackgroundColor;

  factory TilawaCupertinoWheelPickerTokens.fromColorScheme(
    ColorScheme colorScheme,
  ) {
    final design = colorScheme.brightness == Brightness.dark
        ? MeMuslimDesignTokens.dark()
        : MeMuslimDesignTokens.light();
    return TilawaCupertinoWheelPickerTokens(
      pickerHeight: 200,
      segmentGap: design.spaceSmall,
      segmentPadding: EdgeInsets.symmetric(
        vertical: design.spaceMedium,
        horizontal: design.spaceMedium,
      ),
      segmentBorderRadius: design.radiusLarge,
      segmentSelectedBorderWidth: 1.5,
      segmentSelectedBackgroundColor: colorScheme.primaryContainer,
      segmentUnselectedBackgroundColor: colorScheme.surfaceContainerHighest,
      segmentSelectedBorderColor: colorScheme.primary,
      segmentUnselectedBorderColor: colorScheme.primary.withValues(alpha: 0),
      segmentLabelColor: colorScheme.onSurfaceVariant,
      segmentSelectedValueColor: colorScheme.primary,
      segmentUnselectedValueColor: colorScheme.onSurface,
      segmentLabelValueGap: design.spaceTiny,
      selectionOverlayColor: colorScheme.onSurface.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.14 : 0.08,
      ),
      selectionOverlayRadius: design.radiusMedium,
      selectionOverlayHorizontalMargin: design.spaceSmall,
      wheelTopSpacing: design.spaceSmall,
      pickerBackgroundColor: colorScheme.surface,
    );
  }

  TilawaCupertinoWheelPickerTokens copyWith({
    double? pickerHeight,
    double? segmentGap,
    EdgeInsetsGeometry? segmentPadding,
    double? segmentBorderRadius,
    double? segmentSelectedBorderWidth,
    Color? segmentSelectedBackgroundColor,
    Color? segmentUnselectedBackgroundColor,
    Color? segmentSelectedBorderColor,
    Color? segmentUnselectedBorderColor,
    Color? segmentLabelColor,
    Color? segmentSelectedValueColor,
    Color? segmentUnselectedValueColor,
    double? segmentLabelValueGap,
    Color? selectionOverlayColor,
    double? selectionOverlayRadius,
    double? selectionOverlayHorizontalMargin,
    double? wheelTopSpacing,
    Color? pickerBackgroundColor,
  }) {
    return TilawaCupertinoWheelPickerTokens(
      pickerHeight: pickerHeight ?? this.pickerHeight,
      segmentGap: segmentGap ?? this.segmentGap,
      segmentPadding: segmentPadding ?? this.segmentPadding,
      segmentBorderRadius: segmentBorderRadius ?? this.segmentBorderRadius,
      segmentSelectedBorderWidth:
          segmentSelectedBorderWidth ?? this.segmentSelectedBorderWidth,
      segmentSelectedBackgroundColor:
          segmentSelectedBackgroundColor ?? this.segmentSelectedBackgroundColor,
      segmentUnselectedBackgroundColor:
          segmentUnselectedBackgroundColor ??
          this.segmentUnselectedBackgroundColor,
      segmentSelectedBorderColor:
          segmentSelectedBorderColor ?? this.segmentSelectedBorderColor,
      segmentUnselectedBorderColor:
          segmentUnselectedBorderColor ?? this.segmentUnselectedBorderColor,
      segmentLabelColor: segmentLabelColor ?? this.segmentLabelColor,
      segmentSelectedValueColor:
          segmentSelectedValueColor ?? this.segmentSelectedValueColor,
      segmentUnselectedValueColor:
          segmentUnselectedValueColor ?? this.segmentUnselectedValueColor,
      segmentLabelValueGap: segmentLabelValueGap ?? this.segmentLabelValueGap,
      selectionOverlayColor:
          selectionOverlayColor ?? this.selectionOverlayColor,
      selectionOverlayRadius:
          selectionOverlayRadius ?? this.selectionOverlayRadius,
      selectionOverlayHorizontalMargin:
          selectionOverlayHorizontalMargin ??
          this.selectionOverlayHorizontalMargin,
      wheelTopSpacing: wheelTopSpacing ?? this.wheelTopSpacing,
      pickerBackgroundColor:
          pickerBackgroundColor ?? this.pickerBackgroundColor,
    );
  }

  static TilawaCupertinoWheelPickerTokens lerp(
    TilawaCupertinoWheelPickerTokens a,
    TilawaCupertinoWheelPickerTokens b,
    double t,
  ) {
    return TilawaCupertinoWheelPickerTokens(
      pickerHeight: lerpTokenDouble(a.pickerHeight, b.pickerHeight, t),
      segmentGap: lerpTokenDouble(a.segmentGap, b.segmentGap, t),
      segmentPadding: EdgeInsetsGeometry.lerp(
        a.segmentPadding,
        b.segmentPadding,
        t,
      )!,
      segmentBorderRadius: lerpTokenDouble(
        a.segmentBorderRadius,
        b.segmentBorderRadius,
        t,
      ),
      segmentSelectedBorderWidth: lerpTokenDouble(
        a.segmentSelectedBorderWidth,
        b.segmentSelectedBorderWidth,
        t,
      ),
      segmentSelectedBackgroundColor: Color.lerp(
        a.segmentSelectedBackgroundColor,
        b.segmentSelectedBackgroundColor,
        t,
      )!,
      segmentUnselectedBackgroundColor: Color.lerp(
        a.segmentUnselectedBackgroundColor,
        b.segmentUnselectedBackgroundColor,
        t,
      )!,
      segmentSelectedBorderColor: Color.lerp(
        a.segmentSelectedBorderColor,
        b.segmentSelectedBorderColor,
        t,
      )!,
      segmentUnselectedBorderColor: Color.lerp(
        a.segmentUnselectedBorderColor,
        b.segmentUnselectedBorderColor,
        t,
      )!,
      segmentLabelColor: Color.lerp(
        a.segmentLabelColor,
        b.segmentLabelColor,
        t,
      )!,
      segmentSelectedValueColor: Color.lerp(
        a.segmentSelectedValueColor,
        b.segmentSelectedValueColor,
        t,
      )!,
      segmentUnselectedValueColor: Color.lerp(
        a.segmentUnselectedValueColor,
        b.segmentUnselectedValueColor,
        t,
      )!,
      segmentLabelValueGap: lerpTokenDouble(
        a.segmentLabelValueGap,
        b.segmentLabelValueGap,
        t,
      ),
      selectionOverlayColor: Color.lerp(
        a.selectionOverlayColor,
        b.selectionOverlayColor,
        t,
      )!,
      selectionOverlayRadius: lerpTokenDouble(
        a.selectionOverlayRadius,
        b.selectionOverlayRadius,
        t,
      ),
      selectionOverlayHorizontalMargin: lerpTokenDouble(
        a.selectionOverlayHorizontalMargin,
        b.selectionOverlayHorizontalMargin,
        t,
      ),
      wheelTopSpacing: lerpTokenDouble(a.wheelTopSpacing, b.wheelTopSpacing, t),
      pickerBackgroundColor: Color.lerp(
        a.pickerBackgroundColor,
        b.pickerBackgroundColor,
        t,
      )!,
    );
  }
}

/// Component tokens for [TilawaMetricTile].
///
/// Read-only metric tiles read as a *quiet* summary strip, not as a grid of
/// tappable cards. They keep a flat tonal fill, a hairline outline, and no
/// shadow — distinct from the raised, tap-affording [TilawaCard] used for
/// dashboard action/category cards below them.
@immutable
class TilawaMetricTileTokens {
  const TilawaMetricTileTokens({
    required this.padding,
    required this.iconSize,
    required this.valueToIconSpacing,
    required this.valueToLabelSpacing,
    required this.labelToHelperSpacing,
    required this.borderOpacity,
    required this.fillColor,
    required this.borderColor,
    required this.helperColorOpacity,
    required this.valueTextRole,
    required this.labelTextRole,
    required this.helperTextRole,
    required this.valueFontWeight,
    required this.valueLineHeight,
  });

  /// Tile inner padding.
  final EdgeInsetsGeometry padding;

  /// Leading icon glyph size (plain variant — no fill box).
  final double iconSize;

  /// Gap between the leading icon column and the value/label column.
  final double valueToIconSpacing;

  /// Gap between the value and the label.
  final double valueToLabelSpacing;

  /// Gap between the label and the optional helper/trend line.
  final double labelToHelperSpacing;

  /// Outline alpha on [ColorScheme.outlineVariant].
  final double borderOpacity;

  /// Quiet tonal fill. Default is [ColorScheme.surfaceContainerLow] so the
  /// strip recedes behind the raised category cards below it.
  final Color fillColor;

  /// Outline colour (before [borderOpacity] is applied).
  final Color borderColor;

  /// Alpha applied to [ColorScheme.onSurfaceVariant] for the helper line.
  final double helperColorOpacity;

  final TilawaTextRole valueTextRole;
  final TilawaTextRole labelTextRole;
  final TilawaTextRole helperTextRole;

  final FontWeight valueFontWeight;
  final double valueLineHeight;

  factory TilawaMetricTileTokens.defaults() {
    return TilawaMetricTileTokens.fromColorScheme(
      ColorScheme.fromSeed(seedColor: AppColors.defaultPrimary),
    );
  }

  factory TilawaMetricTileTokens.fromColorScheme(ColorScheme colorScheme) {
    final tokens = colorScheme.brightness == Brightness.dark
        ? MeMuslimDesignTokens.dark()
        : MeMuslimDesignTokens.light();
    return TilawaMetricTileTokens(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      iconSize: 16,
      valueToIconSpacing: tokens.spaceExtraSmall,
      valueToLabelSpacing: tokens.spaceExtraSmall,
      labelToHelperSpacing: 2,
      borderOpacity: 0.0,
      fillColor: colorScheme.surface,
      borderColor: Colors.transparent,
      helperColorOpacity: 0.72,
      valueTextRole: TilawaTextRole.headlineSmall,
      labelTextRole: TilawaTextRole.labelMedium,
      helperTextRole: TilawaTextRole.labelSmall,
      valueFontWeight: FontWeight.w700,
      valueLineHeight: 1.05,
    );
  }

  TilawaMetricTileTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? iconSize,
    double? valueToIconSpacing,
    double? valueToLabelSpacing,
    double? labelToHelperSpacing,
    double? borderOpacity,
    Color? fillColor,
    Color? borderColor,
    double? helperColorOpacity,
    TilawaTextRole? valueTextRole,
    TilawaTextRole? labelTextRole,
    TilawaTextRole? helperTextRole,
    FontWeight? valueFontWeight,
    double? valueLineHeight,
  }) {
    return TilawaMetricTileTokens(
      padding: padding ?? this.padding,
      iconSize: iconSize ?? this.iconSize,
      valueToIconSpacing: valueToIconSpacing ?? this.valueToIconSpacing,
      valueToLabelSpacing: valueToLabelSpacing ?? this.valueToLabelSpacing,
      labelToHelperSpacing: labelToHelperSpacing ?? this.labelToHelperSpacing,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      helperColorOpacity: helperColorOpacity ?? this.helperColorOpacity,
      valueTextRole: valueTextRole ?? this.valueTextRole,
      labelTextRole: labelTextRole ?? this.labelTextRole,
      helperTextRole: helperTextRole ?? this.helperTextRole,
      valueFontWeight: valueFontWeight ?? this.valueFontWeight,
      valueLineHeight: valueLineHeight ?? this.valueLineHeight,
    );
  }

  static TilawaMetricTileTokens lerp(
    TilawaMetricTileTokens a,
    TilawaMetricTileTokens b,
    double t,
  ) {
    return TilawaMetricTileTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      valueToIconSpacing: lerpTokenDouble(
        a.valueToIconSpacing,
        b.valueToIconSpacing,
        t,
      ),
      valueToLabelSpacing: lerpTokenDouble(
        a.valueToLabelSpacing,
        b.valueToLabelSpacing,
        t,
      ),
      labelToHelperSpacing: lerpTokenDouble(
        a.labelToHelperSpacing,
        b.labelToHelperSpacing,
        t,
      ),
      borderOpacity: lerpTokenDouble(a.borderOpacity, b.borderOpacity, t),
      fillColor: Color.lerp(a.fillColor, b.fillColor, t)!,
      borderColor: Color.lerp(a.borderColor, b.borderColor, t)!,
      helperColorOpacity: lerpTokenDouble(
        a.helperColorOpacity,
        b.helperColorOpacity,
        t,
      ),
      valueTextRole: lerpTilawaTextRole(a.valueTextRole, b.valueTextRole, t),
      labelTextRole: lerpTilawaTextRole(a.labelTextRole, b.labelTextRole, t),
      helperTextRole: lerpTilawaTextRole(
        a.helperTextRole,
        b.helperTextRole,
        t,
      ),
      valueFontWeight: FontWeight.lerp(
        a.valueFontWeight,
        b.valueFontWeight,
        t,
      )!,
      valueLineHeight: lerpTokenDouble(a.valueLineHeight, b.valueLineHeight, t),
    );
  }
}
