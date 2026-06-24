import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';

/// Calendly-style segment card for dual-field wheel pickers.
///
/// The selected segment shows a primary outline; tapping routes the wheel below
/// to that field's value.
class TilawaPickerSegmentCard extends StatelessWidget {
  const TilawaPickerSegmentCard({
    super.key,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.cupertinoWheelPicker;
    final radius = BorderRadius.circular(tokens.segmentBorderRadius);

    return TilawaInteractiveSurface(
      onTap: onTap,
      selected: selected,
      semanticLabel: '$label, $value',
      borderRadius: radius,
      child: Container(
        padding: tokens.segmentPadding,
        decoration: BoxDecoration(
          color: selected
              ? tokens.segmentSelectedBackgroundColor
              : tokens.segmentUnselectedBackgroundColor,
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? tokens.segmentSelectedBorderColor
                : tokens.segmentUnselectedBorderColor,
            width: tokens.segmentSelectedBorderWidth,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.segmentLabelColor,
              ),
            ),
            SizedBox(height: tokens.segmentLabelValueGap),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? tokens.segmentSelectedValueColor
                    : tokens.segmentUnselectedValueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
