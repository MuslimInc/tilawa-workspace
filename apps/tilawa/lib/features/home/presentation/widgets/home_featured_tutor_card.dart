import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'home_learn_quran_analytics.dart';
import 'open_home_quran_sessions.dart';

/// Minimum visible fraction that counts as an impression.
const double _kImpressionVisibleFraction = 0.5;

/// Layout metrics for the home featured tutor sliver.
abstract final class HomeFeaturedTutorCardLayout {
  const HomeFeaturedTutorCardLayout._();

  /// Total vertical extent for tutor sliver padding + card body.
  static double extentFor(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    final double horizontalInset =
        TilawaHomeScreenTokens.screenHorizontalPadding(tokens);
    final double contentWidth =
        MediaQuery.sizeOf(context).width - (horizontalInset * 2);
    final TextDirection textDirection = Directionality.of(context);

    final double cardPadding = tokens.spaceMedium * 2;
    final double iconBoxSize = tokens.iconSizeLarge + tokens.spaceMedium;

    final TextStyle titleStyle =
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.15,
        ) ??
        const TextStyle(
          fontSize: 16,
          height: 1.15,
          fontWeight: FontWeight.w700,
        );
    final double cardInnerWidth = contentWidth - cardPadding;

    final double titleHeight = _lineHeight(
      context: context,
      style: titleStyle,
      maxLines: 1,
      maxWidth: cardInnerWidth - iconBoxSize - tokens.spaceSmall,
      textDirection: textDirection,
      text: context.l10n.homeFeaturedTutorTitle,
    );
    final double rowHeight = math.max(iconBoxSize, titleHeight);

    final TextStyle subtitleStyle =
        theme.textTheme.bodySmall?.copyWith(height: 1.3) ??
        const TextStyle(fontSize: 12, height: 1.3);
    final double subtitleHeight = _lineHeight(
      context: context,
      style: subtitleStyle,
      maxLines: 2,
      maxWidth: cardInnerWidth,
      textDirection: textDirection,
      text: context.l10n.homeFeaturedTutorSubtitle,
    );

    final double footerHeight = _FeaturedTutorFooterMetrics.heightFor(
      context: context,
      maxWidth: cardInnerWidth,
      ctaLabel: context.l10n.homeFeaturedTutorCta,
      badgeLabel: context.l10n.experimentalBadgeLabel,
    );

    final double cardHeight =
        cardPadding +
        rowHeight +
        tokens.spaceExtraSmall +
        subtitleHeight +
        tokens.spaceMedium +
        footerHeight +
        (tokens.borderWidthThin * 2);

    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double textScaleSlack = textScale > 1.15 ? tokens.spaceSmall : 0;

    return cardHeight + tokens.spaceMedium + textScaleSlack;
  }

  static double _lineHeight({
    required BuildContext context,
    required TextStyle style,
    required int maxLines,
    required TextDirection textDirection,
    required String text,
    double? maxWidth,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth ?? double.infinity);

    return painter.height;
  }
}

/// Builds the featured tutor sliver when the feature flag is enabled.
Widget? homeFeaturedTutorCardSliver(BuildContext context) {
  if (!quranSessionsFeatureConfig().quranSessionsEnabled) {
    return null;
  }

  final MeMuslimDesignTokens tokens = context.tokens;
  final double horizontalInset = TilawaHomeScreenTokens.screenHorizontalPadding(
    tokens,
  );

  return SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalInset,
        0,
        horizontalInset,
        tokens.spaceMedium,
      ),
      child: const _HomeFeaturedTutorCardImpressionScope(
        child: _HomeFeaturedTutorCardContent(),
      ),
    ),
  );
}

/// Featured product card for Learn Quran with Tutor.
///
/// Standalone wrapper for tests; on Home it is rendered via
/// [homeFeaturedTutorCardSliver].
class HomeFeaturedTutorCard extends StatelessWidget {
  const HomeFeaturedTutorCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!quranSessionsFeatureConfig().quranSessionsEnabled) {
      return const SizedBox.shrink();
    }

    return const _HomeFeaturedTutorCardImpressionScope(
      child: _HomeFeaturedTutorCardContent(),
    );
  }
}

