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

// ── Layout constants (no matching design token) ──────────────────────────────
const double _kAvatarSize = 60.0;
const double _kPersonIconSize = 32.0;
const double _kColorSwatchRadius = 12.0;
const double _kCustomSwatchSize = 24.0;
const int _kMaxConcurrentDownloads = 5;

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
  final tokens = Theme.of(context).tokens;
  showModalBottomSheet<void>(
    context: context,
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
              vertical: tokens.spaceLarge + tokens.spaceExtraSmall,
            ).copyWith(bottom: tokens.spaceExtraLarge),
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

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final UserEntity? user = state.maybeWhen(
          authenticated: (user) => user,
          orElse: () => null,
        );
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceExtraLarge,
            vertical: tokens.spaceLarge,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          ),
          child: Row(
            children: [
              Container(
                width: _kAvatarSize,
                height: _kAvatarSize,
                decoration: BoxDecoration(
                  color: foregroundColor.withValues(
                    alpha: tokens.opacitySubtle * 2,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: foregroundColor.withValues(
                      alpha: tokens.opacityMedium,
                    ),
                    width: tokens.spaceTiny,
                  ),
                ),
                child: Center(
                  child: Icon(
                    FluentIcons.person_32_filled,
                    size: _kPersonIconSize,
                    color: foregroundColor,
                  ),
                ),
              ),
              SizedBox(width: tokens.spaceLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? context.l10n.guestUser,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    Text(
                      user?.email ?? context.l10n.signInToSync,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: foregroundColor.withValues(
                          alpha: tokens.opacityGlass,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (user == null)
                IconButton(
                  onPressed: () => const LoginRoute().push(context),
                  icon: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? FluentIcons.arrow_left_24_filled
                        : FluentIcons.arrow_right_24_filled,
                    color: foregroundColor,
                  ),
                ),
            ],
          ),
        );
      },
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
              SizedBox(height: tokens.spaceLarge),
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
                    radius: _kColorSwatchRadius,
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
                leading: SizedBox.square(
                  dimension: _kCustomSwatchSize,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.red,
                          Colors.blue,
                          Colors.green,
                          Colors.red,
                        ],
                      ),
                    ),
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

    return Padding(
      padding: EdgeInsets.only(bottom: context.systemViewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: tokens.spaceLarge),
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
          SizedBox(height: tokens.spaceLarge),
          Text(
            context.l10n.concurrentDownloads,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          for (int i = 1; i <= _kMaxConcurrentDownloads; i++)
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
