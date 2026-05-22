import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/bootstrap/app_launch_config.dart';
import '../../../../router/app_router_config.dart';
import 'package:tilawa/core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../../../theme/domain/app_theme_mode.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';
import '../../../theme/presentation/theme_state_material.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/settings_picker_sheets.dart';
import '../widgets/settings_profile_card.dart';
import '../widgets/settings_shared.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final l10n = context.l10n;

    return BlocListener<AuthBloc, AuthState>(
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
        appBar: TilawaAppBar(title: l10n.settings),
        body: TilawaContentBounds(
          kind: TilawaContentKind.settings,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLarge,
              tokens.spaceLarge,
              tokens.spaceLarge,
              tokens.spaceExtraLarge + tokens.spaceLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SettingsProfileCard(),
                const SettingsSectionGap(),

                // Appearance
                TilawaSettingsGroup(
                  title: l10n.appearance,
                  children: [
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            TilawaSettingsSwitchTile(
                              icon: FluentIcons.dark_theme_24_regular,
                              title: l10n.darkTheme,
                              value: state.mode == AppThemeMode.dark,
                              onChanged: context
                                  .read<ThemeCubit>()
                                  .toggleDark,
                              borderRadius: SettingsTileCorners.top(tokens),
                            ),
                            TilawaSettingsTile(
                              icon: FluentIcons.color_24_regular,
                              title: l10n.primaryColor,
                              trailing: SettingsPrimaryColorTrailing(
                                color: state.primaryColor,
                              ),
                              onTap: () => SettingsSheets.showPrimaryColorPicker(
                                context,
                                currentColor: state.primaryColor,
                                currentSource: state.primaryColorSource,
                                currentPresetId: state.primaryPresetId,
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
                          title: l10n.language,
                          trailing: SettingsValueTrailing(
                            value: settingsLanguageLabel(
                              state.locale,
                              l10n,
                            ),
                          ),
                          onTap: () => SettingsSheets.showLanguagePicker(
                            context,
                            currentLocale: state.locale,
                          ),
                          showDivider: false,
                          borderRadius: SettingsTileCorners.bottom(tokens),
                        );
                      },
                    ),
                  ],
                ),

                const SettingsSectionGap(),

                // Playback
                TilawaSettingsGroup(
                  title: l10n.audioSettings,
                  children: [
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            TilawaSettingsSwitchTile(
                              icon: FluentIcons.history_24_regular,
                              title: l10n.restorePlaybackState,
                              value: state.restorePlaybackState,
                              onChanged: context
                                  .read<SettingsCubit>()
                                  .toggleRestorePlaybackState,
                              borderRadius: SettingsTileCorners.top(tokens),
                            ),
                            TilawaSettingsSwitchTile(
                              icon: FluentIcons.timer_24_regular,
                              title: l10n.enableRecitationDuration,
                              value: state.isSleepTimerEnabled,
                              onChanged: context
                                  .read<SettingsCubit>()
                                  .toggleSleepTimerEnabled,
                              showDivider: false,
                              borderRadius: SettingsTileCorners.bottom(tokens),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SettingsSectionGap(),

                // Library shortcuts (not duplicated in main tabs)
                TilawaSettingsGroup(
                  title: l10n.features,
                  children: [
                    TilawaSettingsTile(
                      icon: FluentIcons.bookmark_24_regular,
                      title: l10n.bookmarks,
                      onTap: () => const BookmarksRoute().push(context),
                      borderRadius: SettingsTileCorners.top(tokens),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.history_24_regular,
                      title: l10n.listeningHistory,
                      onTap: () => const HistoryRoute().push(context),
                    ),
                    TilawaSettingsTile(
                      icon: FluentIcons.book_24_regular,
                      title: l10n.quranReader,
                      onTap: () => const QuranLastReadRoute().push(context),
                      showDivider: false,
                      borderRadius: SettingsTileCorners.bottom(tokens),
                    ),
                  ],
                ),

                const SettingsSectionGap(),

                // Downloads
                TilawaSettingsGroup(
                  title: l10n.downloads,
                  children: [
                    TilawaSettingsTile(
                      icon: FluentIcons.folder_24_regular,
                      title: l10n.manageStorage,
                      onTap: () => const DownloadsRoute().push(context),
                      borderRadius: SettingsTileCorners.top(tokens),
                    ),
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, state) {
                        return TilawaSettingsTile(
                          icon: FluentIcons.arrow_download_24_regular,
                          title: l10n.concurrentDownloads,
                          trailing: SettingsValueTrailing(
                            value: '${state.maxConcurrentDownloads}',
                          ),
                          onTap: () =>
                              SettingsSheets.showConcurrentDownloadsPicker(
                                context,
                                currentValue: state.maxConcurrentDownloads,
                              ),
                          showDivider: false,
                          borderRadius: SettingsTileCorners.bottom(tokens),
                        );
                      },
                    ),
                  ],
                ),

                if (getIt<AppLaunchConfig>().supportTilawaEnabled) ...[
                  const SettingsSectionGap(),
                  TilawaSettingsGroup(
                    title: l10n.supportSettingsGroupTitle,
                    children: [
                      TilawaSettingsTile(
                        icon: FluentIcons.heart_24_regular,
                        title: l10n.supportTilawa,
                        onTap: () => const SupportRoute().push(context),
                        showDivider: false,
                        borderRadius: SettingsTileCorners.all(tokens),
                      ),
                    ],
                  ),
                ],

                const SettingsSectionGap(),
                SettingsLogoutTile(
                  onTap: () => SettingsSheets.showLogoutConfirmation(context),
                ),

                if (kDebugMode) ...[
                  const SettingsSectionGap(),
                  TilawaSettingsGroup(
                    title: 'Developer',
                    children: [
                      TilawaSettingsTile(
                        icon: FluentIcons.apps_list_24_regular,
                        title: 'Route list',
                        onTap: () => const RouteListRoute().push(context),
                        borderRadius: SettingsTileCorners.top(tokens),
                      ),
                      TilawaSettingsTile(
                        icon: FluentIcons.link_24_regular,
                        title: 'Deep link debug',
                        onTap: () => const DeepLinkDebugRoute().push(context),
                        showDivider: false,
                        borderRadius: SettingsTileCorners.bottom(tokens),
                      ),
                    ],
                  ),
                ],

                const SettingsSectionGap(),
                const SettingsAppVersionFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
