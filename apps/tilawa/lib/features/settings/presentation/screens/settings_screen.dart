import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../color_picker/color_picker.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../../../theme/domain/primary_color_preset.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';
import '../cubit/settings_cubit.dart';

// ── Top-level sheet / dialog helpers ─────────────────────────────────────────

void _showColorPicker(
  BuildContext context,
  Color currentColor,
  PrimaryColorSource currentSource,
  String? currentPresetId,
) {
  final tokens = Theme.of(context).tokens;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens.radiusExtraLarge),
      ),
    ),
    builder: (sheetContext) => _ColorPickerSheet(
      currentColor: currentColor,
      currentSource: currentSource,
      currentPresetId: currentPresetId,
      onCustomColorTap: () {
        Navigator.pop(sheetContext);
        _showCustomColorPicker(context, currentColor);
      },
    ),
  );
}

void _showCustomColorPicker(BuildContext context, Color currentColor) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      var pickerColor = currentColor;
      return AlertDialog(
        title: Text(ctx.l10n.choosePrimaryColor),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ctx.read<ThemeCubit>().setPrimaryColor(pickerColor);
              Navigator.of(ctx).pop();
            },
            child: Text(ctx.l10n.save),
          ),
        ],
      );
    },
  );
}

void _showLanguagePicker(BuildContext context, Locale currentLocale) {
  final theme = Theme.of(context);
  final tokens = theme.tokens;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens.radiusExtraLarge),
      ),
    ),
    builder: (_) => _LanguagePickerSheet(currentLocale: currentLocale),
  );
}

void _showConcurrentDownloadsPicker(BuildContext context, int currentValue) {
  final tokens = Theme.of(context).tokens;
  showModalBottomSheet<void>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens.radiusExtraLarge),
      ),
    ),
    builder: (_) => _ConcurrentDownloadsSheet(currentValue: currentValue),
  );
}

void _showLogoutDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.logout),
      content: Text(ctx.l10n.logoutConfirmation),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ctx.read<AuthBloc>().add(const SignOutEvent());
          },
          child: Text(
            ctx.l10n.logout,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}

String _localizedPresetName(BuildContext context, PrimaryColorPreset preset) {
  final AppLocalizations l10n = context.l10n;
  return switch (preset) {
    PrimaryColorPreset.teal => l10n.colorCyan,
    PrimaryColorPreset.sage => l10n.colorGreen,
    PrimaryColorPreset.brown => l10n.colorBrown,
    PrimaryColorPreset.purple => l10n.colorPurple,
  };
}

String _formatPrimaryColorHex(Color color) {
  final int rgb = color.toARGB32() & 0x00FFFFFF;
  final String hex = rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  return '#$hex';
}

String _primaryColorTileSubtitle(BuildContext context, ThemeState state) {
  if (state.primaryColorSource == PrimaryColorSource.custom) {
    return '${context.l10n.custom} · ${_formatPrimaryColorHex(state.primaryColor)}';
  }

  final preset =
      PrimaryColorPreset.findById(state.primaryPresetId) ??
      PrimaryColorPreset.defaultPreset;
  return _localizedPresetName(context, preset);
}

