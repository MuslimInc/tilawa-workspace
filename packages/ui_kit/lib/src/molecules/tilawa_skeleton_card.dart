import 'package:flutter/material.dart';
import '../../tilawa_ui_kit.dart';

/// A skeleton placeholder for card items.
///
/// This widget renders a card-shaped placeholder with:
/// - An image block at the top (landscape ratio)
/// - A title line below
/// - An optional subtitle line
///
/// The layout automatically adapts to [TilawaDensity]:
/// - **Comfortable**: Larger image (16:10 ratio), 16px padding, 3 lines
/// - **Compact**: Smaller image (16:9 ratio), 12px padding, 2 lines
///
/// ## Example
///
/// ```dart
/// TilawaSkeletonCard(
///   width: 200,
///   showSubtitle: true,
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
///   label: 'Loading reciter cards',
///   child: TilawaSkeletonCard(),
/// )
/// ```
///
/// ## Golden Tests
///
/// Use `animate: false` for stable golden images:
///
/// ```dart
/// TilawaSkeletonCard(animate: false)
/// ```
///
/// See also:
/// - [TilawaSkeletonBlock] — The atomic building block
/// - [TilawaSkeletonListTile] — List item skeleton pattern
/// - [TilawaSkeletonList] — Multiple list tiles with spacing
class TilawaSkeletonCard extends StatelessWidget {
  /// Creates a skeleton card placeholder.
  const TilawaSkeletonCard({
    super.key,
    this.width,
    this.height,
    this.showSubtitle = true,
    this.animate = true,
  });

  /// The width of the card.
  ///
  /// If null, the card expands to fill available width.
  final double? width;

  /// The total height of the card.
  ///
  /// If null, height is calculated based on image ratio and content.
  final double? height;

  /// Whether to show the subtitle line.
  ///
  /// Defaults to true. Set to false for cards with only title content.
  final bool showSubtitle;

  /// Whether to animate the shimmer effect.
  ///
  /// Defaults to true. Ignored if reduced motion is enabled.
  /// Set to false for golden tests or static displays.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final designTokens = Theme.of(context).extension<TilawaDesignTokens>()!;
    final density = designTokens.density;

    // Padding based on density
    final padding = switch (density) {
      TilawaDensity.compact => designTokens.spaceSmall,
      _ => designTokens.spaceMedium,
    };

    // Image aspect ratio based on density
    final imageAspectRatio = switch (density) {
      TilawaDensity.compact => 16.0 / 9.0,
      _ => 16.0 / 10.0,
    };

    // Line heights based on density
    final titleHeight = switch (density) {
      TilawaDensity.compact => 14.0,
      _ => 16.0,
    };

    final subtitleHeight = switch (density) {
      TilawaDensity.compact => 12.0,
      _ => 14.0,
    };

    final lineGap = switch (density) {
      TilawaDensity.compact => 6.0,
      _ => 8.0,
    };

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image block
          AspectRatio(
            aspectRatio: imageAspectRatio,
            child: TilawaSkeletonBlock(
              width: double.infinity,
              height: double.infinity,
              shape: TilawaSkeletonShape.rounded,
              animate: animate,
            ),
          ),
          SizedBox(height: padding),
          // Title line
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: TilawaSkeletonBlock(
              width: double.infinity,
              height: titleHeight,
              animate: animate,
            ),
          ),
          if (showSubtitle) ...[
            SizedBox(height: lineGap),
            // Subtitle line (shorter)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: FractionallySizedBox(
                widthFactor: 0.7,
                alignment: AlignmentDirectional.centerStart,
                child: TilawaSkeletonBlock(
                  width: double.infinity,
                  height: subtitleHeight,
                  animate: animate,
                ),
              ),
            ),
          ],
          // Bottom padding
          SizedBox(height: padding),
        ],
      ),
    );
  }
}
