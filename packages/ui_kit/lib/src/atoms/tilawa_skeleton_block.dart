import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import 'tilawa_skeleton_shape.dart';

/// A customizable skeleton placeholder block with optional shimmer animation.
///
/// Skeleton blocks provide visual placeholders for content that is loading,
/// improving perceived performance by showing the approximate layout before
/// content arrives.
///
/// ## Usage
///
/// ```dart
/// // Simple text line placeholder
/// TilawaSkeletonBlock(
///   width: double.infinity,
///   height: 16,
///   shape: TilawaSkeletonShape.rounded,
/// )
///
/// // Circle avatar placeholder
/// TilawaSkeletonBlock(
///   width: 48,
///   height: 48,
///   shape: TilawaSkeletonShape.circle,
/// )
///
/// // Static (no animation) for tests/goldens
/// TilawaSkeletonBlock(
///   width: 200,
///   height: 100,
///   animate: false,
/// )
/// ```
///
/// ## Accessibility
///
/// - Automatically respects reduced motion settings from [MediaQuery]
/// - Uses static display when animations are disabled
/// - Can be wrapped in [Semantics] for screen reader announcements
///
/// ## RTL Support
///
/// Shimmer direction automatically follows text direction:
/// - LTR: Shimmer moves left-to-right
/// - RTL: Shimmer moves right-to-left
class TilawaSkeletonBlock extends StatefulWidget {
  /// Creates a skeleton placeholder block.
  const TilawaSkeletonBlock({
    super.key,
    this.width,
    this.height,
    this.shape = TilawaSkeletonShape.rounded,
    this.borderRadius,
    this.animate = true,
  });

  /// The width of the skeleton block.
  ///
  /// If null, the block expands to fill available width.
  final double? width;

  /// The height of the skeleton block.
  ///
  /// Required unless the block is placed in a constraints-providing parent.
  final double? height;

  /// The shape of the skeleton block.
  ///
  /// Defaults to [TilawaSkeletonShape.rounded].
  final TilawaSkeletonShape shape;

  /// Override the default border radius.
  ///
  /// If null, uses the value from [TilawaSkeletonTokens.borderRadius].
  final double? borderRadius;

  /// Whether to animate the shimmer effect.
  ///
  /// Defaults to true. Ignored if reduced motion is enabled.
  /// Set to false for golden tests or static displays.
  final bool animate;

  @override
  State<TilawaSkeletonBlock> createState() => _TilawaSkeletonBlockState();
}

class _TilawaSkeletonBlockState extends State<TilawaSkeletonBlock>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeCreateController();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(TilawaSkeletonBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      _updateAnimation();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _maybeCreateController() {
    if (_controller != null) return;

    final shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (!shouldAnimate) return;

    final tokens = Theme.of(context).componentTokens.skeleton;
    _controller = AnimationController(
      duration: tokens.animationDuration,
      vsync: this,
    );
  }

  void _updateAnimation() {
    final shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);

    if (shouldAnimate && _controller != null && !_controller!.isAnimating) {
      _controller!.repeat();
    } else if (!shouldAnimate &&
        _controller != null &&
        _controller!.isAnimating) {
      _controller!.stop();
    }
  }

  double get _effectiveBorderRadius {
    final tokens = Theme.of(context).componentTokens.skeleton;

    switch (widget.shape) {
      case TilawaSkeletonShape.rectangle:
        return 0;
      case TilawaSkeletonShape.circle:
        return 999;
      case TilawaSkeletonShape.rounded:
        return widget.borderRadius ?? tokens.borderRadius;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).componentTokens.skeleton;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget skeleton = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: tokens.baseColor,
        borderRadius: BorderRadius.circular(_effectiveBorderRadius),
      ),
    );

    final shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);

    if (shouldAnimate) {
      skeleton = _buildShimmer(skeleton, tokens, isRtl);
    }

    return RepaintBoundary(child: skeleton);
  }

  Widget _buildShimmer(Widget child, TilawaSkeletonTokens tokens, bool isRtl) {
    // Controller must exist when this is called (checked by shouldAnimate)
    final controller = _controller!;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final gradient = LinearGradient(
              begin: isRtl ? Alignment.centerRight : Alignment.centerLeft,
              end: isRtl ? Alignment.centerLeft : Alignment.centerRight,
              colors: [
                tokens.baseColor,
                tokens.highlightColor,
                tokens.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(progress: controller.value),
            );
            return gradient.createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Custom gradient transform that slides the shimmer across the widget.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.progress});

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Slide from -1.0 to 1.0 across the bounds
    final slide = -1.0 + (progress * 2.0);
    return Matrix4.translationValues(bounds.width * slide, 0, 0);
  }
}