class _HomeFeaturedTutorCardImpressionScope extends StatefulWidget {
  const _HomeFeaturedTutorCardImpressionScope({required this.child});

  final Widget child;

  @override
  State<_HomeFeaturedTutorCardImpressionScope> createState() =>
      _HomeFeaturedTutorCardImpressionScopeState();
}

class _HomeFeaturedTutorCardImpressionScopeState
    extends State<_HomeFeaturedTutorCardImpressionScope> {
  bool _loggedImpression = false;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_loggedImpression) {
      return;
    }
    if (info.visibleFraction < _kImpressionVisibleFraction) {
      return;
    }
    if (!quranSessionsFeatureConfig().quranSessionsEnabled) {
      return;
    }
    _loggedImpression = true;
    logHomeLearnQuranCardViewed();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('home_learn_quran_card_impression'),
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.child,
    );
  }
}

class _HomeFeaturedTutorCardContent extends StatelessWidget {
  const _HomeFeaturedTutorCardContent();

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final Color accent = screenTokens.homeFeaturedTutorAccent;
    final Color cardBorder = Color.alphaBlend(
      screenTokens.homePrayerHeroBorder.withValues(alpha: 0.72),
      theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
    );
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.decorative,
    );
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TilawaInteractiveSurface(
          onTap: () {
            logHomeLearnQuranCardTapped();
            openHomeQuranSessions(context);
          },
          borderRadius: borderRadius,
          stateLayerColor: accent,
          semanticLabel: context.l10n.homeFeaturedTutorTitle,
          semanticHint: context.l10n.homeFeaturedTutorCta,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: screenTokens.homeContentSheetSurface,
              border: Border.all(
                color: cardBorder,
                width: tokens.borderWidthThin,
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.all(tokens.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    spacing: tokens.spaceSmall,
                    children: [
                      _FeaturedTutorIconWell(accent: accent),
                      Expanded(
                        child: Text(
                          context.l10n.homeFeaturedTutorTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    context.l10n.homeFeaturedTutorSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: tokens.spaceMedium),
                  _FeaturedTutorFooter(
                    ctaLabel: context.l10n.homeFeaturedTutorCta,
                    badgeLabel: context.l10n.experimentalBadgeLabel,
                    accent: accent,
                    ctaForeground: screenTokens.homeFeaturedTutorCtaForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

abstract final class _FeaturedTutorFooterMetrics {
  static double heightFor({
    required BuildContext context,
    required double maxWidth,
    required String ctaLabel,
    required String badgeLabel,
  }) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final TextDirection textDirection = Directionality.of(context);

    final double ctaHeight = _ctaPillHeight(
      context: context,
      label: ctaLabel,
      textDirection: textDirection,
    );
    final double badgeHeight = _badgeHeight(
      context: context,
      label: badgeLabel,
      textDirection: textDirection,
    );

    if (maxWidth >=
        _minFooterRowWidth(
          context: context,
          ctaLabel: ctaLabel,
          badgeLabel: badgeLabel,
          textDirection: textDirection,
        )) {
      return math.max(ctaHeight, badgeHeight);
    }

    return ctaHeight + tokens.spaceSmall + badgeHeight;
  }

  static double _ctaPillHeight({
    required BuildContext context,
    required String label,
    required TextDirection textDirection,
  }) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    final TextStyle style =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: textDirection,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    return (tokens.spaceSmall * 2) +
        math.max(painter.height, tokens.iconSizeSmall);
  }

  static double _badgeHeight({
    required BuildContext context,
    required String label,
    required TextDirection textDirection,
  }) {
    final ThemeData theme = Theme.of(context);
    final badgeTokens = theme.componentTokens.experimentalBadge;
    final TextStyle style =
        theme.textTheme.labelSmall?.copyWith(
          fontWeight: badgeTokens.fontWeight,
          letterSpacing: badgeTokens.letterSpacing,
          height: 1,
        ) ??
        const TextStyle(fontSize: 11, height: 1);

    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: textDirection,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    final EdgeInsets badgePadding = badgeTokens.padding.resolve(textDirection);
    return badgePadding.vertical + painter.height;
  }

  static double _minFooterRowWidth({
    required BuildContext context,
    required String ctaLabel,
    required String badgeLabel,
    required TextDirection textDirection,
  }) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    final badgeTokens = theme.componentTokens.experimentalBadge;

    final TextStyle ctaStyle =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
    final TextPainter ctaTextPainter = TextPainter(
      text: TextSpan(text: ctaLabel, style: ctaStyle),
      textDirection: textDirection,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    final double ctaWidth =
        (tokens.spaceMedium * 2) +
        ctaTextPainter.width +
        tokens.spaceExtraSmall +
        tokens.iconSizeSmall;

    final TextStyle badgeStyle =
        theme.textTheme.labelSmall?.copyWith(
          fontWeight: badgeTokens.fontWeight,
          letterSpacing: badgeTokens.letterSpacing,
          height: 1,
        ) ??
        const TextStyle(fontSize: 11, height: 1);
    final TextPainter badgeTextPainter = TextPainter(
      text: TextSpan(text: badgeLabel, style: badgeStyle),
      textDirection: textDirection,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    final EdgeInsets badgePadding = badgeTokens.padding.resolve(textDirection);
    final double badgeWidth = badgePadding.horizontal + badgeTextPainter.width;

    return ctaWidth + tokens.spaceSmall + badgeWidth;
  }
}

class _FeaturedTutorFooter extends StatelessWidget {
  const _FeaturedTutorFooter({
    required this.ctaLabel,
    required this.badgeLabel,
    required this.accent,
    required this.ctaForeground,
  });

  final String ctaLabel;
  final String badgeLabel;
  final Color accent;
  final Color ctaForeground;

  double _minFooterRowWidth(BuildContext context) {
    return _FeaturedTutorFooterMetrics._minFooterRowWidth(
      context: context,
      ctaLabel: ctaLabel,
      badgeLabel: badgeLabel,
      textDirection: Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;

    final cta = _FeaturedTutorCtaPill(
      label: ctaLabel,
      accent: accent,
      foreground: ctaForeground,
    );
    final theme = Theme.of(context);
    final badge = ExcludeSemantics(
      child: TilawaExperimentalBadge(
        label: badgeLabel,
        foregroundColor: theme.colorScheme.onSurface,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= _minFooterRowWidth(context);

        if (useRow) {
          return Row(
            children: [
              cta,
              const Spacer(),
              badge,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spaceSmall,
          children: [cta, badge],
        );
      },
    );
  }
}

/// Visual CTA affordance — card tap target owns navigation.
class _FeaturedTutorCtaPill extends StatelessWidget {
  const _FeaturedTutorCtaPill({
    required this.label,
    required this.accent,
    required this.foreground,
  });

  final String label;
  final Color accent;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);

    final EdgeInsetsDirectional pillPadding = EdgeInsetsDirectional.symmetric(
      horizontal: tokens.spaceMedium,
      vertical: tokens.spaceSmall,
    );
    final TextStyle labelStyle =
        theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
    final TextPainter labelPainter = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double pillHeight =
        pillPadding.vertical +
        math.max(labelPainter.height, tokens.iconSizeSmall);
    final BorderRadius pillRadius = BorderRadius.circular(
      tokens.radiusPill(pillHeight),
    );

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent,
          borderRadius: pillRadius,
        ),
        child: Padding(
          padding: pillPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spaceExtraSmall,
            children: [
              Text(
                label,
                style: labelStyle,
              ),
              Icon(
                FluentIcons.chevron_right_16_regular,
                size: tokens.iconSizeSmall,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedTutorIconWell extends StatelessWidget {
  const _FeaturedTutorIconWell({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final double iconBoxSize = tokens.iconSizeLarge + tokens.spaceMedium;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        color: accent.withValues(alpha: 0.10),
      ),
      child: SizedBox(
        width: iconBoxSize,
        height: iconBoxSize,
        child: Center(
          child: TilawaLearnQuranTutorIcon(
            size: tokens.iconSizeLarge,
            color: accent,
          ),
        ),
      ),
    );
  }
}
