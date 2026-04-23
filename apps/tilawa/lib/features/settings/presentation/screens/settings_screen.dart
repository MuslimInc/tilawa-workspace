import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../router/app_router_config.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../color_picker/color_picker.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';
import '../cubit/settings_cubit.dart';

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
              unauthenticated: () {
                // Navigate to login on logout
                const LoginRoute().go(context);
              },
              error: (message) {
                ToastUtils.showErrorToast(message);
              },
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(context.l10n.settings)),
        body: TilawaContentBounds(
          kind: TilawaContentKind.settings,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLarge,
              vertical: tokens.spaceLarge + tokens.spaceExtraSmall,
            ).copyWith(bottom: TilawaShellPadding.of(context) + 20),
            child: Column(
              children: [
                // User Profile Section
                _buildProfileSection(context),
                SizedBox(height: tokens.spaceLarge * 2),

                // General Group (Theme & Language)
                TilawaSettingsGroup(
                  title: context.l10n.appearance.toUpperCase(),
                  children: [
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            TilawaSettingsTile(
                              icon: FluentIcons.dark_theme_24_regular,
                              iconColor: AppColors.settingsTheme,
                              title: context.l10n.theme,
                              subtitle: _getThemeName(context, state.mode),
                              onTap: () =>
                                  _showThemePicker(context, state.mode),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            TilawaSettingsTile(
                              icon: FluentIcons.color_24_regular,
                              iconColor: AppColors.settingsColor,
                              title: context.l10n.primaryColor,
                              subtitle: _getColorName(
                                context,
                                state.primaryColor,
                              ),
                              onTap: () =>
                                  _showColorPicker(context, state.primaryColor),
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
                          subtitle: state.locale.languageCode == 'ar'
                              ? context.l10n.arabic
                              : context.l10n.english,
                          onTap: () =>
                              _showLanguagePicker(context, state.locale),
                          showDivider: false,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
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
                              subtitle:
                                  context.l10n.restorePlaybackStateSubtitle,
                              value: state.restorePlaybackState,
                              onChanged: (value) {
                                context
                                    .read<SettingsCubit>()
                                    .toggleRestorePlaybackState(value);
                              },
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            TilawaSettingsSwitchTile(
                              icon: FluentIcons.timer_24_regular,
                              iconColor: AppColors.settingsDuration,
                              title: context.l10n.enableRecitationDuration,
                              subtitle:
                                  context.l10n.enableRecitationDurationSubtitle,
                              value: state.isSleepTimerEnabled,
                              onChanged: (value) {
                                context
                                    .read<SettingsCubit>()
                                    .toggleSleepTimerEnabled(value);
                              },
                              showDivider: false,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16),
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
                      subtitle: context.l10n.noBookmarksHint,
                      onTap: () => const BookmarksRoute().push(context),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.history_24_regular,
                      iconColor: AppColors.settingsHistory,
                      title: context.l10n.listeningHistory,
                      subtitle: context.l10n.noHistoryDescription,
                      onTap: () => const HistoryRoute().push(context),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.clock_24_regular,
                      iconColor: AppColors.settingsPrayer,
                      title: context.l10n.prayerTimes,
                      subtitle: context.l10n.locationRequiredDescription,
                      onTap: () => const PrayerTimesRoute().push(context),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.book_24_regular,
                      iconColor: AppColors.settingsQuran,
                      title: context.l10n.quranReader,
                      subtitle: context.l10n.continueReading,
                      onTap: () => const QuranLastReadRoute().push(context),
                      showDivider: false,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
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
                      subtitle: context.l10n.manageStorageSubtitle,
                      onTap: () => const DownloadsRoute().push(context),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            TilawaSettingsSwitchTile(
                              icon: Icons.wifi_rounded,
                              iconColor: AppColors.settingsDownloads,
                              title: _getQuranAssetPrefetchTitle(context),
                              subtitle: _getQuranAssetPrefetchSubtitle(context),
                              value: state.prefetchQuranAssetsOnWifiOnly,
                              onChanged: (value) {
                                context
                                    .read<SettingsCubit>()
                                    .togglePrefetchQuranAssetsOnWifiOnly(value);
                              },
                            ),
                            TilawaSettingsTile(
                              icon: FluentIcons.arrow_download_24_regular,
                              iconColor: AppColors.settingsDownloads,
                              title: context.l10n.concurrentDownloads,
                              subtitle: context.l10n
                                  .concurrentDownloadsSubtitle(
                                    state.maxConcurrentDownloads,
                                  ),
                              onTap: () => _showConcurrentDownloadsPicker(
                                context,
                                state.maxConcurrentDownloads,
                              ),
                              showDivider: false,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: tokens.spaceLarge * 2),

                // Logout Button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthAuthenticated) {
                      return Material(
                        color: context.isDarkMode
                            ? context.theme.cardColor
                            : AppColors.logoutBackground,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => _showLogoutDialog(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  FluentIcons.sign_out_24_filled,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  context.l10n.logout,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Route List (Dev)
                if (kDebugMode) ...[
                  SizedBox(height: tokens.spaceLarge * 2),
                  TilawaSettingsTile(
                    icon: Icons.list_alt_rounded,
                    title: 'Route List (Dev)',
                    onTap: () => const RouteListRoute().push(context),
                    borderRadius: BorderRadius.circular(16),
                    showDivider: false,
                  ),
                ],

                SizedBox(height: 32),

                // App Version Section
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    final version = state.appInfo?.version ?? '...';
                    final buildNumber = state.appInfo?.buildNumber ?? '...';
                    return Column(
                      children: [
                        Text(
                          context.l10n.version(version),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: tokens.spaceExtraSmall),
                        Text(
                          context.l10n.build(buildNumber),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final UserEntity? user = state.maybeWhen(
          authenticated: (user) => user,
          orElse: () => null,
        );
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colorScheme.primary,
                context.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.profileGradientStart.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    FluentIcons.person_32_filled,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? context.l10n.guestUser,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.email ?? context.l10n.signInToSync,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (user == null)
                IconButton(
                  onPressed: () => const LoginRoute().push(context),
                  icon: const Icon(
                    FluentIcons.arrow_right_24_filled,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return context.l10n.systemTheme;
      case ThemeMode.light:
        return context.l10n.lightTheme;
      case ThemeMode.dark:
        return context.l10n.darkTheme;
    }
  }

  void _showThemePicker(BuildContext context, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text(
              context.l10n.chooseTheme,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _ThemeOption(
              title: context.l10n.systemTheme,
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (val) {
                context.read<ThemeCubit>().setMode(val);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: context.l10n.lightTheme,
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (val) {
                context.read<ThemeCubit>().setMode(val);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: context.l10n.darkTheme,
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (val) {
                context.read<ThemeCubit>().setMode(val);
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getColorName(BuildContext context, Color color) {
    // Check if the color is in options
    final bool isKnownColor = ThemeCubit.colorOptions.any(
      (element) => element.color.toARGB32() == color.toARGB32(),
    );

    if (!isKnownColor) {
      return context.l10n.custom;
    }

    final AppColorOption option = ThemeCubit.colorOptions.firstWhere(
      (element) => element.color.toARGB32() == color.toARGB32(),
      orElse: () => ThemeCubit.colorOptions.first,
    );
    return _getLocalizedColorName(context, option.name);
  }

  String _getLocalizedColorName(BuildContext context, String name) {
    final AppLocalizations l10n = context.l10n;
    return switch (name) {
      'Cyan' => l10n.colorCyan,
      'Green' => l10n.colorGreen,
      'Brown' => l10n.colorBrown,
      'Purple' => l10n.colorPurple,
      _ => name,
    };
  }

  String _getQuranAssetPrefetchTitle(BuildContext context) {
    return context.l10n.localeName == 'ar'
        ? 'تهيئة أصول القرآن مسبقًا عبر الواي فاي فقط'
        : 'Prefetch Quran assets on Wi-Fi only';
  }

  String _getQuranAssetPrefetchSubtitle(BuildContext context) {
    return context.l10n.localeName == 'ar'
        ? 'حمّل خطوط وصور المصحف في الخلفية قبل فتح القارئ عند الاتصال بالواي فاي.'
        : 'Prepare Quran fonts and reader images in the background before opening the reader when connected to Wi-Fi.';
  }

  void _showColorPicker(BuildContext context, Color currentColor) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        final height = MediaQuery.of(sheetContext).size.height;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height * 0.85),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16),
                  Text(
                    context.l10n.choosePrimaryColor,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...ThemeCubit.colorOptions.map((option) {
                    final isSelected =
                        option.color.toARGB32() == currentColor.toARGB32();
                    return ListTile(
                      onTap: () {
                        context.read<ThemeCubit>().setPrimaryColor(
                          option.color,
                        );
                        Navigator.pop(sheetContext);
                      },
                      leading: CircleAvatar(
                        backgroundColor: option.color,
                        radius: 12,
                      ),
                      title: Text(
                        _getLocalizedColorName(context, option.name),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? option.color : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              FluentIcons.checkmark_24_regular,
                              color: option.color,
                            )
                          : null,
                    );
                  }),
                  // Custom Color Option
                  ListTile(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showCustomColorPicker(context, currentColor);
                    },
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
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
                    title: Text(
                      context.l10n.custom,
                      style: TextStyle(
                        fontWeight:
                            !ThemeCubit.colorOptions.any(
                              (opt) =>
                                  opt.color.toARGB32() ==
                                  currentColor.toARGB32(),
                            )
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color:
                            !ThemeCubit.colorOptions.any(
                              (opt) =>
                                  opt.color.toARGB32() ==
                                  currentColor.toARGB32(),
                            )
                            ? currentColor
                            : null,
                      ),
                    ),
                    trailing:
                        !ThemeCubit.colorOptions.any(
                          (opt) =>
                              opt.color.toARGB32() == currentColor.toARGB32(),
                        )
                        ? Icon(
                            FluentIcons.checkmark_24_regular,
                            color: currentColor,
                          )
                        : null,
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCustomColorPicker(BuildContext context, Color currentColor) {
    showDialog(
      context: context,
      builder: (ctx) {
        var pickerColor = currentColor;
        return AlertDialog(
          title: Text(ctx.l10n.choosePrimaryColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(ctx.l10n.cancel),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: Text(ctx.l10n.save),
              onPressed: () {
                ctx.read<ThemeCubit>().setPrimaryColor(pickerColor);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context, Locale currentLocale) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text(
              context.l10n.chooseLanguage,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text("العربية"),
              trailing: currentLocale.languageCode == arabicLanguageCode
                  ? Icon(
                      FluentIcons.checkmark_24_regular,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              onTap: () {
                context.read<LocalizationBloc>().add(
                  const ChangeLanguage(Locale(arabicLanguageCode)),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(context.l10n.english),
              trailing: currentLocale.languageCode == englishLanguageCode
                  ? Icon(
                      FluentIcons.checkmark_24_regular,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              onTap: () {
                context.read<LocalizationBloc>().add(
                  const ChangeLanguage(Locale(englishLanguageCode)),
                );
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showConcurrentDownloadsPicker(BuildContext context, int currentValue) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text(
              context.l10n.concurrentDownloads,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            for (int i = 1; i <= 5; i++)
              ListTile(
                title: Text('$i'),
                trailing: currentValue == i
                    ? Icon(
                        FluentIcons.checkmark_24_regular,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () {
                  context.read<SettingsCubit>().setMaxConcurrentDownloads(i);
                  Navigator.pop(context);
                },
              ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logout),
        content: Text(context.l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const SignOutEvent());
            },
            child: Text(
              context.l10n.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });
  final String title;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ListTile(
      onTap: () => onChanged(value),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
              FluentIcons.checkmark_24_regular,
              color: Theme.of(context).primaryColor,
            )
          : null,
    );
  }
}
