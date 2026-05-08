import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../foundation/component_tokens.dart';

/// A theme-aware wrapper around the [Skeletonizer] package.
///
/// Unlike manual skeleton blocks, this preserves the exact layout of the
/// child widget by automatically replacing text and images with "bones"
/// that match their original size. This gives a much more accurate loading
/// placeholder than generic [TilawaSkeletonBlock] / [TilawaSkeletonListTile].
///
/// ## Usage
///
/// ```dart
/// TilawaSkeletonizer(
///   child: MyListTile(title: Text('Placeholder'), subtitle: Text('...')),
/// )
/// ```
///
/// For sliver contexts, use [TilawaSliverSkeletonizer].
class TilawaSkeletonizer extends StatelessWidget {
  const TilawaSkeletonizer({
    super.key,
    this.enabled = true,
    this.ignorePointers = true,
    this.justifyMultiLineText,
    required this.child,
  });

  /// Whether the skeleton effect is active.
  final bool enabled;

  /// Whether to ignore pointer events while loading.
  final bool ignorePointers;

  /// Whether to justify multi-line text bones.
  final bool? justifyMultiLineText;

  /// The actual widget tree to skeletonize.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).componentTokens.skeleton;

    return Skeletonizer(
      enabled: enabled,
      ignorePointers: ignorePointers,
      justifyMultiLineText: justifyMultiLineText,
      effect: ShimmerEffect(
        baseColor: tokens.baseColor,
        highlightColor: tokens.highlightColor,
        duration: tokens.animationDuration,
      ),
      child: child,
    );
  }
}

/// A theme-aware wrapper around [SliverSkeletonizer].
///
/// Use inside [CustomScrollView] slivers to skeletonize sliver children
/// while preserving their exact layout dimensions.
///
/// ## Usage
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     TilawaSliverSkeletonizer(
///       child: SliverList(
///         delegate: SliverChildBuilderDelegate(
///           (context, index) => MyListItem(),
///           childCount: 10,
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
class TilawaSliverSkeletonizer extends StatelessWidget {
  const TilawaSliverSkeletonizer({
    super.key,
    this.enabled = true,
    this.ignorePointers = true,
    this.justifyMultiLineText,
    required this.child,
  });

  /// Whether the skeleton effect is active.
  final bool enabled;

  /// Whether to ignore pointer events while loading.
  final bool ignorePointers;

  /// Whether to justify multi-line text bones.
  final bool? justifyMultiLineText;

  /// The sliver widget tree to skeletonize.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).componentTokens.skeleton;

    return SliverSkeletonizer(
      enabled: enabled,
      ignorePointers: ignorePointers,
      justifyMultiLineText: justifyMultiLineText,
      effect: ShimmerEffect(
        baseColor: tokens.baseColor,
        highlightColor: tokens.highlightColor,
        duration: tokens.animationDuration,
      ),
      child: child,
    );
  }
}
