import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Shared shimmer scope for skeleton loading states.
///
/// Wrap a layout of [TilawaSkeletonBone] / [TilawaSkeletonLine] widgets in a
/// single [TilawaSkeleton] so every bone shares one animation ticker (one
/// shimmer sweep across the whole placeholder, not one per bone). The scope
/// honours reduced motion ([MediaQuery.disableAnimationsOf]) by freezing bones
/// as static blocks, and drives timing/appearance from
/// [MeMuslimDesignTokens.durationSlow] and [TilawaSkeletonTokens].
///
/// ```dart
/// TilawaSkeleton(
///   semanticLabel: context.l10n.loading,
///   child: Column(
///     spacing: tokens.spaceSmall,
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: const [
///       TilawaSkeletonLine(width: 160),
///       TilawaSkeletonLine(),
///     ],
///   ),
/// )
/// ```
///
/// Keep skeleton layouts mirroring the loaded content's geometry so the
/// loading → content swap doesn't jump (see
/// `TilawaCapabilityActionCardSkeleton` for a measured example).
class TilawaSkeleton extends StatefulWidget {
  /// Creates a shimmer scope for descendant skeleton bones.
  const TilawaSkeleton({
    super.key,
    required this.child,
    this.animate = true,
    this.semanticLabel,
  });

  /// Skeleton layout composed of bones and regular layout widgets.
  final Widget child;

  /// When false, bones render as static blocks (also off under reduced
  /// motion).
  final bool animate;

  /// Announced label for the loading region (e.g. "Loading"). When set, the
  /// bones themselves are excluded from semantics and the scope becomes a
  /// live region.
  final String? semanticLabel;

  /// The shared shimmer animation of the nearest enclosing [TilawaSkeleton],
  /// or null when there is none or motion is disabled.
  static Animation<double>? shimmerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_TilawaSkeletonShimmerScope>()
        ?.shimmer;
  }

  @override
  State<TilawaSkeleton> createState() => _TilawaSkeletonState();
}

class _TilawaSkeletonState extends State<TilawaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shimmerController.duration = Theme.of(context).tokens.durationSlow;
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant TilawaSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    final bool shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (!shouldAnimate) {
      _shimmerController.stop();
      _shimmerController.value = 0;
      return;
    }
    if (!_shimmerController.isAnimating) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);

    Widget scoped = _TilawaSkeletonShimmerScope(
      shimmer: shouldAnimate ? _shimmerController : null,
      child: widget.child,
    );

    if (widget.semanticLabel != null) {
      scoped = Semantics(
        container: true,
        liveRegion: true,
        label: widget.semanticLabel,
        child: ExcludeSemantics(child: scoped),
      );
    }

    return scoped;
  }
}

class _TilawaSkeletonShimmerScope extends InheritedWidget {
  const _TilawaSkeletonShimmerScope({
    required this.shimmer,
    required super.child,
  });

  final Animation<double>? shimmer;

  @override
  bool updateShouldNotify(_TilawaSkeletonShimmerScope oldWidget) =>
      shimmer != oldWidget.shimmer;
}

/// A rounded skeleton block standing in for an icon, image, chip, or any
/// fixed-size element while content loads.
///
/// Must be placed under a [TilawaSkeleton] to shimmer; outside a scope it
/// renders as a static block. Fill and highlight colours come from
/// [TilawaSkeletonTokens] on `onSurface` so bones read correctly on both
/// light and dark surfaces.
class TilawaSkeletonBone extends StatelessWidget {
  /// Creates a rounded rectangular bone.
  const TilawaSkeletonBone({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  }) : _isCircle = false;

  /// Creates a circular bone (avatars, icon rests).
  const TilawaSkeletonBone.circle({
    super.key,
    required double dimension,
  }) : width = dimension,
       height = dimension,
       borderRadius = null,
       _isCircle = true;

  /// Bone width; null lets the parent constrain it (commonly
  /// `double.infinity` inside a [Column]).
  final double? width;

  /// Bone height.
  final double height;

  /// Corner radius override. Defaults to
  /// [MeMuslimDesignTokens.radiusSmall].
  final double? borderRadius;

  final bool _isCircle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaSkeletonTokens skeletonTokens = theme.componentTokens.skeleton;
    final Color baseColor = theme.colorScheme.onSurface.withValues(
      alpha: skeletonTokens.baseAlpha,
    );
    final Color highlightColor = theme.colorScheme.onSurface.withValues(
      alpha: skeletonTokens.highlightAlpha,
    );

    final Widget bone = RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: _isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: _isCircle
              ? null
              : BorderRadius.circular(
                  borderRadius ?? theme.tokens.radiusSmall,
                ),
        ),
      ),
    );

    final Animation<double>? shimmer = TilawaSkeleton.shimmerOf(context);
    if (shimmer == null) {
      return bone;
    }

    // Sweep the highlight band in reading direction so RTL skeletons
    // shimmer end-to-start like their LTR counterparts.
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final double bandWidth = skeletonTokens.shimmerBandWidth;

    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, child) {
        final double travel = -1 + (shimmer.value * 2);
        final double slide = isRtl ? -travel : travel;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(slide - bandWidth, 0),
              end: Alignment(slide + bandWidth, 0),
              colors: <Color>[baseColor, highlightColor, baseColor],
              stops: const <double>[0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: bone,
    );
  }
}

/// A skeleton bone sized to one line of text in a given style.
///
/// Measures the resolved [style] (defaults to `bodyMedium`) so the bone's
/// height matches the text it stands in for and the loading → content swap
/// keeps a stable layout.
class TilawaSkeletonLine extends StatelessWidget {
  /// Creates a single text-line bone.
  const TilawaSkeletonLine({
    super.key,
    this.width,
    this.style,
  });

  /// Line width; null lets the parent constrain it.
  final double? width;

  /// Text style whose line height the bone mirrors. Defaults to
  /// `textTheme.bodyMedium`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle resolvedStyle = style ?? theme.textTheme.bodyMedium!;
    final TextPainter painter = TextPainter(
      text: TextSpan(text: 'Hg', style: resolvedStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final double lineHeight = painter.height;
    painter.dispose();

    return TilawaSkeletonBone(width: width, height: lineHeight);
  }
}
