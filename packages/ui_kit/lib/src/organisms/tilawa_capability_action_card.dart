import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atoms/tilawa_icon_box.dart';
import '../atoms/tilawa_skeleton.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';
import '../foundation/tilawa_icons.dart';
import '../foundation/tilawa_interactive_surface.dart';
import '../molecules/tilawa_verified_teacher_badge.dart';

/// Premium capability entry card for approved roles and elevated settings CTAs.
///
/// Calm brand gradient, generous padding, and a secondary badge row so the
/// title stays primary. Use outside worship surfaces (reader, prayer, athkar).
class TilawaCapabilityActionCard extends StatelessWidget {
  const TilawaCapabilityActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.onTap,
    this.badgeLabel,
    this.trailingIcon,
    this.useGradient = true,
    this.semanticLabel,
    this.leadingIconSemanticTint = TilawaSemanticTint.scholar,
    this.margin,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final String? badgeLabel;
  final IconData? trailingIcon;
  final bool useGradient;
  final String? semanticLabel;
  final TilawaSemanticTint leadingIconSemanticTint;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardTokens = theme.componentTokens.capabilityActionCard;
    final String resolvedSemanticLabel = semanticLabel ?? '$title. $subtitle';
    final _CapabilityActionCardLayoutProfile profile =
        _CapabilityActionCardLayoutProfile(
          showBadge: badgeLabel != null,
        );
    return _CapabilityActionCardLayout(
      profile: profile,
      title: title,
      subtitle: subtitle,
      badgeLabel: badgeLabel,
      margin: margin,
      builder: (context, metrics) {
        return _CapabilityActionCardFrame(
          useGradient: useGradient,
          margin: EdgeInsets.zero,
          semanticLabel: resolvedSemanticLabel,
          isButton: true,
          onTap: onTap,
          bodyHeight: metrics.bodyHeight,
          child: _CapabilityActionCardBody(
            metrics: metrics,
            cardTokens: cardTokens,
            leading: TilawaIconBox(
              icon: leadingIcon,
              size: cardTokens.leadingIconSize,
              variant: TilawaIconBoxVariant.tinted,
              semanticTint: leadingIconSemanticTint,
            ),
            copy: _CapabilityActionCardCopy(
              title: title,
              subtitle: subtitle,
              badgeLabel: badgeLabel,
              cardTokens: cardTokens,
            ),
            trailing: Padding(
              padding: EdgeInsets.only(top: theme.tokens.spaceTiny),
              child: Icon(
                trailingIcon ?? TilawaIcons.chevronRightSmall,
                size: cardTokens.trailingIconSize,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: cardTokens.trailingIconOpacity,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder matching [TilawaCapabilityActionCard] layout.
///
/// Use while capability metadata is loading so Settings keeps stable chrome.
class TilawaCapabilityActionCardSkeleton extends StatelessWidget {
  const TilawaCapabilityActionCardSkeleton({
    super.key,
    this.showBadge = true,
    this.titleLines = 1,
    this.subtitleLines = 1,
    this.useGradient = true,
    this.margin,
    this.semanticLabel = 'Loading',
    this.animate = true,
    this.mirrorTitle,
    this.mirrorSubtitle,
    this.mirrorBadgeLabel,
  });

  /// Mirrors the verified-teacher badge row on the loaded card.
  final bool showBadge;

  /// Placeholder title line count — keep in sync with loaded card copy.
  final int titleLines;

  /// Placeholder subtitle line count — keep in sync with loaded card copy.
  final int subtitleLines;
  final bool useGradient;
  final EdgeInsetsGeometry? margin;
  final String semanticLabel;

  /// When set with [mirrorSubtitle], sizes the skeleton to match a loaded card
  /// carrying the same copy.
  final String? mirrorTitle;
  final String? mirrorSubtitle;
  final String? mirrorBadgeLabel;

  /// When false, bones render as static blocks (also off under reduced motion).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTokens = theme.componentTokens.capabilityActionCard;
    final _CapabilityActionCardLayoutProfile profile =
        _CapabilityActionCardLayoutProfile(
          titleLines: titleLines,
          subtitleLines: subtitleLines,
          showBadge: showBadge || mirrorBadgeLabel != null,
        );
    // The frame's Semantics already labels the loading region, so the
    // shimmer scope stays semantically transparent here.
    return TilawaSkeleton(
      animate: animate,
      child: _CapabilityActionCardLayout(
        profile: profile,
        title: mirrorTitle,
        subtitle: mirrorSubtitle,
        badgeLabel: mirrorBadgeLabel,
        margin: margin,
        builder: (context, metrics) {
          return _CapabilityActionCardFrame(
            useGradient: useGradient,
            margin: EdgeInsets.zero,
            semanticLabel: semanticLabel,
            isButton: false,
            bodyHeight: metrics.bodyHeight,
            child: _CapabilityActionCardBody(
              metrics: metrics,
              cardTokens: cardTokens,
              leading: TilawaSkeletonBone(
                width: metrics.leadingExtent,
                height: metrics.leadingExtent,
                borderRadius: theme.tokens.resolveRadius(
                  family: TilawaRadiusFamily.decorative,
                ),
              ),
              copy: _CapabilityActionCardSkeletonCopy(
                metrics: metrics,
                profile: profile,
              ),
              trailing: Padding(
                padding: EdgeInsets.only(top: theme.tokens.spaceTiny),
                child: TilawaSkeletonBone(
                  width: cardTokens.trailingIconSize,
                  height: cardTokens.trailingIconSize,
                  borderRadius: theme.tokens.radiusSmall,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CapabilityActionCardLayout extends StatelessWidget {
  const _CapabilityActionCardLayout({
    required this.profile,
    required this.builder,
    this.title,
    this.subtitle,
    this.badgeLabel,
    this.margin,
  });

  final _CapabilityActionCardLayoutProfile profile;
  final String? title;
  final String? subtitle;
  final String? badgeLabel;
  final EdgeInsetsGeometry? margin;
  final Widget Function(
    BuildContext context,
    _CapabilityActionCardLayoutMetrics metrics,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final cardTokens = Theme.of(context).componentTokens.capabilityActionCard;
    final resolvedMargin = margin ?? cardTokens.outerPadding;

    return Padding(
      padding: resolvedMargin,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _CapabilityActionCardLayoutMetrics.resolve(
            context,
            cardTokens: cardTokens,
            profile: profile,
            copyMaxWidth: _CapabilityActionCardLayoutMetrics.copyMaxWidth(
              context,
              bodyWidth: constraints.maxWidth,
              cardTokens: cardTokens,
            ),
            title: title,
            subtitle: subtitle,
            badgeLabel: badgeLabel,
          );
          return builder(context, metrics);
        },
      ),
    );
  }
}

@immutable
class _CapabilityActionCardLayoutProfile {
  const _CapabilityActionCardLayoutProfile({
    this.titleLines = 1,
    this.subtitleLines = 1,
    this.showBadge = true,
  });

  final int titleLines;
  final int subtitleLines;
  final bool showBadge;
}

@immutable
class _CapabilityActionCardLayoutMetrics {
  const _CapabilityActionCardLayoutMetrics({
    required this.titleBlockHeight,
    required this.subtitleBlockHeight,
    required this.badgeHeight,
    required this.copyColumnHeight,
    required this.leadingExtent,
    required this.bodyHeight,
  });

  final double titleBlockHeight;
  final double subtitleBlockHeight;
  final double badgeHeight;
  final double copyColumnHeight;
  final double leadingExtent;
  final double bodyHeight;

  factory _CapabilityActionCardLayoutMetrics.resolve(
    BuildContext context, {
    required TilawaCapabilityActionCardTokens cardTokens,
    required _CapabilityActionCardLayoutProfile profile,
    required double copyMaxWidth,
    String? title,
    String? subtitle,
    String? badgeLabel,
  }) {
    final theme = Theme.of(context);
    final chipTokens = theme.componentTokens.chip;
    final iconBoxTokens = theme.componentTokens.iconBox;
    final designTokens = theme.tokens;

    final TextStyle titleStyle = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final TextStyle subtitleStyle = theme.textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    final TextStyle badgeStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: chipTokens.statusFontWeight,
      letterSpacing: chipTokens.statusLetterSpacing,
    );

    double textLineHeight(TextStyle style) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: 'Hg', style: style),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      return painter.height;
    }

    double measureTextBlockHeight({
      required String value,
      required TextStyle style,
      required int maxLines,
    }) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: Directionality.of(context),
        maxLines: maxLines,
      )..layout(maxWidth: copyMaxWidth);
      return painter.height;
    }

    final double titleBlockHeight = title == null
        ? textLineHeight(titleStyle) * profile.titleLines
        : measureTextBlockHeight(
            value: title,
            style: titleStyle,
            maxLines: 2,
          );
    final double subtitleBlockHeight = subtitle == null
        ? textLineHeight(subtitleStyle) * profile.subtitleLines
        : measureTextBlockHeight(
            value: subtitle,
            style: subtitleStyle,
            maxLines: 3,
          );
    final EdgeInsets badgePadding = chipTokens.inlinePadding.resolve(
      Directionality.of(context),
    );
    final double badgeLabelHeight = badgeLabel == null
        ? textLineHeight(badgeStyle)
        : measureTextBlockHeight(
            value: badgeLabel,
            style: badgeStyle,
            maxLines: 1,
          );
    final double badgeHeight = profile.showBadge
        ? badgePadding.vertical +
              math.max(chipTokens.inlineIconSize, badgeLabelHeight)
        : 0;

    final double rawCopyColumnHeight =
        titleBlockHeight +
        cardTokens.titleSubtitleSpacing +
        subtitleBlockHeight +
        (profile.showBadge ? cardTokens.badgeTopSpacing + badgeHeight : 0);
    final double copyColumnHeight = rawCopyColumnHeight.ceilToDouble() + 1;

    final double leadingExtent =
        cardTokens.leadingIconSize + iconBoxTokens.padding * 2;
    final double chevronExtent =
        cardTokens.trailingIconSize + designTokens.spaceTiny;
    final double bodyHeight = math.max(
      leadingExtent,
      math.max(copyColumnHeight, chevronExtent),
    );

    return _CapabilityActionCardLayoutMetrics(
      titleBlockHeight: titleBlockHeight,
      subtitleBlockHeight: subtitleBlockHeight,
      badgeHeight: badgeHeight,
      copyColumnHeight: copyColumnHeight,
      leadingExtent: leadingExtent,
      bodyHeight: bodyHeight,
    );
  }

  static double copyMaxWidth(
    BuildContext context, {
    required double bodyWidth,
    required TilawaCapabilityActionCardTokens cardTokens,
  }) {
    final iconBoxTokens = Theme.of(context).componentTokens.iconBox;
    final EdgeInsets contentPadding = cardTokens.contentPadding.resolve(
      Directionality.of(context),
    );
    final double leadingExtent =
        cardTokens.leadingIconSize + iconBoxTokens.padding * 2;

    // Row uses [spacing] between leading, copy, and trailing — two gaps.
    return math.max(
      0,
      bodyWidth -
          contentPadding.horizontal -
          leadingExtent -
          (cardTokens.rowGap * 2) -
          cardTokens.trailingIconSize,
    );
  }
}

class _CapabilityActionCardBody extends StatelessWidget {
  const _CapabilityActionCardBody({
    required this.metrics,
    required this.cardTokens,
    required this.leading,
    required this.copy,
    required this.trailing,
  });

  final _CapabilityActionCardLayoutMetrics metrics;
  final TilawaCapabilityActionCardTokens cardTokens;
  final Widget leading;
  final Widget copy;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: cardTokens.rowGap,
      children: [
        leading,
        Expanded(
          child: SizedBox(
            height: metrics.copyColumnHeight,
            child: copy,
          ),
        ),
        trailing,
      ],
    );

    return Padding(
      padding: cardTokens.contentPadding,
      child: SizedBox(height: metrics.bodyHeight, child: row),
    );
  }
}

class _CapabilityActionCardSkeletonCopy extends StatelessWidget {
  const _CapabilityActionCardSkeletonCopy({
    required this.metrics,
    required this.profile,
  });

  final _CapabilityActionCardLayoutMetrics metrics;
  final _CapabilityActionCardLayoutProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTokens = theme.componentTokens.capabilityActionCard;
    final designTokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.titleLines == 1)
          TilawaSkeletonBone(
            width: double.infinity,
            height: metrics.titleBlockHeight,
          )
        else
          for (int index = 0; index < profile.titleLines; index++)
            TilawaSkeletonBone(
              width: double.infinity,
              height: metrics.titleBlockHeight / profile.titleLines,
            ),
        SizedBox(height: cardTokens.titleSubtitleSpacing),
        if (profile.subtitleLines == 1)
          TilawaSkeletonBone(
            width: double.infinity,
            height: metrics.subtitleBlockHeight,
          )
        else
          for (int index = 0; index < profile.subtitleLines; index++)
            TilawaSkeletonBone(
              width: double.infinity,
              height: metrics.subtitleBlockHeight / profile.subtitleLines,
            ),
        if (profile.showBadge) ...[
          SizedBox(height: cardTokens.badgeTopSpacing),
          TilawaSkeletonBone(
            width: 128,
            height: metrics.badgeHeight,
            borderRadius: designTokens.resolveRadius(
              family: TilawaRadiusFamily.chip,
              height: metrics.badgeHeight,
            ),
          ),
        ],
      ],
    );
  }
}

class _CapabilityActionCardFrame extends StatelessWidget {
  const _CapabilityActionCardFrame({
    required this.child,
    required this.useGradient,
    required this.semanticLabel,
    required this.isButton,
    required this.bodyHeight,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final bool useGradient;
  final EdgeInsetsGeometry? margin;
  final String semanticLabel;
  final bool isButton;
  final double bodyHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final designTokens = theme.tokens;
    final cardTokens = theme.componentTokens.capabilityActionCard;
    final settingsTokens = theme.componentTokens.settingsGroup;
    final double radius = designTokens.resolveRadius(
      family: TilawaRadiusFamily.card,
    );
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final EdgeInsetsGeometry resolvedMargin = margin ?? cardTokens.outerPadding;
    final EdgeInsets resolvedContentPadding = cardTokens.contentPadding.resolve(
      Directionality.of(context),
    );
    final double resolvedBodyMinHeight = math.max(
      designTokens.minInteractiveDimension,
      resolvedContentPadding.vertical + bodyHeight,
    );

    // Material stays for the rounded fill + clip (the gradient uses [Ink],
    // which needs a Material ancestor). Tap handling moves to the shared
    // interaction primitive wrapping the whole card below.
    final Widget surface = Material(
      color: useGradient ? null : colorScheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: cardTokens.borderColor,
          width: settingsTokens.tileDividerThickness,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _CapabilityActionCardSurfaceFill(
        useGradient: useGradient,
        borderRadius: borderRadius,
        cardTokens: cardTokens,
        minHeight: resolvedBodyMinHeight,
        child: child,
      ),
    );

    final Widget framed = SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: designTokens.opacityShadow,
              ),
              blurRadius: designTokens.blurShadow,
              offset: designTokens.shadowOffsetMedium,
            ),
          ],
        ),
        child: surface,
      ),
    );

    // Interactive cards route the whole frame (surface + shadow) through the
    // kit's interaction primitive: state-layer press, focus ring, and haptic —
    // no ink ripple. The outer Semantics still owns the button role + label.
    final Widget interactive = onTap == null
        ? framed
        : TilawaInteractiveSurface(
            onTap: onTap,
            button: false,
            borderRadius: borderRadius,
            child: framed,
          );

    return Padding(
      padding: resolvedMargin,
      child: Semantics(
        button: isButton,
        label: semanticLabel,
        liveRegion: !isButton,
        child: isButton ? interactive : ExcludeSemantics(child: framed),
      ),
    );
  }
}

