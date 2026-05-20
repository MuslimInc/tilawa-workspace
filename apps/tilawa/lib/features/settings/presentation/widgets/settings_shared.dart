import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/settings_cubit.dart';

/// Consistent vertical spacing between settings groups.
class SettingsSectionGap extends StatelessWidget {
  const SettingsSectionGap({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return SizedBox(height: tokens.spaceLarge + tokens.spaceSmall);
  }
}

/// Border radii for the first, middle, and last tiles in a group.
abstract final class SettingsTileCorners {
  static BorderRadius top(TilawaDesignTokens tokens) {
    return BorderRadius.vertical(top: Radius.circular(tokens.radiusLarge));
  }

  static BorderRadius bottom(TilawaDesignTokens tokens) {
    return BorderRadius.vertical(bottom: Radius.circular(tokens.radiusLarge));
  }

  static BorderRadius all(TilawaDesignTokens tokens) {
    return BorderRadius.circular(tokens.radiusLarge);
  }
}

/// Trailing label plus chevron for picker tiles.
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
    final tokens = theme.componentTokens.settingsGroup;
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
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: theme.tokens.spaceSmall),
        Icon(
          FluentIcons.chevron_right_24_filled,
          size: tokens.tileTrailingSize,
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: (tokens.tileTrailingOpacity * 1.35).clamp(0.45, 0.72),
          ),
        ),
      ],
    );
  }
}

/// Color swatch plus chevron for the primary-color picker tile.
class SettingsPrimaryColorTrailing extends StatelessWidget {
  const SettingsPrimaryColorTrailing({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.settingsGroup;
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tokens.tileIconSize,
          height: tokens.tileIconSize,
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
        ),
        SizedBox(width: theme.tokens.spaceSmall),
        Icon(
          FluentIcons.chevron_right_24_filled,
          size: tokens.tileTrailingSize,
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: (tokens.tileTrailingOpacity * 1.35).clamp(0.45, 0.72),
          ),
        ),
      ],
    );
  }
}

String settingsLanguageLabel(Locale locale, AppLocalizations l10n) {
  return switch (locale.languageCode) {
    'ar' => 'العربية',
    _ => 'English',
  };
}

/// Sign-out tile shown only for authenticated users.
class SettingsLogoutTile extends StatelessWidget {
  const SettingsLogoutTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        return TilawaSettingsGroup(
          title: context.l10n.logout,
          children: [
            TilawaSettingsTile(
              icon: FluentIcons.sign_out_24_filled,
              iconColor: colorScheme.error,
              title: context.l10n.logout,
              onTap: onTap,
              showDivider: false,
              borderRadius: SettingsTileCorners.all(tokens),
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
            padding: EdgeInsets.symmetric(vertical: tokens.spaceSmall),
            child: Center(
              child: Text(
                context.l10n.version('…'),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Column(
          spacing: tokens.spaceExtraSmall,
          children: [
            Text(
              context.l10n.version(info.version),
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
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
        );
      },
    );
  }
}
