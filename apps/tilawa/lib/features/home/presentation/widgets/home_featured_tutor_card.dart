import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'open_home_quran_sessions.dart';

/// Featured product card for Learn Quran with Tutor.
class HomeFeaturedTutorCard extends StatelessWidget {
  const HomeFeaturedTutorCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!quranSessionsFeatureConfig().quranSessionsEnabled) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    final theme = Theme.of(context);
    final screenTokens = theme.componentTokens.homeScreen;
    final Color accent = screenTokens.homeFeaturedTutorAccent;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.decorative,
    );

    final BorderRadius borderRadius = BorderRadius.circular(radius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TilawaInteractiveSurface(
          onTap: () => openHomeQuranSessions(context),
          borderRadius: borderRadius,
          stateLayerColor: accent,
          semanticLabel: context.l10n.homeFeaturedTutorTitle,
          semanticHint: context.l10n.homeFeaturedTutorCta,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(
                    alpha: screenTokens.homePrayerHeroShadowOpacity,
                  ),
                  offset: Offset(0, tokens.spaceExtraSmall.toDouble()),
                  blurRadius: tokens.spaceLarge.toDouble(),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: screenTokens.featuredTutorGradient(),
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
                      ctaForeground:
                          screenTokens.homeFeaturedTutorCtaForeground,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spaceExtraSmall),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TilawaButton(
            text: context.l10n.homeFeaturedTutorMySessions,
            onPressed: () => openHomeMySessions(context),
            variant: TilawaButtonVariant.ghost,
            size: TilawaButtonSize.small,
            leadingIcon: Icon(
              FluentIcons.calendar_ltr_16_regular,
              size: tokens.iconSizeSmall,
            ),
          ),
        ),
      ],
    );
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
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final textDirection = Directionality.of(context);
    final badgeTokens = theme.componentTokens.experimentalBadge;

    final ctaStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final ctaTextPainter = TextPainter(
      text: TextSpan(text: ctaLabel, style: ctaStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();

    final ctaWidth =
        (tokens.spaceMedium * 2) +
        ctaTextPainter.width +
        tokens.spaceExtraSmall +
        tokens.iconSizeSmall;

    final badgeStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: badgeTokens.fontWeight,
      letterSpacing: badgeTokens.letterSpacing,
      height: 1,
    );
    final badgeTextPainter = TextPainter(
      text: TextSpan(text: badgeLabel, style: badgeStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();

    final badgePadding = badgeTokens.padding.resolve(textDirection);
    final badgeWidth = badgePadding.horizontal + badgeTextPainter.width;

    return ctaWidth + tokens.spaceSmall + badgeWidth;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

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

/// Visual CTA affordance — card [InkWell] owns the single tap target.
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
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spaceExtraSmall,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
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
    final tokens = context.tokens;
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
