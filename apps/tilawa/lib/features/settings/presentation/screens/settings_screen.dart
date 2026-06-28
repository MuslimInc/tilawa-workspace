import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/app_legal_urls.dart';
import 'package:tilawa/core/telemetry/sentry_debug_verify_tile.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/layout/list_scroll_bottom_padding.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/env.dart';
import '../../../../router/app_router_config.dart';
import '../../../whats_new/whats_new.dart';
import '../../../auth/application/account_deletion_flow_tracker.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../../../share/domain/entities/share_content.dart';
import '../../../share/domain/usecases/share_content_use_case.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';
import '../../../theme/presentation/theme_state_material.dart';
import '../../../home/presentation/widgets/home_hero_phase_debug_tile.dart';
import '../../../notifications/debug/notification_debug_lab_tile.dart';
import '../../../tour_guide/presentation/widgets/tour_guide_debug_reset_tile.dart';
import '../cubit/settings_cubit.dart';
import '../formatters/settings_share_text_formatter.dart';
import '../../../quran_sessions/quran_sessions_feature_flags.dart';
import '../widgets/settings_teacher_capability_scope.dart';
import '../widgets/settings_teaching_on_memuslim_tile.dart';
import '../widgets/settings_picker_sheets.dart';
import '../widgets/settings_widgets.dart';
import 'package:tilawa/features/shell/application/shell_tab_reselect.dart';
import 'package:tilawa/features/shell/presentation/shell_tab_reselect_listener.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.supportTilawaEnabled,
    required this.shareContent,
  });

  final bool supportTilawaEnabled;
  final ShareContentUseCase shareContent;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onShellTabReselect() {
    unawaited(
      ShellTabReselect.scrollToTopOrRefresh(
        scrollController: _scrollController,
        refresh: () async {},
        duration: context.tokens.durationFast,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final isGuest = context.watch<AuthBloc>().state is! AuthAuthenticated;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          loading: () {},
          authenticated: (_) {},
          unauthenticated: () {
            final AccountDeletionFlowTracker? deletionFlow =
                getIt.isRegistered<AccountDeletionFlowTracker>()
                ? getIt<AccountDeletionFlowTracker>()
                : null;
            if (deletionFlow != null && deletionFlow.suppressLoginAutoSignIn) {
              // [AccountDeletionNavigationListener] routes to login on success.
              return;
            }
            if (GoRouterState.of(context).matchedLocation !=
                const LoginRoute().location) {
              const LoginRoute().go(context);
            }
          },
          error: (message) => TilawaFeedback.showToast(
            context,
            message: message,
            variant: TilawaFeedbackVariant.error,
          ),
          noGoogleAccounts: () {},
        );
      },
      child: ShellTabReselectListener(
        tabIndex: kAppShellSettingsTabIndex,
        onReselect: _onShellTabReselect,
        child: Scaffold(
          appBar: TilawaCatalogAppBar.titleOnly(
            context,
            title: l10n.settings,
            automaticallyImplyLeading: false,
          ),
          body: TilawaCatalogSettingsBody(
            child: SettingsTeacherCapabilityScope(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: tokens.spaceMedium,
                  bottom: listScrollBottomPadding(context),
                ),
                children: [
                  const SettingsProfileHeader(),
                  const SettingsGuestAccountGroup(),
                  if (!isGuest &&
                      quranSessionsFeatureConfig().showProfileTeacherEntry)
                    const SettingsTeachingOnMemuslimSection(),
                  TilawaSettingsGroup(
                    title: l10n.settingsAppearance,
                    leadingIcon: FluentIcons.weather_moon_24_regular,
                    includeTopGap: isGuest,
                    children: [
                      BlocBuilder<ThemeCubit, ThemeState>(
                        builder: (context, state) {
                          return TilawaSettingsTile(
                            title: l10n.chooseTheme,
                            trailing: settingsPickerTrailing(
                              context,
                              value: settingsThemeLabel(state, l10n),
                            ),
                            onTap: () =>
                                SettingsSheets.showThemePicker(context),
                          );
                        },
                      ),
                      if (Env.kShowColorPicker)
                        BlocBuilder<ThemeCubit, ThemeState>(
                          builder: (context, state) {
                            return TilawaSettingsTile(
                              title: l10n.primaryColor,
                              trailing: settingsColorTrailing(
                                context,
                                state.primaryColor,
                              ),
                              onTap: () =>
                                  SettingsSheets.showPrimaryColorPicker(
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
                            title: l10n.language,
                            trailing: settingsPickerTrailing(
                              context,
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
                          );
                        },
                      ),
                    ],
                  ),
                  TilawaSettingsGroup(
                    title: l10n.settingsRecitersSection,
                    leadingIcon: Icons.record_voice_over_rounded,
                    children: [
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          return TilawaSettingsSwitchTile(
                            title: l10n.showRecitersAlphabetIndex,
                            value: state.showRecitersAlphabetIndex,
                            onChanged: context
                                .read<SettingsCubit>()
                                .setShowRecitersAlphabetIndex,
                            showDivider: false,
                          );
                        },
                      ),
                    ],
                  ),
                  TilawaSettingsGroup(
                    title: l10n.settingsPlaybackAndStorage,
                    leadingIcon: FluentIcons.storage_24_regular,
                    children: [
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          return TilawaSettingsSwitchTile(
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
                            title: l10n.enableRecitationDuration,
                            value: state.isSleepTimerEnabled,
                            onChanged: context
                                .read<SettingsCubit>()
                                .toggleSleepTimerEnabled,
                          );
                        },
                      ),
                      TilawaSettingsTile(
                        title: l10n.manageStorage,
                        subtitle: l10n.manageStorageSubtitle,
                        onTap: () => const DownloadsRoute().push(context),
                      ),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          return TilawaSettingsTile(
                            title: l10n.concurrentDownloads,
                            subtitle: l10n.concurrentDownloadsSubtitle(
                              state.maxConcurrentDownloads,
                            ),
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
                    leadingIcon: FluentIcons.person_support_24_regular,
                    children: [
                      const SettingsRateAppTile(),
                      TilawaSettingsTile(
                        title: l10n.whatsNewSettingsTile,
                        onTap: () =>
                            getIt<WhatsNewCoordinator>().showFromSettings(),
                      ),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          return SettingsShareAppTile(
                            isLast: !widget.supportTilawaEnabled,
                            onShareRequested: () {
                              final shareText = buildSettingsShareAppText(
                                l10n,
                                appInfo: state.appInfo,
                              );
                              return widget.shareContent(
                                ShareContent.text(text: shareText),
                              );
                            },
                          );
                        },
                      ),
                      if (widget.supportTilawaEnabled)
                        TilawaSettingsTile(
                          title: l10n.supportTilawa,
                          subtitle: l10n.supportHelpKeepFree,
                          onTap: () => const SupportRoute().push(context),
                        ),
                      TilawaSettingsTile(
                        title: l10n.privacyPolicy,
                        onTap: () => openLegalUrl(AppLegalUrls.privacyPolicy),
                        showDivider: false,
                      ),
                    ],
                  ),
                  SettingsAccountActions(
                    onLogout: () =>
                        SettingsSheets.showLogoutConfirmation(context),
                    onDeleteAccount: () =>
                        SettingsSheets.showDeleteAccountConfirmation(
                          context,
                        ),
                  ),
                  if (kDebugMode)
                    TilawaSettingsGroup(
                      title: 'Developer',
                      leadingIcon: FluentIcons.code_24_regular,
                      children: [
                        TilawaSettingsTile(
                          title: 'Route list',
                          onTap: () => const RouteListRoute().push(context),
                        ),
                        const SentryDebugVerifyTile(),
                        const HomeHeroPhaseDebugTile(),
                        const NotificationDebugLabTile(),
                        const TourGuideDebugResetTile(isLast: true),
                      ],
                    ),
                  const SettingsVersionFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
