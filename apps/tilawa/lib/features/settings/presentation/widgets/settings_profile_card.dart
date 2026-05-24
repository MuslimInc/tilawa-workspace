import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Pinterest-style profile header for the settings screen.
class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
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
        final String subtitle = isGuest
            ? context.l10n.signInToSync
            : context.l10n.settingsViewProfile;

        return TilawaCatalogSettingsProfileRow(
          avatar: SettingsProfileAvatar(photoUrl: user?.photoUrl),
          title: displayName,
          subtitle: subtitle,
          onTap: isGuest ? () => const LoginRoute().push(context) : null,
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
    const double size = 56;
    const double iconSize = 28;
    final trimmed = photoUrl?.trim() ?? '';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.surfaceContainerHigh,
      foregroundColor: colorScheme.onSurface,
      backgroundImage: trimmed.isNotEmpty
          ? CachedNetworkImageProvider(trimmed)
          : null,
      child: trimmed.isEmpty
          ? Icon(
              FluentIcons.person_24_regular,
              size: iconSize,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}
