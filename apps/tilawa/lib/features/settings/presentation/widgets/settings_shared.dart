import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/settings_cubit.dart';

/// Trailing label plus chevron for picker rows (Pinterest catalog style).
class SettingsValueTrailing extends StatelessWidget {
  const SettingsValueTrailing({
    super.key,
    required this.value,
    this.leading,
  });

  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: theme.tokens.spaceSmall),
        ],
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(
              alpha: theme.tokens.opacityEmphasis,
            ),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Color swatch for the primary-color picker row.
class SettingsPrimaryColorTrailing extends StatelessWidget {
  const SettingsPrimaryColorTrailing({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const double size = 22;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: theme.tokens.opacityMedium,
          ),
          width: theme.tokens.borderWidthThin,
        ),
      ),
    );
  }
}

String settingsLanguageLabel(Locale locale, AppLocalizations l10n) {
  return switch (locale.languageCode) {
    'ar' => 'العربية',
    _ => 'English',
  };
}

/// Sign-out row (Pinterest: plain label, no chevron).
class SettingsLogoutTile extends StatelessWidget {
  const SettingsLogoutTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        return TilawaCatalogSettingsSection(
          title: context.l10n.settingsLoginSection,
          children: [
            TilawaCatalogSettingsLinkRow(
              title: context.l10n.logout,
              showChevron: false,
              onTap: onTap,
            ),
          ],
        );
      },
    );
  }
}

/// App version and build number footer.
class SettingsAppVersionFooter extends StatelessWidget {
  const SettingsAppVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final info = state.appInfo;
        if (info == null) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: tokens.spaceLarge,
              horizontal: tokens.spaceMedium,
            ),
            child: Text(
              context.l10n.version('…'),
              style: context.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceMedium,
            tokens.spaceLarge,
            tokens.spaceMedium,
            tokens.spaceExtraLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spaceExtraSmall,
            children: [
              Text(
                context.l10n.version(info.version),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                context.l10n.build(info.buildNumber),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
