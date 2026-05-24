import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/bootstrap/app_launch_config.dart';
import '../../../../router/app_router_config.dart';
import '../../../app_review/presentation/cubit/app_review_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../../../theme/domain/app_theme_mode.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';
import '../../../theme/presentation/theme_state_material.dart';
import '../../../tour_guide/presentation/widgets/tour_guide_debug_reset_tile.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/settings_picker_sheets.dart';
import '../widgets/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final supportEnabled = getIt<AppLaunchConfig>().supportTilawaEnabled;

    return BlocProvider(
      create: (_) => getIt<AppReviewCubit>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            authenticated: (_) {},
            unauthenticated: () => const LoginRoute().go(context),
            error: (message) => ToastUtils.showErrorToast(message),
          );
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: TilawaCatalogAppBar.titleOnly(context, title: l10n.settings),
          body: TilawaCatalogSettingsBody(
            child: ListView(
              padding: EdgeInsets.only(bottom: tokens.spaceMedium),
              children: [
                const SettingsProfileHeader(),
                SizedBox(height: tokens.spaceMedium),
                TilawaSettingsGroup(
                  title: l10n.settings,
                  children: [
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        return TilawaSettingsSwitchTile(
                          icon: FluentIcons.weather_moon_24_regular,
                          title: l10n.darkTheme,
                          value: state.mode == AppThemeMode.dark,
                          onChanged: context.read<ThemeCubit>().toggleDark,
                        );
                      },
                    ),
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        return TilawaSettingsTile(
                          icon: FluentIcons.color_24_regular,
                          title: l10n.primaryColor,
                          trailing: settingsColorTrailing(
                            context,
                            state.primaryColor,
                          ),
                          onTap: () => SettingsSheets.showPrimaryColorPicker(
                            context,
                            currentColor: state.primaryColor,
                            currentSource: state.primaryColorSource,
                            currentPresetId: state.primaryPresetId,
                          ),
                        );
                      },
                    ),
                    BlocBuilder<LocalizationBloc, LocalizationState>(
                      builder: (context, state) {
                        return TilawaSettingsTile(
                          icon: FluentIcons.local_language_24_regular,
                          title: l10n.language,
                          trailing: settingsPickerTrailing(
                            context,
                            value: settingsLanguageLabel(state.locale, l10n),
                          ),
                          onTap: () => SettingsSheets.showLanguagePicker(
                            context,
                            currentLocale: state.locale,
                          ),
                          showDivider: false,
                        );
                      },
                    ),
                  ],
                ),
                TilawaSettingsGroup(
                  title: l10n.audioSettings,
                  children: [
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return TilawaSettingsSwitchTile(
                          icon: FluentIcons.arrow_reset_24_regular,
                          title: l10n.restorePlaybackState,
                          value: state.restorePlaybackState,
                          onChanged: context
                              .read<SettingsCubit>()
                              .toggleRestorePlaybackState,
                        );
                      },
                    ),
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return TilawaSettingsSwitchTile(
                          icon: FluentIcons.timer_24_regular,
                          title: l10n.enableRecitationDuration,
                          value: state.isSleepTimerEnabled,
                          onChanged: context
                              .read<SettingsCubit>()
                              .toggleSleepTimerEnabled,
                          showDivider: false,
                        );
                      },
                    ),
                  ],
                ),
                TilawaSettingsGroup(
                  title: l10n.features,
                  children: [
                    TilawaSettingsTile(
                      icon: FluentIcons.bookmark_24_regular,
                      title: l10n.bookmarks,
                      onTap: () => const BookmarksRoute().push(context),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.history_24_regular,
                      title: l10n.listeningHistory,
                      onTap: () => const HistoryRoute().push(context),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.book_open_24_regular,
                      title: l10n.quranReader,
                      onTap: () => const QuranLastReadRoute().push(context),
                      showDivider: false,
                    ),
                  ],
                ),
                TilawaSettingsGroup(
                  title: l10n.downloads,
                  children: [
                    TilawaSettingsTile(
                      icon: FluentIcons.storage_24_regular,
                      title: l10n.manageStorage,
                      onTap: () => const DownloadsRoute().push(context),
                    ),
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return TilawaSettingsTile(
                          icon: FluentIcons.arrow_download_24_regular,
                          title: l10n.concurrentDownloads,
                          trailing: settingsPickerTrailing(
                            context,
                            value: '${state.maxConcurrentDownloads}',
                          ),
                          onTap: () =>
                              SettingsSheets.showConcurrentDownloadsPicker(
                                context,
                                currentValue: state.maxConcurrentDownloads,
                              ),
                          showDivider: false,
                        );
                      },
                    ),
                  ],
                ),
                TilawaSettingsGroup(
                  title: l10n.settingsSupportSection,
                  children: [
                    SettingsRateAppTile(isLast: !supportEnabled),
                    if (supportEnabled)
                      TilawaSettingsTile(
                        icon: FluentIcons.heart_24_regular,
                        title: l10n.supportTilawa,
                        onTap: () => const SupportRoute().push(context),
                        showDivider: false,
                      ),
                  ],
                ),
                SettingsLogoutSection(
                  onLogout: () =>
                      SettingsSheets.showLogoutConfirmation(context),
                ),
                if (kDebugMode)
                  TilawaSettingsGroup(
                    title: 'Developer',
                    children: [
                      TilawaSettingsTile(
                        icon: FluentIcons.code_24_regular,
                        title: 'Route list',
                        onTap: () => const RouteListRoute().push(context),
                      ),
                      TilawaSettingsTile(
                        icon: FluentIcons.link_24_regular,
                        title: 'Deep link debug',
                        onTap: () => const DeepLinkDebugRoute().push(context),
                      ),
                      const TourGuideDebugResetTile(isLast: true),
                    ],
                  ),
                const SettingsVersionFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
