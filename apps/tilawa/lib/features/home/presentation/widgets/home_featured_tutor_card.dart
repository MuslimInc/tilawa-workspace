import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
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

    return Semantics(
      button: true,
      label: context.l10n.homeFeaturedTutorTitle,
      child: DecoratedBox(
        decoration: HomeDashboardElevatedSurface.decoration(
          context,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => openHomeQuranSessions(context),
            borderRadius: BorderRadius.circular(radius),
            splashColor: accent.withValues(alpha: 0.10),
            highlightColor: accent.withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall + tokens.spaceExtraSmall,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: tokens.spaceSmall + tokens.spaceExtraSmall,
                children: [
                  _FeaturedTutorAvatar(accent: accent),
                  Expanded(
                    child: _FeaturedTutorCopy(
                      accent: accent,
                      ctaBackground: accent,
                      ctaForeground:
                          screenTokens.homeFeaturedTutorCtaForeground,
                      eyebrow: context.l10n.homeFeaturedTutorEyebrow,
                      title: context.l10n.homeFeaturedTutorTitle,
                      subtitle: context.l10n.homeFeaturedTutorSubtitle,
                      cta: context.l10n.homeFeaturedTutorCta,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedTutorCopy extends StatelessWidget {
  const _FeaturedTutorCopy({
    required this.accent,
    required this.ctaBackground,
    required this.ctaForeground,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  final Color accent;
  final Color ctaBackground;
  final Color ctaForeground;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
              width: tokens.borderWidthThin,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceExtraSmall + tokens.borderWidthThin,
              vertical: tokens.borderWidthThin,
            ),
            child: Text(
              eyebrow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spaceExtraSmall),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        SizedBox(height: tokens.spaceExtraSmall * 0.5),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.25,
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        _FeaturedTutorCtaPill(
          label: cta,
          background: ctaBackground,
          foreground: ctaForeground,
        ),
      ],
    );
  }
}

class _FeaturedTutorCtaPill extends StatelessWidget {
  const _FeaturedTutorCtaPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceExtraSmall,
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
              FluentIcons.chevron_right_24_filled,
              size: tokens.iconSizeSmall * 0.9,
              color: foreground,
              textDirection: Directionality.of(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedTutorAvatar extends StatelessWidget {
  const _FeaturedTutorAvatar({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double boxSize = tokens.iconSizeLarge + tokens.spaceSmall;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: tokens.borderWidthThin * 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.borderWidthThin * 1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Icon(
              FluentIcons.person_voice_24_regular,
              size: tokens.iconSizeMedium,
              color: accent,
            ),
          ),
        ),
      ),
    );
  }
}
