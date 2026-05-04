import 'package:flutter/material.dart';

import '../../tilawa_ui_kit.dart';

/// A skeleton placeholder for list tile items.
///
/// This widget renders a horizontal row with:
/// - A circular avatar skeleton on the left
/// - Two or three text line skeletons on the right
///
/// The layout automatically adapts to [TilawaDensity]:
/// - **Comfortable**: 16px gaps, larger avatar (48px), 3 lines
/// - **Compact**: 12px gaps, smaller avatar (40px), 2 lines
///
/// ## Example
///
/// ```dart
/// TilawaSkeletonListTile()
/// ```
///
/// ## Accessibility
///
/// This widget renders purely visual placeholder content. Wrap in [Semantics]
/// with appropriate labels when used in actual loading states:
///
/// ```dart
/// Semantics(
///   label: 'Loading reciters',
///   child: TilawaSkeletonListTile(),
/// )
/// ```
///
/// ## Golden Tests
///
/// Use `animate: false` for stable golden images:
///
/// ```dart
/// TilawaSkeletonListTile(animate: false)
/// ```
///
/// See also:
/// - [TilawaSkeletonBlock] — The atomic building block
/// - [TilawaSkeletonList] — Multiple list tiles with spacing
/// - [TilawaSkeletonCard] — Card-shaped skeleton pattern
class TilawaSkeletonListTile extends StatelessWidget {
  /// Creates a skeleton list tile placeholder.
  const TilawaSkeletonListTile({super.key, this.animate = true, this.lines = 2})
    : assert(lines >= 1 && lines <= 3, 'Lines must be between 1 and 3');

  /// Whether to animate the shimmer effect.
  ///
  /// Defaults to true. Ignored if reduced motion is enabled.
  /// Set to false for golden tests or static displays.
  final bool animate;

  /// Number of text lines to show (1-3).
  ///
  /// Defaults to 2. Adjust based on your list tile content density.
  final int lines;

  @override
  Widget build(BuildContext context) {
    final designTokens = Theme.of(context).extension<TilawaDesignTokens>()!;
    final density = designTokens.density;

    // Size and spacing based on density
    final avatarSize = switch (density) {
      TilawaDensity.compact => 40.0,
      _ => 48.0,
    };

    final gap = switch (density) {
      TilawaDensity.compact => designTokens.spaceSmall,
      _ => designTokens.spaceMedium,
    };

    final lineHeight = switch (density) {
      TilawaDensity.compact => 12.0,
      _ => 14.0,
    };

    final lineGap = switch (density) {
      TilawaDensity.compact => 6.0,
      _ => 8.0,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        TilawaSkeletonBlock(
          width: avatarSize,
          height: avatarSize,
          shape: TilawaSkeletonShape.circle,
          animate: animate,
        ),
        SizedBox(width: gap),
        // Text lines
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary line (full width)
              TilawaSkeletonBlock(
                width: double.infinity,
                height: lineHeight,
                animate: animate,
              ),
              if (lines >= 2) ...[
                SizedBox(height: lineGap),
                // Secondary line (80% width)
                TilawaSkeletonBlock(
                  width: null, // Will be constrained by parent
                  height: lineHeight,
                  animate: animate,
                ),
              ],
              if (lines >= 3) ...[
                SizedBox(height: lineGap),
                // Tertiary line (60% width)
                FractionallySizedBox(
                  widthFactor: 0.6,
                  alignment: AlignmentDirectional.centerStart,
                  child: TilawaSkeletonBlock(
                    width: double.infinity,
                    height: lineHeight,
                    animate: animate,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