class _PrimaryColorTileTrailing extends StatelessWidget {
  const _PrimaryColorTileTrailing({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final designTokens = theme.tokens;
    final settingsTokens = theme.componentTokens.settingsGroup;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: settingsTokens.tileIconSize,
          height: settingsTokens.tileIconSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: designTokens.opacityMedium,
              ),
              width: designTokens.spaceTiny,
            ),
          ),
        ),
        SizedBox(width: designTokens.spaceSmall),
        Icon(
          FluentIcons.chevron_right_24_filled,
          size: settingsTokens.tileTrailingSize,
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: settingsTokens.tileTrailingOpacity,
          ),
        ),
      ],
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            state.when(
              initial: () {},
              loading: () {},
              authenticated: (_) {},
              unauthenticated: () => const LoginRoute().go(context),
              error: (message) => ToastUtils.showErrorToast(message),
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: context.canPop() ? const TilawaBackButton() : null,
          title: Text(context.l10n.settings),
        ),
        body: TilawaContentBounds(
          kind: TilawaContentKind.settings,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLarge,
              vertical: tokens.spaceLarge,
            ).copyWith(bottom: tokens.spaceExtraLarge + tokens.spaceLarge),
            child: Column(
              children: [
                const _SettingsProfileCard(),
                SizedBox(height: tokens.spaceLarge * 2),

                // Appearance Group (Theme & Language)
                TilawaSettingsGroup(
                  title: context.l10n.appearance.toUpperCase(),
                  children: [
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            TilawaSettingsSwitchTile(
                              icon: FluentIcons.dark_theme_24_regular,
                              iconColor: AppColors.settingsTheme,
                              title: context.l10n.darkTheme,
                              value: state.mode == ThemeMode.dark,
                              onChanged: (value) =>
                                  context.read<ThemeCubit>().toggleDark(value),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(tokens.radiusLarge),
                              ),
                            ),
                            TilawaSettingsTile(
                              icon: FluentIcons.color_24_regular,
                              iconColor: AppColors.settingsColor,
                              title: context.l10n.primaryColor,
                              subtitle: _primaryColorTileSubtitle(
                                context,
                                state,
                              ),
                              trailing: _PrimaryColorTileTrailing(
                                color: state.primaryColor,
                              ),
                              onTap: () => _showColorPicker(
                                context,
                                state.primaryColor,
                                state.primaryColorSource,
                                state.primaryPresetId,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    BlocBuilder<LocalizationBloc, LocalizationState>(
                      builder: (context, state) {
                        return TilawaSettingsTile(
                          icon: FluentIcons.local_language_24_regular,
                          iconColor: AppColors.settingsLanguage,
                          title: context.l10n.language,
                          onTap: () =>
                              _showLanguagePicker(context, state.locale),
                          showDivider: false,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(tokens.radiusLarge),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: tokens.spaceExtraLarge),

                // Audio Group
                TilawaSettingsGroup(
                  title: context.l10n.audioSettings.toUpperCase(),
                  children: [
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            TilawaSettingsSwitchTile(
                              icon: FluentIcons.history_24_regular,
                              iconColor: AppColors.settingsPlayback,
                              title: context.l10n.restorePlaybackState,
                              value: state.restorePlaybackState,
                              onChanged: (value) => context
                                  .read<SettingsCubit>()
                                  .toggleRestorePlaybackState(value),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(tokens.radiusLarge),
                              ),
                            ),
                            TilawaSettingsSwitchTile(
                              icon: FluentIcons.timer_24_regular,
                              iconColor: AppColors.settingsDuration,
                              title: context.l10n.enableRecitationDuration,
                              value: state.isSleepTimerEnabled,
                              onChanged: (value) => context
                                  .read<SettingsCubit>()
                                  .toggleSleepTimerEnabled(value),
                              showDivider: false,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(tokens.radiusLarge),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: tokens.spaceExtraLarge),

                // Features Group
                TilawaSettingsGroup(
                  title: context.l10n.features.toUpperCase(),
                  children: [
                    TilawaSettingsTile(
                      icon: FluentIcons.bookmark_24_regular,
                      iconColor: AppColors.settingsBookmarks,
                      title: context.l10n.bookmarks,
                      onTap: () => const BookmarksRoute().push(context),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(tokens.radiusLarge),
                      ),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.history_24_regular,
                      iconColor: AppColors.settingsHistory,
                      title: context.l10n.listeningHistory,
                      onTap: () => const HistoryRoute().push(context),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.clock_24_regular,
                      iconColor: AppColors.settingsPrayer,
                      title: context.l10n.prayerTimes,
                      onTap: () => const PrayerTimesRoute().push(context),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.book_24_regular,
                      iconColor: AppColors.settingsQuran,
                      title: context.l10n.quranReader,
                      onTap: () => const QuranLastReadRoute().push(context),
                      showDivider: false,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(tokens.radiusLarge),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: tokens.spaceExtraLarge),

                // Downloads Group
                TilawaSettingsGroup(
                  title: context.l10n.downloads.toUpperCase(),
                  children: [
                    TilawaSettingsTile(
                      icon: FluentIcons.folder_24_regular,
                      iconColor: AppColors.settingsStorage,
                      title: context.l10n.manageStorage,
                      onTap: () => const DownloadsRoute().push(context),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(tokens.radiusLarge),
                      ),
                    ),
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return TilawaSettingsTile(
                          icon: FluentIcons.arrow_download_24_regular,
                          iconColor: AppColors.settingsDownloads,
                          title: context.l10n.concurrentDownloads,
                          onTap: () => _showConcurrentDownloadsPicker(
                            context,
                            state.maxConcurrentDownloads,
                          ),
                          showDivider: false,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(tokens.radiusLarge),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: tokens.spaceLarge * 2),
                const _LogoutButton(),

                if (kDebugMode) ...[
                  SizedBox(height: tokens.spaceLarge * 2),
                  TilawaSettingsTile(
                    icon: Icons.list_alt_rounded,
                    title: 'Route List (Dev)',
                    onTap: () => const RouteListRoute().push(context),
                    borderRadius: BorderRadius.circular(tokens.radiusLarge),
                    showDivider: false,
                  ),
                ],

                SizedBox(height: tokens.spaceLarge * 2),
                const _AppVersionInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _SettingsProfileCard extends StatelessWidget {
  const _SettingsProfileCard();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = context.colorScheme;
    final foregroundColor = colorScheme.onPrimary;
    final borderRadius = BorderRadius.circular(tokens.radiusExtraLarge);

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

        final Color primary = colorScheme.primary;
        final Color gradientHi = Color.lerp(
          primary,
          Colors.white,
          context.isDarkMode ? 0.1 : 0.16,
        )!;
        final Color gradientLo = Color.lerp(
          primary,
          Colors.black,
          context.isDarkMode ? 0.14 : 0.05,
        )!;

        void onGuestTap() => const LoginRoute().push(context);

        final Widget card = Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(
                  alpha: context.isDarkMode ? 0.45 : 0.28,
                ),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: -10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isGuest ? onGuestTap : null,
                mouseCursor: isGuest
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                splashColor: foregroundColor.withValues(
                  alpha: tokens.opacityMedium,
                ),
                highlightColor: foregroundColor.withValues(
                  alpha: tokens.opacitySubtle * 2,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gradientHi, gradientLo],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceExtraLarge,
                      vertical: tokens.spaceLarge + tokens.spaceExtraSmall,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SettingsProfileAvatar(
                          tokens: tokens,
                          foregroundColor: foregroundColor,
                          photoUrl: user?.photoUrl,
                        ),
                        SizedBox(
                          width: tokens.spaceLarge + tokens.spaceSmall,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                  color: foregroundColor,
                                ),
                              ),
                              SizedBox(height: tokens.spaceExtraSmall),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: foregroundColor.withValues(
                                    alpha: tokens.opacityGlass,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isGuest) ...[
                          SizedBox(width: tokens.spaceSmall),
                          _GuestSignInPill(
                            foregroundColor: foregroundColor,
                            tokens: tokens,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        if (isGuest) {
          return Semantics(
            button: true,
            excludeSemantics: true,
            label: '${context.l10n.guestUser}. ${context.l10n.signInToSync}',
            hint: context.l10n.signIn,
            child: card,
          );
        }
        return card;
      },
    );
  }
}

/// Circular avatar with light elevation and Google / placeholder content.
class _SettingsProfileAvatar extends StatelessWidget {
  const _SettingsProfileAvatar({
    required this.tokens,
    required this.foregroundColor,
    required this.photoUrl,
  });

  final TilawaDesignTokens tokens;
  final Color foregroundColor;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final double size = TilawaSettingsScreenTokens.profileAvatarSize;
    final String trimmed = photoUrl?.trim() ?? '';
    final bool hasPhoto = trimmed.isNotEmpty;

    return Material(
      elevation: context.isDarkMode ? 5 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      color: foregroundColor.withValues(
        alpha: tokens.opacitySubtle * 2,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size,
        height: size,
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: trimmed,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: tokens.spaceLarge,
                    height: tokens.spaceLarge,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foregroundColor.withValues(
                        alpha: tokens.opacityGlass,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    FluentIcons.person_32_filled,
                    size: TilawaSettingsScreenTokens.profilePersonIconSize,
                    color: foregroundColor,
                  ),
                ),
              )
            : Center(
                child: Icon(
                  FluentIcons.person_32_filled,
                  size: TilawaSettingsScreenTokens.profilePersonIconSize,
                  color: foregroundColor,
                ),
              ),
      ),
    );
  }
}

class _GuestSignInPill extends StatelessWidget {
  const _GuestSignInPill({
    required this.foregroundColor,
    required this.tokens,
  });

  final Color foregroundColor;
  final TilawaDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final IconData arrow = rtl
        ? FluentIcons.arrow_left_16_filled
        : FluentIcons.arrow_right_16_filled;

    return IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            color: foregroundColor.withValues(
              alpha: tokens.opacityMedium + tokens.opacitySubtle,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMedium,
              vertical: tokens.spaceSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.signIn,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: tokens.spaceExtraSmall),
                Icon(
                  arrow,
                  size: tokens.iconSizeSmall,
                  color: foregroundColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = context.colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        return Material(
          color: colorScheme.errorContainer.withValues(
            alpha: context.isDarkMode ? 0.16 : 0.58,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          child: InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.sign_out_24_filled,
                    color: colorScheme.error,
                    size: tokens.iconSizeMedium,
                  ),
                  SizedBox(width: tokens.spaceMedium),
                  Text(
                    context.l10n.logout,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
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

class _AppVersionInfo extends StatelessWidget {
  const _AppVersionInfo();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final version = state.appInfo?.version ?? '...';
        final buildNumber = state.appInfo?.buildNumber ?? '...';
        return Column(
          children: [
            Text(
              context.l10n.version(version),
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface.withValues(
                  alpha: tokens.opacityMedium + tokens.opacitySubtle * 2,
                ),
              ),
            ),
            SizedBox(height: tokens.spaceExtraSmall),
            Text(
              context.l10n.build(buildNumber),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withValues(
                  alpha: tokens.opacityMedium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet({
    required this.currentColor,
    required this.currentSource,
    required this.currentPresetId,
    required this.onCustomColorTap,
  });

  final Color currentColor;
  final PrimaryColorSource currentSource;
  final String? currentPresetId;
  final VoidCallback onCustomColorTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final isCustom = currentSource == PrimaryColorSource.custom;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TilawaSheetHandle(),
              Text(
                context.l10n.choosePrimaryColor,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: tokens.spaceLarge),
              ...PrimaryColorPreset.values.map((preset) {
                final isSelected = !isCustom && currentPresetId == preset.id;
                return TilawaSelectionTile(
                  leading: CircleAvatar(
                    backgroundColor: preset.value,
                    radius: TilawaSettingsScreenTokens
                        .primaryPickerPresetSwatchRadius,
                  ),
                  title: _localizedPresetName(context, preset),
                  isSelected: isSelected,
                  onTap: () {
                    context.read<ThemeCubit>().setPrimaryPreset(preset);
                    Navigator.pop(context);
                  },
                );
              }),
              TilawaSelectionTile(
                leading: CircleAvatar(
                  radius: TilawaSettingsScreenTokens
                      .primaryPickerPresetSwatchRadius,
                  backgroundColor: isCustom
                      ? currentColor
                      : colorScheme.surfaceContainerHigh,
                  child: isCustom
                      ? null
                      : Icon(
                          FluentIcons.color_24_regular,
                          size:
                              TilawaSettingsScreenTokens
                                  .primaryPickerCustomSwatchSize *
                              0.5,
                          color: colorScheme.primary,
                        ),
                ),
                title: context.l10n.custom,
                isSelected: isCustom,
                onTap: onCustomColorTap,
              ),
              SizedBox(height: tokens.spaceLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({required this.currentLocale});

  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: context.systemViewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TilawaSheetHandle(),
            Text(
              context.l10n.chooseLanguage,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            TilawaSelectionTile(
              title: 'العربية',
              isSelected: currentLocale.languageCode == arabicLanguageCode,
              onTap: () {
                context.read<LocalizationBloc>().add(
                  const ChangeLanguage(Locale(arabicLanguageCode)),
                );
                Navigator.pop(context);
              },
            ),
            TilawaSelectionTile(
              title: 'English',
              isSelected: currentLocale.languageCode == englishLanguageCode,
              onTap: () {
                context.read<LocalizationBloc>().add(
                  const ChangeLanguage(Locale(englishLanguageCode)),
                );
                Navigator.pop(context);
              },
            ),
            SizedBox(height: tokens.spaceLarge),
          ],
        ),
      ),
    );
  }
}

class _ConcurrentDownloadsSheet extends StatelessWidget {
  const _ConcurrentDownloadsSheet({required this.currentValue});

  final int currentValue;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TilawaSheetHandle(),
          Text(
            context.l10n.concurrentDownloads,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          for (
            int i = 1;
            i <= TilawaSettingsScreenTokens.maxConcurrentDownloadsPickerCount;
            i++
          )
            TilawaSelectionTile(
              title: '$i',
              isSelected: currentValue == i,
              onTap: () {
                context.read<SettingsCubit>().setMaxConcurrentDownloads(i);
                Navigator.pop(context);
              },
            ),
          SizedBox(height: tokens.spaceLarge),
        ],
      ),
    );
  }
}
