import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/app_legal_urls.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa/shared/widgets/profile_avatar.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/di/injection.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../app_review/presentation/cubit/app_review_cubit.dart';
import '../../../app_review/presentation/cubit/app_review_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../theme/domain/app_theme_mode.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../../../quran_sessions/quran_sessions_feature_flags.dart';
import 'settings_teacher_capability_scope.dart';

String settingsMemberSinceLabel(BuildContext context, DateTime createdAt) {
  final locale = Localizations.localeOf(context).toString();
  final formatted = DateFormat.yMMM(locale).format(createdAt);
  return context.l10n.settingsMemberSince(formatted);
}

String settingsThemeLabel(ThemeState state, AppLocalizations l10n) {
  if (state.useSystemTheme) {
    return l10n.themeSystem;
  }
  return switch (state.mode) {
    AppThemeMode.dark => l10n.themeDark,
    AppThemeMode.light => l10n.themeLight,
  };
}

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
    FluentIcons.chevron_right_20_regular,
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
  String? fontFamily,
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
          fontFamily: fontFamily,
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
        final theme = Theme.of(context);
        final tokens = theme.tokens;
        final colorScheme = theme.colorScheme;
        final isGuest = user == null;
        final title = switch (user) {
          null => context.l10n.signInToSync,
          final u when u.displayName.trim().isNotEmpty => u.displayName.trim(),
          _ => context.l10n.guestUser,
        };
        final subtitle = switch (user) {
          null => null,
          final u => settingsMemberSinceLabel(context, u.createdAt),
        };
        final photoUrl = user?.photoUrl?.trim() ?? '';
        final VoidCallback onTap = isGuest
            ? () => const LoginRoute().push<void>(context)
            : () => const EditProfileRoute().push<void>(context);

        return TilawaSettingsGroupHorizontalInset(
          child: Semantics(
            button: true,
            child: TilawaCard(
              onTap: onTap,
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: Row(
                children: [
                  ProfileAvatar(
                    photoUrl: photoUrl,
                    displayName: user?.displayName,
                    size: tokens.iconHubExtent,
                  ),
                  SizedBox(width: tokens.spaceMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: tokens.spaceExtraSmall),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: tokens.textHeightLoose,
                            ),
                          ),
                        ],
                        if (!isGuest) ...[
                          const _SettingsAdminBadge(),
                          if (quranSessionsFeatureConfig()
                              .showProfileTeacherEntry)
                            _SettingsVerifiedTeacherBadge(isGuest: isGuest),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: tokens.spaceSmall),
                  if (isGuest)
                    Icon(
                      TilawaIcons.chevronRightSmall,
                      size: tokens.iconSizeSmall,
                      color: colorScheme.onSurfaceVariant,
                    )
                  else
                    TilawaIconBox(
                      icon: FluentIcons.edit_24_regular,
                      iconColor: colorScheme.primary,
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

class _SettingsAdminBadge extends StatefulWidget {
  const _SettingsAdminBadge();

  @override
  State<_SettingsAdminBadge> createState() => _SettingsAdminBadgeState();
}

class _SettingsAdminBadgeState extends State<_SettingsAdminBadge> {
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<AuthRepository>()) {
      return;
    }
    final bool isAdmin = await getIt<AuthRepository>().hasAdminClaim();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin != true) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSmall),
      child: Semantics(
        label: context.l10n.settingsAdminUserBadge,
        child: TilawaStatusChip(
          label: context.l10n.settingsAdminUserBadge,
          icon: Icons.admin_panel_settings_rounded,
          backgroundColor: colorScheme.semanticTintBackground(
            TilawaSemanticTint.ink,
          ),
          foregroundColor: colorScheme.semanticTintForeground(
            TilawaSemanticTint.ink,
          ),
        ),
      ),
    );
  }
}

