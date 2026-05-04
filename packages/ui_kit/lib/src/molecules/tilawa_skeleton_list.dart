import 'package:flutter/material.dart';
import '../../tilawa_ui_kit.dart';
import '../foundation/design_tokens.dart';
import '../foundation/density.dart';

/// A skeleton placeholder for a list of items.
///
/// This widget renders multiple skeleton list tiles with consistent spacing.
/// Useful for showing loading states in list views, scrollable areas,
/// and content placeholders.
///
/// The layout automatically adapts to [TilawaDensity]:
/// - **Comfortable**: 16px gaps between items
/// - **Compact**: 12px gaps between items
///
/// ## Example
///
/// ```dart
/// TilawaSkeletonList(
///   itemCount: 5,
///   linesPerItem: 2,
/// )
/// ```
///
/// ## Accessibility
///
/// This widget renders purely visual placeholder content. Wrap in [Semantics]
/// with appropriate labels when used in actual loading states:
///
/// ```dart
/// Semantics(
///   label: 'Loading reciters list',
///   child: TilawaSkeletonList(itemCount: 10),
/// )
/// ```
///
/// ## Golden Tests
///
/// Use `animate: false` for stable golden images:
///
/// ```dart
/// TilawaSkeletonList(
///   itemCount: 3,
///   animate: false,
/// )
/// ```
///
/// See also:
/// - [TilawaSkeletonBlock] — The atomic building block
/// - [TilawaSkeletonListTile] — Single list item skeleton pattern
/// - [TilawaSkeletonCard] — Card-shaped skeleton pattern
class TilawaSkeletonList extends StatelessWidget {
  /// Creates a skeleton list placeholder.
  const TilawaSkeletonList({
    super.key,
    this.itemCount = 3,
    this.linesPerItem = 2,
    this.padding,
    this.itemPadding,
    this.animate = true,
  }) : assert(itemCount > 0, 'Item count must be positive'),
       assert(linesPerItem >= 1 && linesPerItem <= 3,
              'Lines per item must be between 1 and 3');

  /// Number of skeleton items to render.
  ///
  /// Defaults to 3. Adjust based on expected visible content.
  final int itemCount;

  /// Number of text lines per item (1-3).
  ///
  /// Defaults to 2. See [TilawaSkeletonListTile.lines] for details.
  final int linesPerItem;

  /// Padding around the entire list.
  ///
  /// If null, uses density-appropriate default:
  /// - Comfortable: 16px all sides
  /// - Compact: 12px all sides
  final EdgeInsetsGeometry? padding;

  /// Padding for each individual list item.
  ///
  /// If null, items have no internal padding (just the gap between items).
  final EdgeInsetsGeometry? itemPadding;

  /// Whether to animate the shimmer effect.
  ///
  /// Defaults to true. Ignored if reduced motion is enabled.
  /// Set to false for golden tests or static displays.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final designTokens = Theme.of(context).extension<TilawaDesignTokens>()!;
    final density = designTokens.density;

    // Default padding based on density
    final effectivePadding = padding ??
        EdgeInsets.all(
          switch (density) {
            TilawaDensity.compact => designTokens.spaceSmall,
            _ => designTokens.spaceMedium,
          },
        );

    // Gap between items based on density
    final itemGap = switch (density) {
      TilawaDensity.compact => designTokens.spaceSmall,
      _ => designTokens.spaceMedium,
    };

    return Padding(
      padding: effectivePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) SizedBox(height: itemGap),
            Padding(
              padding: itemPadding ?? EdgeInsets.zero,
              child: TilawaSkeletonListTile(
                lines: linesPerItem,
                animate: animate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
