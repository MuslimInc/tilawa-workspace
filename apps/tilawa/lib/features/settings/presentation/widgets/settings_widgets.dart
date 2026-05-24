import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../app_review/presentation/cubit/app_review_cubit.dart';
import '../../../app_review/presentation/cubit/app_review_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/settings_cubit.dart';

String settingsLanguageLabel(Locale locale, AppLocalizations l10n) {
  return switch (locale.languageCode) {
    'ar' => 'العربية',
    _ => 'English',
  };
}

Icon _settingsChevronIcon(BuildContext context) {
  final theme = Theme.of(context);
  final groupTokens = theme.componentTokens.settingsGroup;

  return Icon(
    FluentIcons.chevron_right_24_filled,
    size: groupTokens.tileTrailingSize,
    color: theme.colorScheme.onSurfaceVariant.withValues(
      alpha: (groupTokens.tileTrailingOpacity * 1.35).clamp(0.45, 0.72),
    ),
  );
}

Widget settingsColorTrailing(BuildContext context, Color color) {
  final tokens = Theme.of(context).tokens;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SettingsPrimaryColorDot(color: color),
      SizedBox(width: tokens.spaceSmall),
      _settingsChevronIcon(context),
    ],
  );
}

Widget settingsPickerTrailing(
  BuildContext context, {
  required String value,
  Widget? leading,
}) {
  final theme = Theme.of(context);
  final tokens = theme.tokens;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (leading != null) ...[
        leading,
        SizedBox(width: tokens.spaceSmall),
      ],
      Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(
            alpha: tokens.opacityEmphasis,
          ),
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(width: tokens.spaceSmall),
      _settingsChevronIcon(context),
    ],
  );
}

class SettingsPrimaryColorDot extends StatelessWidget {
  const SettingsPrimaryColorDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double size = 22;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: theme.tokens.opacityMedium,
          ),
          width: theme.tokens.borderWidthThin,
        ),
      ),
    );
  }
}

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final UserEntity? user = state.maybeWhen(
          authenticated: (user) => user,
          orElse: () => null,
        );
        final title = switch (user) {
          null => context.l10n.signInToSync,
          final u when u.displayName.trim().isNotEmpty => u.displayName.trim(),
          _ => context.l10n.guestUser,
        };
        final isGuest = user == null;
        final photoUrl = user?.photoUrl?.trim() ?? '';

        return TilawaSettingsGroupHorizontalInset(
          child: TilawaSettingsGroupPanel(
            children: [
              TilawaCatalogSettingsProfileRow(
                avatar: _ProfileAvatar(photoUrl: photoUrl),
                title: title,
                onTap: isGuest ? () => const LoginRoute().push(context) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const size = 56.0;
    const iconSize = 28.0;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.surfaceContainerHigh,
      foregroundColor: colorScheme.onSurface,
      backgroundImage: photoUrl.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl)
          : null,
      child: photoUrl.isEmpty
          ? Icon(
              FluentIcons.person_24_regular,
              size: iconSize,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}

class SettingsRateAppTile extends StatelessWidget {
  const SettingsRateAppTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppReviewCubit, AppReviewState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) {
        final message = state.failure?.localizedMessage(context);
        if (message != null) {
          ToastUtils.showErrorToast(message);
        }
      },
      builder: (context, state) {
        final tokens = Theme.of(context).tokens;

        return TilawaSettingsTile(
          icon: FluentIcons.star_24_regular,
          title: context.l10n.rateTilawa,
          showDivider: !isLast,
          trailing: state.isBusy
              ? SizedBox(
                  width: tokens.iconSizeSmall,
                  height: tokens.iconSizeSmall,
                  child: const TilawaLoadingIndicator(centered: false),
                )
              : _settingsChevronIcon(context),
          onTap: () {
            if (!state.isBusy) {
              context.read<AppReviewCubit>().rateFromSettings();
            }
          },
        );
      },
    );
  }
}

class SettingsLogoutSection extends StatelessWidget {
  const SettingsLogoutSection({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        return TilawaSettingsGroup(
          title: context.l10n.settingsYourAccount,
          children: [
            TilawaSettingsTile(
              icon: FluentIcons.sign_out_24_regular,
              title: context.l10n.logout,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: onLogout,
              showDivider: false,
            ),
          ],
        );
      },
    );
  }
}

class SettingsVersionFooter extends StatelessWidget {
  const SettingsVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final textStyle = context.textTheme.bodySmall?.copyWith(color: muted);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final info = state.appInfo;
        final version = info?.version ?? '…';
        final build = info?.buildNumber;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceMedium,
            tokens.spaceLarge,
            tokens.spaceMedium,
            tokens.spaceExtraLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceExtraSmall,
            children: [
              Text(
                context.l10n.version(version),
                style: textStyle,
                textAlign: TextAlign.center,
              ),
              if (build != null)
                Text(
                  context.l10n.build(build),
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        );
      },
    );
  }
}