class _SettingsVerifiedTeacherBadge extends StatelessWidget {
  const _SettingsVerifiedTeacherBadge({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    if (isGuest ||
        SettingsTeacherCapabilityScope.isTeachingSectionLoadingOf(context)) {
      return const SizedBox.shrink();
    }

    final capability = SettingsTeacherCapabilityScope.maybeCapabilityOf(
      context,
    );
    if (capability == null ||
        !capability.showsVerifiedTeacherBadgeInProfileHeader) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSmall),
      child: TilawaVerifiedTeacherBadge(
        label: context.quranSessionsL10n.verifiedTeacherBadge,
      ),
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
          TilawaFeedback.showToast(
            context,
            message: message,
            variant: TilawaFeedbackVariant.error,
          );
        }
      },
      builder: (context, state) {
        final tokens = Theme.of(context).tokens;

        return TilawaSettingsTile(
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

class SettingsShareAppTile extends StatefulWidget {
  const SettingsShareAppTile({
    super.key,
    this.isLast = false,
    required this.onShareRequested,
  });

  final bool isLast;
  final Future<void> Function() onShareRequested;

  @override
  State<SettingsShareAppTile> createState() => _SettingsShareAppTileState();
}

class _SettingsShareAppTileState extends State<SettingsShareAppTile> {
  bool _isSharing = false;

  Future<void> _shareApp() async {
    if (_isSharing) {
      return;
    }

    setState(() => _isSharing = true);

    try {
      await widget.onShareRequested();
    } catch (_) {
      if (mounted) {
        TilawaFeedback.showToast(
          context,
          message: context.l10n.shareTilawaFailed,
          variant: TilawaFeedbackVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return TilawaSettingsTile(
      title: context.l10n.shareTilawa,
      showDivider: !widget.isLast,
      trailing: _isSharing
          ? SizedBox(
              width: tokens.iconSizeSmall,
              height: tokens.iconSizeSmall,
              child: const TilawaLoadingIndicator(
                centered: false,
                strokeWidth: 2.0,
              ),
            )
          : _settingsChevronIcon(context),
      onTap: _shareApp,
    );
  }
}

class SettingsGuestAccountGroup extends StatelessWidget {
  const SettingsGuestAccountGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        return TilawaSettingsGroup(
          title: context.l10n.settingsLoginSection,
          leadingIcon: FluentIcons.person_24_regular,
          includeTopGap: false,
          children: [
            TilawaSettingsTile(
              title: context.l10n.signIn,
              onTap: () => const LoginRoute().push(context),
              showDivider: false,
            ),
          ],
        );
      },
    );
  }
}

Future<void> _runGuardedSettingsServerAction(
  BuildContext context, {
  required ServerActionType action,
  required FutureOr<void> Function() run,
  ServerActionGuard? serverActionGuard,
}) async {
  final guardResult = await (serverActionGuard ?? getIt<ServerActionGuard>())
      .ensureCanRun(action);
  if (!context.mounted) {
    return;
  }

  final Failure? blockedFailure = guardResult.fold(
    (failure) => failure,
    (_) => null,
  );
  if (blockedFailure != null) {
    TilawaFeedback.showToast(
      context,
      message:
          blockedFailure.localizedMessage(context) ??
          context.l10n.serverActionOfflineMessage,
      variant: TilawaFeedbackVariant.error,
    );
    return;
  }

  await run();
}

class SettingsLogoutAppBarAction extends StatefulWidget {
  const SettingsLogoutAppBarAction({
    super.key,
    required this.onLogout,
    this.serverActionGuard,
  });

  final FutureOr<void> Function() onLogout;
  final ServerActionGuard? serverActionGuard;

  @override
  State<SettingsLogoutAppBarAction> createState() =>
      _SettingsLogoutAppBarActionState();
}

class _SettingsLogoutAppBarActionState
    extends State<SettingsLogoutAppBarAction> {
  bool _actionCheckInProgress = false;

  Future<void> _onLogoutPressed() async {
    if (_actionCheckInProgress) {
      return;
    }

    setState(() => _actionCheckInProgress = true);
    try {
      await _runGuardedSettingsServerAction(
        context,
        action: ServerActionType.logout,
        serverActionGuard: widget.serverActionGuard,
        run: widget.onLogout,
      );
    } finally {
      if (mounted) {
        setState(() => _actionCheckInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        return TilawaIconActionButton(
          icon: FluentIcons.sign_out_24_regular,
          tooltip: context.l10n.logout,
          enabled: !_actionCheckInProgress,
          onTap: () => unawaited(_onLogoutPressed()),
        );
      },
    );
  }
}

class SettingsAccountActions extends StatefulWidget {
  const SettingsAccountActions({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
    this.serverActionGuard,
  });

  final FutureOr<void> Function() onLogout;
  final FutureOr<void> Function() onDeleteAccount;
  final ServerActionGuard? serverActionGuard;

  @override
  State<SettingsAccountActions> createState() => _SettingsAccountActionsState();
}

class _SettingsAccountActionsState extends State<SettingsAccountActions> {
  bool _actionCheckInProgress = false;

  Future<void> _guardAndRun(
    ServerActionType action,
    FutureOr<void> Function() run,
  ) async {
    if (_actionCheckInProgress) {
      return;
    }

    setState(() => _actionCheckInProgress = true);
    try {
      await _runGuardedSettingsServerAction(
        context,
        action: action,
        serverActionGuard: widget.serverActionGuard,
        run: run,
      );
    } finally {
      if (mounted) {
        setState(() => _actionCheckInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final tokens = context.tokens;
        final colorScheme = Theme.of(context).colorScheme;

        return TilawaSettingsGroupHorizontalInset(
          child: Padding(
            padding: EdgeInsets.only(top: tokens.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceSmall,
              children: [
                TilawaButton(
                  text: context.l10n.logout,
                  variant: TilawaButtonVariant.primary,
                  backgroundColor: colorScheme.onSurface,
                  foregroundColor: colorScheme.surface,
                  isFullWidth: true,
                  onPressed: () => unawaited(
                    _guardAndRun(ServerActionType.logout, widget.onLogout),
                  ),
                ),
                TilawaButton(
                  text: context.l10n.deleteAccount,
                  variant: TilawaButtonVariant.dangerOutline,
                  isFullWidth: true,
                  onPressed: () => unawaited(
                    _guardAndRun(
                      ServerActionType.deleteAccount,
                      widget.onDeleteAccount,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsLegalSection extends StatelessWidget {
  const SettingsLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TilawaSettingsGroup(
      title: l10n.settingsLegalSection,
      children: [
        TilawaSettingsTile(
          title: l10n.privacyPolicy,
          onTap: () => openLegalUrl(AppLegalUrls.privacyPolicy),
          showDivider: false,
        ),
      ],
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
            tokens.spaceMedium,
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
