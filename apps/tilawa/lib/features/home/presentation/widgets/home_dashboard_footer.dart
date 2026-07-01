import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

export 'open_home_quran_sessions.dart';

import 'open_home_quran_sessions.dart';

/// Minimal utility footer for Home destinations outside the bottom nav.
class HomeDashboardFooter extends StatelessWidget {
  const HomeDashboardFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final sessionsEnabled =
        quranSessionsFeatureConfig().showLearnQuranStudentExperience;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceLarge),
      child: Wrap(
        spacing: tokens.spaceMedium,
        runSpacing: tokens.spaceSmall,
        children: [
          _FooterLink(
            icon: Icons.brightness_7_outlined,
            label: context.l10n.homeQuickTasbeeh,
            onTap: () => const TasbeehRoute().push(context),
          ),
          if (sessionsEnabled)
            _FooterLink(
              icon: Icons.menu_book_rounded,
              label: context.l10n.homeSessionsTitle,
              onTap: () => openHomeQuranSessions(context),
            ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final BorderRadius borderRadius = BorderRadius.circular(
      tokens.radiusMedium,
    );

    return TilawaInteractiveSurface(
      onTap: onTap,
      borderRadius: borderRadius,
      semanticLabel: label,
      stateLayerColor: colorScheme.onSurfaceVariant,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceExtraSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: tokens.iconSizeSmall,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: tokens.spaceSmall),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
