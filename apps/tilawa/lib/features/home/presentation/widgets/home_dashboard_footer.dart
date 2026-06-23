import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../quran_sessions/presentation/quran_sessions_user.dart';

/// Opens Quran Sessions when the profile is complete, otherwise gates first.
Future<void> openHomeQuranSessions(BuildContext context) async {
  final userId = quranSessionsCurrentUserId(getIt);
  if (userId == null) {
    context.push('/login');
    return;
  }

  final result = await getIt<GetUserProfileUseCase>()(userId);
  if (!context.mounted) return;

  final profile = result.fold((_) => null, (p) => p);
  if (profile != null && profile.isComplete) {
    context.push(QuranSessionsRoutes.home);
    return;
  }

  final completed = await context.push<bool>(
    QuranSessionsRoutes.profileCompletion,
  );
  if (!context.mounted) return;
  if (completed == true) {
    context.push(QuranSessionsRoutes.home);
  }
}

/// Minimal utility footer for Home destinations outside the bottom nav.
class HomeDashboardFooter extends StatelessWidget {
  const HomeDashboardFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

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

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
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
      ),
    );
  }
}
