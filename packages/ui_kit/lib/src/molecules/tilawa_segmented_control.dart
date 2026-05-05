import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

/// A segmented control widget for switching between a small number of options.
///
/// Similar to iOS UISegmentedControl or Material ToggleButtons, but styled
/// consistently with the Tilawa design system. Use for 2-5 options where
/// only one can be selected at a time.
///
/// The control consists of a rounded container with segmented buttons inside.
/// The selected segment has a distinct background color and shadow.
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

  /// Text color for unselected segments. Defaults to onPrimary with opacity.
  final Color? unselectedTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.componentTokens.segmentedControl;

    final effectiveBackground =
        backgroundColor ?? colorScheme.surface.withValues(alpha: 0.22);
    final effectiveSelectedColor = selectedColor ?? colorScheme.surface;
    final effectiveSelectedTextColor =
        selectedTextColor ?? colorScheme.onSurface;
    final effectiveUnselectedTextColor =
        unselectedTextColor ?? colorScheme.onPrimary.withValues(alpha: 0.82);

    return Container(
      padding: tokens.containerPadding,
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(tokens.containerRadius),
        border: Border.all(color: colorScheme.surface.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: segments.map((segment) {
          final isSelected = segment.value == selectedValue;
          return Expanded(
            child: _SegmentButton(
              label: segment.label,
              isSelected: isSelected,
              onTap: () => onValueChanged(segment.value),
              selectedBackgroundColor: effectiveSelectedColor,
              selectedTextColor: effectiveSelectedTextColor,
              unselectedTextColor: effectiveUnselectedTextColor,
              tokens: tokens,
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
  const TilawaSegment({required this.value, required this.label});

  /// The value associated with this segment.
  final T value;

  /// The text label to display.
  final String label;
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedBackgroundColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.tokens,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedBackgroundColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final TilawaSegmentedControlTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: isSelected
          ? tokens.selectedFontWeight
          : tokens.unselectedFontWeight,
      color: isSelected ? selectedTextColor : unselectedTextColor,
    );

    return Material(
      color: isSelected ? selectedBackgroundColor : Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.containerRadius - 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.containerRadius - 2),
        child: Container(
          padding: tokens.itemPadding,
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    tokens.containerRadius - 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Center(child: Text(label, style: textStyle)),
        ),
      ),
    );
  }
}
