import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_ui/theme/app_colors.dart';
import 'package:tilawa_ui/theme/color_scheme.dart';

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
    return BlocListener<AuthBloc, AuthState>(
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
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(context.l10n.settings)),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            children: [
              // User Profile Section
              _buildProfileSection(context),
              SizedBox(height: 32.h),

              // General Group (Theme & Language)
              _SettingsGroup(
                title: context.l10n.appearance.toUpperCase(),
                children: [
                  BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          _SettingsTile(
                            icon: FluentIcons.dark_theme_24_regular,
                            iconColor: AppColors.settingsTheme,
                            title: context.l10n.theme,
                            subtitle: _getThemeName(context, state.mode),
                            onTap: () => _showThemePicker(context, state.mode),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16.r),
                            ),
                          ),
                          _SettingsTile(
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
                      return _SettingsTile(
                        icon: FluentIcons.local_language_24_regular,
                        iconColor: AppColors.settingsLanguage,
                        title: context.l10n.language,
                        subtitle: state.locale.languageCode == 'ar'
                            ? context.l10n.arabic
                            : context.l10n.english,
                        onTap: () => _showLanguagePicker(context, state.locale),
                        showDivider: false,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16.r),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Audio Group
              _SettingsGroup(
                title: context.l10n.audioSettings.toUpperCase(),
                children: [
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          _SwitchSettingsTile(
                            icon: FluentIcons.history_24_regular,
                            iconColor: AppColors.settingsPlayback,
                            title: context.l10n.restorePlaybackState,
                            subtitle: context.l10n.restorePlaybackStateSubtitle,
                            value: state.restorePlaybackState,
                            onChanged: (value) {
                              context
                                  .read<SettingsCubit>()
                                  .toggleRestorePlaybackState(value);
                            },
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16.r),
                            ),
                          ),
                          _SwitchSettingsTile(
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
                              bottom: Radius.circular(16.r),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Features Group
              _SettingsGroup(
                title: context.l10n.features.toUpperCase(),
                children: [
                  _SettingsTile(
                    icon: FluentIcons.bookmark_24_regular,
                    iconColor: AppColors.settingsBookmarks,
                    title: context.l10n.bookmarks,
                    subtitle: context.l10n.noBookmarksHint,
                    onTap: () => const BookmarksRoute().push(context),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                  ),
                  _SettingsTile(
                    icon: FluentIcons.history_24_regular,
                    iconColor: AppColors.settingsHistory,
                    title: context.l10n.listeningHistory,
                    subtitle: context.l10n.noHistoryDescription,
                    onTap: () => const HistoryRoute().push(context),
                  ),
                  _SettingsTile(
                    icon: FluentIcons.clock_24_regular,
                    iconColor: AppColors.settingsPrayer,
                    title: context.l10n.prayerTimes,
                    subtitle: context.l10n.locationRequiredDescription,
                    onTap: () => const PrayerTimesRoute().push(context),
                  ),
                  _SettingsTile(
                    icon: FluentIcons.book_24_regular,
                    iconColor: AppColors.settingsQuran,
                    title: context.l10n.quranReader,
                    subtitle: context.l10n.continueReading,
                    onTap: () =>
                        const QuranReaderRoute(surahNumber: 1).push(context),
                    showDivider: false,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16.r),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Downloads Group
              _SettingsGroup(
                title: context.l10n.downloads.toUpperCase(),
                children: [
                  _SettingsTile(
                    icon: FluentIcons.folder_24_regular,
                    iconColor: AppColors.settingsStorage,
                    title: context.l10n.manageStorage,
                    subtitle: context.l10n.manageStorageSubtitle,
                    onTap: () => const DownloadsRoute().push(context),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                  ),
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return _SettingsTile(
                        icon: FluentIcons.arrow_download_24_regular,
                        iconColor: AppColors.settingsDownloads,
                        title: context.l10n.concurrentDownloads,
                        subtitle: context.l10n.concurrentDownloadsSubtitle(
                          state.maxConcurrentDownloads,
                        ),
                        onTap: () => _showConcurrentDownloadsPicker(
                          context,
                          state.maxConcurrentDownloads,
                        ),
                        showDivider: false,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16.r),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // Logout Button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    return Material(
                      color: context.isDarkMode
                          ? context.theme.cardColor
                          : AppColors.logoutBackground,
                      borderRadius: BorderRadius.circular(20.r),
                      child: InkWell(
                        onTap: () => _showLogoutDialog(context),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FluentIcons.sign_out_24_filled,
                                color: AppColors.error,
                                size: 20,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                context.l10n.logout,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
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
                SizedBox(height: 32.h),
                _SettingsTile(
                  icon: Icons.list_alt_rounded,
                  title: 'Route List (Dev)',
                  onTap: () => const RouteListRoute().push(context),
                  borderRadius: BorderRadius.circular(16.r),
                  showDivider: false,
                ),
              ],

              SizedBox(height: 32.h),

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
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        context.l10n.build(buildNumber),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 32.h),
            ],
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
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colorScheme.primary,
                context.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.r),
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
                width: 60.r,
                height: 60.r,
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
                    size: 32.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? context.l10n.guestUser,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user?.email ?? context.l10n.signInToSync,
                      style: TextStyle(
                        fontSize: 14.sp,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.h),
            Text(
              context.l10n.chooseTheme,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
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
            SizedBox(height: 16.h),
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

  void _showColorPicker(BuildContext context, Color currentColor) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.h),
            Text(
              context.l10n.choosePrimaryColor,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            ...ThemeCubit.colorOptions.map((option) {
              final isSelected =
                  option.color.toARGB32() == currentColor.toARGB32();
              return ListTile(
                onTap: () {
                  context.read<ThemeCubit>().setPrimaryColor(option.color);
                  Navigator.pop(context);
                },
                leading: CircleAvatar(
                  backgroundColor: option.color,
                  radius: 12.r,
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
                Navigator.pop(context);
                _showCustomColorPicker(context, currentColor);
              },
              leading: Container(
                width: 24.r,
                height: 24.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [Colors.red, Colors.blue, Colors.green, Colors.red],
                  ),
                ),
              ),
              title: Text(
                context.l10n.custom,
                style: TextStyle(
                  fontWeight:
                      !ThemeCubit.colorOptions.any(
                        (opt) =>
                            opt.color.toARGB32() == currentColor.toARGB32(),
                      )
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color:
                      !ThemeCubit.colorOptions.any(
                        (opt) =>
                            opt.color.toARGB32() == currentColor.toARGB32(),
                      )
                      ? currentColor
                      : null,
                ),
              ),
              trailing:
                  !ThemeCubit.colorOptions.any(
                    (opt) => opt.color.toARGB32() == currentColor.toARGB32(),
                  )
                  ? Icon(FluentIcons.checkmark_24_regular, color: currentColor)
                  : null,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.h),
            Text(
              context.l10n.chooseLanguage,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
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
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  void _showConcurrentDownloadsPicker(BuildContext context, int currentValue) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.h),
            Text(
              context.l10n.concurrentDownloads,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
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
            SizedBox(height: 16.h),
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 16.h, 16.w, 8.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [
              BoxShadow(
                color: AppColors.settingsCardShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.subtitle,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: ListTile(
            onTap: onTap,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 2.h,
            ),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            leading: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 22.sp),
            ),
            title: Text(
              title,
              style: TextStyle(fontSize: 15.5.sp, fontWeight: FontWeight.w600),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  )
                : null,
            trailing: Icon(
              FluentIcons.chevron_right_24_filled,
              size: 14.sp,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 64.w, right: 16.w),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: theme.dividerColor.withValues(alpha: 0.05),
            ),
          ),
      ],
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

class _SwitchSettingsTile extends StatelessWidget {
  const _SwitchSettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.subtitle,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: borderRadius is BorderRadius
                ? borderRadius as BorderRadius
                : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 22.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: theme.primaryColor.withValues(alpha: 0.5),
                    activeThumbColor: theme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 64.w, right: 16.w),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: theme.dividerColor.withValues(alpha: 0.05),
            ),
          ),
      ],
    );
  }
}
