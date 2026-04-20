import 'package:flutter/material.dart';

/// A layout primitive that handles responsive grid logic using
/// [SliverGridDelegateWithMaxCrossAxisExtent].
///
/// It determines the number of columns automatically based on the available
/// width and the [targetItemExtent].
class TilawaContentGrid extends StatelessWidget {
  const TilawaContentGrid({
    super.key,
    required this.targetItemExtent,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.padding,
    required this.itemBuilder,
    required this.itemCount,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
  });

  /// The maximum width/extent an item should take before adding a new column.
  final double targetItemExtent;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry? padding;

  /// Called, as needed, to build child widgets.
  final IndexedWidgetBuilder itemBuilder;

  /// The total number of children.
  final int itemCount;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  final bool shrinkWrap;

  /// How the scroll view should respond to user input.
  final ScrollPhysics? physics;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: targetItemExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
