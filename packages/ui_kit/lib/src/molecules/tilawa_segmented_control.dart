import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interaction_feedback.dart';
import '../foundation/tilawa_interactive_surface.dart';
import '../foundation/tilawa_type_scale.dart';

/// A segmented control widget for switching between a small number of options.
///
/// Similar to iOS UISegmentedControl or Material ToggleButtons, but styled
/// consistently with the Tilawa design system. Use for 2-5 options where
/// only one can be selected at a time.
///
/// For section tabs tied to a [TabController] / [TabBarView], use
/// [TilawaTabBar] instead. Do not use Material [SegmentedButton] in product
/// UI — it is not part of the Tilawa atomic kit.
///
/// The control consists of a rounded container with segmented buttons inside.
/// The selected segment has a distinct background color and shadow.
///
/// Per-segment disable: set [TilawaSegment.enabled] to false. Disabled
/// segments stay visible, use reduced opacity, and ignore taps.
class TilawaSegmentedControl<T> extends StatelessWidget {
  /// Creates a segmented control.
  const TilawaSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onValueChanged,
    this.backgroundColor,
    this.selectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.containerRadius,
    this.itemRadius,
    this.enabled = true,
  });

  /// The segments to display. Each segment has a value and label.
  final List<TilawaSegment<T>> segments;

  /// The currently selected value.
  final T selectedValue;

  /// Called when a segment is tapped with its value.
  final ValueChanged<T> onValueChanged;

  /// Background color of the container. Defaults to surface with low opacity.
  final Color? backgroundColor;

  /// Background color of the selected segment. Defaults to surface.
  final Color? selectedColor;

  /// Text color for the selected segment. Defaults to onSurface.
  final Color? selectedTextColor;

  /// Text color for unselected segments. Defaults to onSurfaceVariant.
  final Color? unselectedTextColor;

  /// Outer container corner radius. Defaults to the segmented-control kit
  /// token. Pass a larger value when the control sits inside a card-radius
  /// chrome strip and needs to match the surrounding rounding.
  final double? containerRadius;

  /// Selected/unselected segment corner radius. Defaults to the kit token.
  final double? itemRadius;

  /// Whether the control is interactive.
  final bool enabled;

  /// Laid-out height for chrome that must reserve space around this control.
  static double layoutHeight(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaSegmentedControlTokens tokens =
        theme.componentTokens.segmentedControl;
    final TextStyle? labelStyle = theme.textTheme.labelLarge;
    final EdgeInsets itemPadding = tokens.itemPadding.resolve(
      Directionality.of(context),
    );
    final EdgeInsets containerPadding = tokens.containerPadding.resolve(
      Directionality.of(context),
    );
    final double labelHeight = tilawaMeasureTextHeight(
      context: context,
      style: labelStyle,
    );
    return containerPadding.vertical + itemPadding.vertical + labelHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.segmentedControl;

    final effectiveBackground =
        backgroundColor ?? tokens.containerBackgroundColor;
    final effectiveSelectedColor =
        selectedColor ?? tokens.selectedBackgroundColor;
    final effectiveSelectedTextColor =
        selectedTextColor ?? colorScheme.onPrimary;
    final effectiveUnselectedTextColor =
        unselectedTextColor ?? colorScheme.onSurfaceVariant;

    final designTokens = theme.tokens;
    final itemPadding = tokens.itemPadding.resolve(Directionality.of(context));
    final containerPadding = tokens.containerPadding.resolve(
      Directionality.of(context),
    );
    final labelStyle = theme.textTheme.labelLarge;
    final double labelHeight = tilawaMeasureTextHeight(
      context: context,
      style: labelStyle,
    );
    final double itemHeight = itemPadding.vertical + labelHeight;
    final defaultRadii = designTokens.resolveSegmentedControlRadii(
      itemHeight: itemHeight,
      containerPadding: containerPadding.top,
    );
    final double effectiveContainerRadius =
        containerRadius ?? defaultRadii.containerRadius;
    final double effectiveItemRadius =
        itemRadius ??
        designTokens.concentricInner(
          outerRadius: effectiveContainerRadius,
          padding: containerPadding.top,
        );

    return Container(
      padding: tokens.containerPadding,
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(effectiveContainerRadius),
      ),
      child: Row(
        spacing: tokens.itemSpacing,
        children: segments.map((segment) {
          final isSelected = segment.value == selectedValue;
          final segmentEnabled = enabled && segment.enabled;
          return Expanded(
            child: _SegmentButton(
              label: segment.label,
              isSelected: isSelected,
              onTap: () {
                if (!segmentEnabled) return;
                if (segment.value != selectedValue) {
                  TilawaInteractionFeedback.trigger(TilawaHaptic.selection);
                  onValueChanged(segment.value);
                }
              },
              selectedBackgroundColor: effectiveSelectedColor,
              selectedTextColor: effectiveSelectedTextColor,
              unselectedTextColor: effectiveUnselectedTextColor,
              tokens: tokens,
              itemRadius: effectiveItemRadius,
              enabled: segmentEnabled,
              semanticsHint: segment.semanticsHint,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A single segment in a [TilawaSegmentedControl].
@immutable
class TilawaSegment<T> {
  /// Creates a segment.
  const TilawaSegment({
    required this.value,
    required this.label,
    this.enabled = true,
    this.semanticsHint,
  });

  /// The value associated with this segment.
  final T value;

  /// The text label to display.
  final String label;

  /// When false, segment is visible but not selectable.
  final bool enabled;

  /// Optional accessibility hint when [enabled] is false (e.g. why unavailable).
  final String? semanticsHint;
}

// Material 3 disabled content opacity (matches [TilawaButton]).
const double _kDisabledSegmentOpacity = 0.38;

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedBackgroundColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.tokens,
    required this.itemRadius,
    required this.enabled,
    this.semanticsHint,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedBackgroundColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final TilawaSegmentedControlTokens tokens;
  final double itemRadius;
  final bool enabled;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: isSelected
          ? tokens.selectedFontWeight
          : tokens.unselectedFontWeight,
      color: isSelected ? selectedTextColor : unselectedTextColor,
    );

    final itemBorderRadius = BorderRadius.circular(itemRadius);

    final segment = TilawaInteractiveSurface(
      onTap: onTap,
      enabled: enabled,
      // fix: Accessibility — segment state.
      selected: isSelected,
      semanticLabel: label,
      semanticHint: enabled ? null : semanticsHint,
      // The control fires its own selection haptic (only when the value
      // actually changes), so the surface stays silent to avoid a double tap.
      haptic: TilawaHaptic.none,
      borderRadius: itemBorderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? selectedBackgroundColor : Colors.transparent,
          borderRadius: itemBorderRadius,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tokens.selectedItemShadowColor,
                    blurRadius: tokens.selectedItemShadowBlur,
                    offset: tokens.selectedItemShadowOffset,
                  ),
                ]
              : null,
        ),
        child: Container(
          padding: tokens.itemPadding,
          child: Center(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    if (enabled) return segment;

    return Opacity(opacity: _kDisabledSegmentOpacity, child: segment);
  }
}
