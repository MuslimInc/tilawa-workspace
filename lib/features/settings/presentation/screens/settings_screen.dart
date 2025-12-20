// ignore_for_file: deprecated_member_use
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/config/language_config.dart';
import '../../../../core/extensions.dart';
import '../../../../router/app_router_config.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';
import '../cubit/settings_cubit.dart';

// ... other imports

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              title: context.l10n.appearance,
              children: [
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, state) {
                    return _SettingsTile(
                      icon: FluentIcons.dark_theme_24_regular,
                      title: context.l10n.theme,
                      subtitle: _getThemeName(context, state.mode),
                      onTap: () => _showThemePicker(context, state.mode),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16.r),
                      ),
                    );
                  },
                ),
                BlocBuilder<LocalizationBloc, LocalizationState>(
                  builder: (context, state) {
                    return _SettingsTile(
                      icon: FluentIcons.local_language_24_regular,
                      title: context.l10n.language,
                      subtitle:
                          state.locale.languageCode ==
                              LanguageConfig.defaultLanguageCode
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
              title: context.l10n.audioSettings,
              children: [
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    return _SwitchSettingsTile(
                      icon: FluentIcons.history_24_regular,
                      title: context.l10n.restorePlaybackState,
                      subtitle: context.l10n.restorePlaybackStateSubtitle,
                      value: state.restorePlaybackState,
                      onChanged: (value) {
                        context
                            .read<SettingsCubit>()
                            .toggleRestorePlaybackState(value);
                      },
                      showDivider: false,
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Downloads Group
            _SettingsGroup(
              title: context.l10n.downloads,
              children: [
                _SettingsTile(
                  icon: FluentIcons.folder_24_regular,
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
                  return InkWell(
                    onTap: () {
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
                                context.read<AuthBloc>().add(
                                  const SignOutEvent(),
                                );
                              },
                              child: Text(
                                context.l10n.logout,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        context.l10n.logout,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(height: 32.h),

            // Route List (Dev)
            _SettingsTile(
              icon: Icons.list_alt_rounded,
              title: 'Route List (Dev)',
              onTap: () => const RouteListRoute().push(context),
              borderRadius: BorderRadius.circular(16.r),
              showDivider: false,
            ),

            SizedBox(height: 32.h),
          ],
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
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30.r,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  FluentIcons.person_32_filled,
                  size: 32.sp,
                  color: Theme.of(context).primaryColor,
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
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user?.email ?? context.l10n.signInToSync,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
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
              title: Text(context.l10n.english),
              trailing: currentLocale.languageCode == 'en'
                  ? Icon(
                      FluentIcons.checkmark_24_regular,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              onTap: () {
                context.read<LocalizationBloc>().add(
                  const ChangeLanguage(Locale('en')),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(context.l10n.arabic),
              trailing:
                  currentLocale.languageCode ==
                      LanguageConfig.defaultLanguageCode
                  ? Icon(
                      FluentIcons.checkmark_24_regular,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              onTap: () {
                context.read<LocalizationBloc>().add(
                  const ChangeLanguage(
                    Locale(LanguageConfig.defaultLanguageCode),
                  ),
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16.r),
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
    this.subtitle,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Material(
          borderRadius: borderRadius,
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            leading: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 20.sp),
            ),
            title: Text(title, style: TextStyle(fontSize: 16.sp)),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  )
                : null,
            trailing: Icon(
              FluentIcons.chevron_right_24_regular,
              size: 18.sp,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 60.w, endIndent: 20.w, thickness: 0.5),
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
    this.subtitle,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: theme.primaryColor, size: 20.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16.sp)),
                      if (subtitle != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeColor: theme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 60.w, endIndent: 20.w, thickness: 0.5),
      ],
    );
  }
}
