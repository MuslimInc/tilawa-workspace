import 'dart:ui' show lerpDouble;

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
    return _scopeOf(context)?.shimmer;
  }

  static _TilawaSkeletonShimmerScope? _scopeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_TilawaSkeletonShimmerScope>();
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
    _shimmerController.duration = Theme.of(
      context,
    ).componentTokens.skeleton.shimmerPeriod;
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
      scopeContext: context,
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
    required this.scopeContext,
    required super.child,
  });

  final Animation<double>? shimmer;

  /// The scope [State]'s context. Bones resolve its render box at paint time
  /// to shift their shader into the scope's coordinate space, so all bones
  /// show slices of one travelling band (Flutter shimmer-loading cookbook).
  final BuildContext scopeContext;

  @override
  bool updateShouldNotify(_TilawaSkeletonShimmerScope oldWidget) =>
      shimmer != oldWidget.shimmer || scopeContext != oldWidget.scopeContext;
}

/// A rounded skeleton block standing in for an icon, image, chip, or any
/// fixed-size element while content loads.
///
/// Must be placed under a [TilawaSkeleton] to shimmer; outside a scope it
/// renders as a static block. Fill and highlight colours come from
/// [TilawaSkeletonTokens] (`onSurface` alphas composited opaquely over
/// `surface`) so bones read correctly on both light and dark surfaces and
/// the shimmer band keeps full contrast under [BlendMode.srcATop].
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
    // Pre-composite the token alphas into OPAQUE fills. [ShaderMask] with
    // [BlendMode.srcATop] multiplies the shader by the child's alpha, so a
    // translucent bone would render the shimmer band at a fraction of its
    // strength (the cookbook requires a solid-color placeholder for the
    // same reason).
    final Color surface = theme.colorScheme.surface;
    final Color baseColor = Color.alphaBlend(
      theme.colorScheme.onSurface.withValues(alpha: skeletonTokens.baseAlpha),
      surface,
    );
    final Color highlightColor = Color.alphaBlend(
      theme.colorScheme.onSurface.withValues(
        alpha: skeletonTokens.highlightAlpha,
      ),
      surface,
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

    final _TilawaSkeletonShimmerScope? scope = TilawaSkeleton._scopeOf(
      context,
    );
    final Animation<double>? shimmer = scope?.shimmer;
    if (scope == null || shimmer == null) {
      return bone;
    }

    // Cookbook shimmer (docs.flutter.dev/cookbook/effects/shimmer-loading):
    // a fixed, gently tilted gradient axis slides across the scope via a
    // translation [GradientTransform]. [AlignmentDirectional] mirrors the
    // axis for RTL, so Arabic gleams from the top-start (right) corner
    // toward the bottom-end (left) corner.
    final TextDirection textDirection = Directionality.of(context);
    final double bandWidth = skeletonTokens.shimmerBandWidth;
    // Highlight band stops centred within the leading part of the gradient
    // span — cookbook uses [0.1, 0.3, 0.4]; ours derives from the band
    // width token.
    final List<double> stops = <double>[
      0.25 - bandWidth / 2,
      0.25,
      0.25 + bandWidth / 2,
    ];

    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, child) {
        // Cookbook travel range: -0.5 → 1.5 of the scope width, so the
        // band fully enters and exits.
        final double slidePercent = lerpDouble(-0.5, 1.5, shimmer.value)!;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // One band sweeps the whole [TilawaSkeleton] scope: shift this
            // bone's shader rect into the scope's coordinate space so every
            // bone paints its slice of the same travelling gradient (see
            // the Flutter shimmer-loading cookbook), instead of each bone
            // sweeping across only its own bounds.
            Rect shaderRect = bounds;
            final RenderObject? scopeRender = scope.scopeContext
                .findRenderObject();
            final RenderObject? boneRender = context.findRenderObject();
            if (scopeRender is RenderBox &&
                boneRender is RenderBox &&
                scopeRender.attached &&
                boneRender.attached &&
                scopeRender.hasSize) {
              final Offset boneTopLeft = boneRender.localToGlobal(
                Offset.zero,
                ancestor: scopeRender,
              );
              shaderRect = Rect.fromLTWH(
                -boneTopLeft.dx,
                -boneTopLeft.dy,
                scopeRender.size.width,
                scopeRender.size.height,
              );
            }
            return LinearGradient(
              colors: <Color>[baseColor, highlightColor, baseColor],
              stops: stops,
              begin: const AlignmentDirectional(-1.0, -0.3),
              end: const AlignmentDirectional(1.0, 0.3),
              tileMode: TileMode.clamp,
              transform: _SlidingGradientTransform(
                slidePercent: slidePercent,
              ),
            ).createShader(shaderRect, textDirection: textDirection);
          },
          child: child,
        );
      },
      child: bone,
    );
  }
}

/// Slides the shimmer gradient across the scope by translating the shader
/// (Flutter shimmer-loading cookbook). Mirrors travel direction for RTL so
/// the band always moves in reading direction.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double direction = textDirection == TextDirection.rtl ? -1.0 : 1.0;
    return Matrix4.translationValues(
      bounds.width * slidePercent * direction,
      0.0,
      0.0,
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
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double lineHeight = painter.height;
    painter.dispose();

    return TilawaSkeletonBone(width: width, height: lineHeight);
  }
}
