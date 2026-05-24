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
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

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
        backgroundColor: colorScheme.surface,
        appBar: TilawaAppBar(
          title: l10n.settingsYourAccount,
          automaticallyImplyLeading: false,
          centerTitle: false,
          surface: TilawaAppBarSurface.parchment,
          showBottomHairline: true,
        ),
        body: TilawaCatalogSettingsBody(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SettingsProfileCard(),
              TilawaCatalogSettingsSection(
                title: l10n.settings,
                topSpacing: 0,
                children: [
                  BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          TilawaCatalogSettingsSwitchRow(
                            title: l10n.darkTheme,
                            value: state.mode == AppThemeMode.dark,
                            onChanged: context.read<ThemeCubit>().toggleDark,
                          ),
                          TilawaCatalogSettingsLinkRow(
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
                      return TilawaCatalogSettingsLinkRow(
                        title: l10n.language,
                        trailing: SettingsValueTrailing(
                          value: settingsLanguageLabel(state.locale, l10n),
                        ),
                        onTap: () => SettingsSheets.showLanguagePicker(
                          context,
                          currentLocale: state.locale,
                        ),
                      );
                    },
                  ),
                ],
              ),
              TilawaCatalogSettingsSection(
                title: l10n.audioSettings,
                children: [
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          TilawaCatalogSettingsSwitchRow(
                            title: l10n.restorePlaybackState,
                            value: state.restorePlaybackState,
                            onChanged: context
                                .read<SettingsCubit>()
                                .toggleRestorePlaybackState,
                          ),
                          TilawaCatalogSettingsSwitchRow(
                            title: l10n.enableRecitationDuration,
                            value: state.isSleepTimerEnabled,
                            onChanged: context
                                .read<SettingsCubit>()
                                .toggleSleepTimerEnabled,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              TilawaCatalogSettingsSection(
                title: l10n.features,
                children: [
                  TilawaCatalogSettingsLinkRow(
                    title: l10n.bookmarks,
                    onTap: () => const BookmarksRoute().push(context),
                  ),
                  TilawaCatalogSettingsLinkRow(
                    title: l10n.listeningHistory,
                    onTap: () => const HistoryRoute().push(context),
                  ),
                  TilawaCatalogSettingsLinkRow(
                    title: l10n.quranReader,
                    onTap: () => const QuranLastReadRoute().push(context),
                  ),
                ],
              ),
              TilawaCatalogSettingsSection(
                title: l10n.downloads,
                children: [
                  TilawaCatalogSettingsLinkRow(
                    title: l10n.manageStorage,
                    onTap: () => const DownloadsRoute().push(context),
                  ),
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return TilawaCatalogSettingsLinkRow(
                        title: l10n.concurrentDownloads,
                        trailing: SettingsValueTrailing(
                          value: '${state.maxConcurrentDownloads}',
                        ),
                        onTap: () =>
                            SettingsSheets.showConcurrentDownloadsPicker(
                              context,
                              currentValue: state.maxConcurrentDownloads,
                            ),
                      );
                    },
                  ),
                ],
              ),
              if (getIt<AppLaunchConfig>().supportTilawaEnabled)
                TilawaCatalogSettingsSection(
                  title: l10n.settingsSupportSection,
                  children: [
                    TilawaCatalogSettingsLinkRow(
                      title: l10n.supportTilawa,
                      onTap: () => const SupportRoute().push(context),
                    ),
                  ],
                ),
              SettingsLogoutTile(
                onTap: () => SettingsSheets.showLogoutConfirmation(context),
              ),
              if (kDebugMode)
                TilawaCatalogSettingsSection(
                  title: 'Developer',
                  children: [
                    TilawaCatalogSettingsLinkRow(
                      title: 'Route list',
                      onTap: () => const RouteListRoute().push(context),
                    ),
                    TilawaCatalogSettingsLinkRow(
                      title: 'Deep link debug',
                      onTap: () => const DeepLinkDebugRoute().push(context),
                    ),
                  ],
                ),
              const SettingsAppVersionFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
