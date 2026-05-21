import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/bootstrap/app_launch_config.dart';
import '../../../../router/app_router_config.dart';
import 'package:tilawa_core/di/injection.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Profile header for the settings screen.
class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final UserEntity? user = state.maybeWhen(
          authenticated: (user) => user,
          orElse: () => null,
        );
        final bool isGuest = user == null;
        final String displayName =
            user != null && user.displayName.trim().isNotEmpty
            ? user.displayName.trim()
            : context.l10n.guestUser;
        final String subtitle = user != null && user.email.trim().isNotEmpty
            ? user.email.trim()
            : context.l10n.signInToSync;

        return Material(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isGuest ? () => const LoginRoute().push(context) : null,
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceLarge),
              child: Row(
                children: [
                  SettingsProfileAvatar(photoUrl: user?.photoUrl),
                  SizedBox(width: tokens.spaceLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: tokens.spaceExtraSmall,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: tokens.opacityEmphasis,
                            ),
                          ),
                        ),
                        if (getIt<AppLaunchConfig>().supportTilawaEnabled)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed: () =>
                                  const SupportRoute().push(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: colorScheme.onPrimaryContainer,
                              ),
                              child: Text(
                                context.l10n.supportTilawa,
                                style: context.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isGuest)
                    Icon(
                      FluentIcons.chevron_right_24_filled,
                      color: colorScheme.onPrimaryContainer,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SettingsProfileAvatar extends StatelessWidget {
  const SettingsProfileAvatar({super.key, this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final size = TilawaSettingsScreenTokens.profileAvatarSize;
    final iconSize = TilawaSettingsScreenTokens.profilePersonIconSize;
    final trimmed = photoUrl?.trim() ?? '';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primary.withValues(
        alpha: tokens.opacityMedium,
      ),
      foregroundColor: colorScheme.onPrimary,
      backgroundImage: trimmed.isNotEmpty ? CachedNetworkImageProvider(trimmed) : null,
      child: trimmed.isEmpty
          ? Icon(FluentIcons.person_32_filled, size: iconSize)
          : null,
    );
  }
}