class _CapabilityActionCardSurfaceFill extends StatelessWidget {
  const _CapabilityActionCardSurfaceFill({
    required this.useGradient,
    required this.borderRadius,
    required this.cardTokens,
    required this.minHeight,
    required this.child,
  });

  final bool useGradient;
  final BorderRadius borderRadius;
  final TilawaCapabilityActionCardTokens cardTokens;
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: useGradient
          ? BoxDecoration(
              gradient: cardTokens.backgroundGradient(),
              borderRadius: borderRadius,
            )
          : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: child,
      ),
    );
  }
}

class _CapabilityActionCardCopy extends StatelessWidget {
  const _CapabilityActionCardCopy({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.cardTokens,
  });

  final String title;
  final String subtitle;
  final String? badgeLabel;
  final TilawaCapabilityActionCardTokens cardTokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: theme.textTheme.titleMedium?.copyWith(
            color: cardTokens.titleColor,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        SizedBox(height: cardTokens.titleSubtitleSpacing),
        Text(
          subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textAlign: TextAlign.start,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cardTokens.subtitleColor,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        if (badgeLabel != null) ...[
          SizedBox(height: cardTokens.badgeTopSpacing),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TilawaVerifiedTeacherBadge(label: badgeLabel!),
          ),
        ],
      ],
    );
  }
}
