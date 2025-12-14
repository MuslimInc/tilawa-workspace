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

            // Appearance Group
            _SettingsGroup(
              title: 'Appearance',
              children: [
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, state) {
                    return _SettingsTile(
                      icon: FluentIcons.dark_theme_24_regular,
                      title: 'Theme',
                      subtitle: _getThemeName(state.mode),
                      onTap: () => _showThemePicker(context, state.mode),
                      borderRadius: BorderRadiusGeometry.vertical(
                        top: Radius.circular(16.r),
                      ),
                    );
                  },
                ),
                BlocBuilder<LocalizationBloc, LocalizationState>(
                  builder: (context, state) {
                    return _SettingsTile(
                      icon: FluentIcons.local_language_24_regular,
                      title: 'Language',
                      subtitle:
                          state.locale.languageCode ==
                              LanguageConfig.defaultLanguageCode
                          ? 'Arabic'
                          : 'English',
                      onTap: () => _showLanguagePicker(context, state.locale),
                      showDivider: false,
                      borderRadius: BorderRadiusGeometry.vertical(
                        bottom: Radius.circular(16.r),
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Downloads Group
            // Downloads Group
            _SettingsGroup(
              title: 'Downloads',
              children: [
                _SettingsTile(
                  icon: FluentIcons.folder_24_regular,
                  title: 'Manage Storage',
                  subtitle: 'View and manage downloaded content',
                  onTap: () => const DownloadsRoute().push(context),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                  ),
                ),
                BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    return _SettingsTile(
                      icon: FluentIcons.arrow_download_24_regular,
                      title: 'Concurrent Downloads',
                      subtitle:
                          '${state.maxConcurrentDownloads} downloads at once',
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

            SizedBox(height: 24.h),

            // Account Group
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return _SettingsGroup(
                    title: 'Account',
                    children: [
                      _SettingsTile(
                        icon: FluentIcons.sign_out_24_regular,
                        title: 'Logout',
                        titleColor: Colors.redAccent,
                        iconColor: Colors.redAccent,
                        showArrow: false,
                        showDivider: false,
                        onTap: () {
                          // Show confirmation dialog before logout
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<AuthBloc>().add(
                                      const SignOutEvent(),
                                    );
                                  },
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
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
                      user?.displayName ?? 'Guest User',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user?.email ?? 'Sign in to sync your data',
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

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
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
              'Choose Theme',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _ThemeOption(
              title: 'System Default',
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (val) {
                context.read<ThemeCubit>().setMode(val);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: 'Light Mode',
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (val) {
                context.read<ThemeCubit>().setMode(val);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: 'Dark Mode',
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
              'Choose Language',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            ListTile(
              title: const Text('English'),
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
              title: const Text('العربية'),
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
              'Concurrent Downloads',
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
    this.titleColor,
    this.iconColor,
    this.showArrow = true,
    this.showDivider = true,
    this.borderRadius = BorderRadius.zero,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showArrow;
  final bool showDivider;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
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
                color: (iconColor ?? Theme.of(context).primaryColor).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 20.sp,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                color: titleColor,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  )
                : null,
            trailing: showArrow
                ? Icon(
                    FluentIcons.chevron_right_24_regular,
                    size: 18.sp,
                    color: Colors.grey,
                  )
                : null,
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
