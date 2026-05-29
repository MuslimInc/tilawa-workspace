import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../bloc/prayer_permissions_cubit.dart';
import '../bloc/prayer_times_bloc.dart';
import '../prayer_notification_semantics_ids.dart';

/// A dedicated bottom sheet for managing prayer notification alerts.
///
/// Follows Atomic Design principles by reusing Tilawa UI Kit atoms and
/// local private widgets for consistent styling.
class PrayerNotificationSettingsSheet extends StatefulWidget {
  const PrayerNotificationSettingsSheet({super.key});

  @override
  State<PrayerNotificationSettingsSheet> createState() =>
      _PrayerNotificationSettingsSheetState();
}

class _PrayerNotificationSettingsSheetState
    extends State<PrayerNotificationSettingsSheet> {
  @override
  void initState() {
    super.initState();
    context.read<PrayerPermissionsCubit>().checkCapability();
  }

  void _updateSettings(PrayerSettingsEntity newSettings) {
    context.read<PrayerTimesBloc>().add(
      PrayerTimesEvent.updateSettings(newSettings),
    );
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bottomPadding = context.floatingBottomPadding;

    // We use context.select to listen only to the settings change
    final settings = context.select(
      (PrayerTimesBloc bloc) => bloc.state.settings,
    );

    final basePadding = TilawaBottomSheetScaffold.resolvedBodyPadding(context);
    final scrollPadding = basePadding.copyWith(
      bottom: basePadding.bottom + bottomPadding,
    );

    return TilawaBottomSheetScaffold(
      topBar: _SheetHeader(onDone: _close, tokens: tokens, theme: theme),
      betweenTopBarAndBody: const [Divider(height: 1)],
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: scrollPadding,
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                // Permission Banners
                BlocBuilder<PrayerPermissionsCubit, PrayerPermissionsState>(
                  buildWhen: (p, c) => p.capability != c.capability,
                  builder: (context, state) {
                    final capability = state.capability;
                    if (capability == null) return const SizedBox.shrink();

                    return Column(
                      children: [
                        if (!capability.hasNotificationPermission)
                          _PermissionBanner(
                            message:
                                context.l10n.notificationPermissionRequired,
                            onTap: () async {
                              await context
                                  .read<PrayerPermissionsCubit>()
                                  .requestNotificationPermission();
                              if (context.mounted) {
                                context.read<PrayerTimesBloc>().add(
                                  const PrayerTimesEvent.loadPrayerTimes(
                                    forceReschedule: true,
                                  ),
                                );
                              }
                            },
                            tokens: tokens,
                            theme: theme,
                          ),
                        if (capability.hasNotificationPermission &&
                            !capability.canScheduleExact)
                          _PermissionBanner(
                            message: context.l10n.exactAlarmPermissionRequired,
                            onTap: () async {
                              await context
                                  .read<PrayerPermissionsCubit>()
                                  .requestExactAlarmPermission();
                              if (context.mounted) {
                                context.read<PrayerTimesBloc>().add(
                                  const PrayerTimesEvent.loadPrayerTimes(
                                    forceReschedule: true,
                                  ),
                                );
                              }
                            },
                            tokens: tokens,
                            theme: theme,
                          ),
                        if (capability.hasNotificationPermission &&
                            !capability.isIgnoringBatteryOptimizations)
                          _PermissionBanner(
                            message: context
                                .l10n
                                .batteryOptimizationExemptionRequired,
                            onTap: () async {
                              await context
                                  .read<PrayerPermissionsCubit>()
                                  .requestIgnoreBatteryOptimizations();
                              if (context.mounted) {
                                context.read<PrayerTimesBloc>().add(
                                  const PrayerTimesEvent.loadPrayerTimes(
                                    forceReschedule: true,
                                  ),
                                );
                              }
                            },
                            tokens: tokens,
                            theme: theme,
                          ),
                        if (capability.hasNotificationPermission &&
                            capability.oemRequiresAutostart)
                          _InfoBanner(
                            message: context.l10n.oemAutostartHint,
                            tokens: tokens,
                            theme: theme,
                          ),
                      ],
                    );
                  },
                ),

                _SettingsSwitch(
                  title: context.l10n.prayerNotificationsEnabledAll,
                  value: settings.allNotificationsEnabled,
                  identifier: PrayerNotificationSemanticsIds.globalToggle,
                  onChanged: (value) {
                    _updateSettings(
                      settings.copyWithToggledNotifications(value),
                    );
                  },
                ),

                _SettingsSwitch(
                  title: context.l10n.playAdhan,
                  value: settings.allAdhanEnabled,
                  identifier: PrayerNotificationSemanticsIds.soundToggle,
                  onChanged: (value) {
                    _updateSettings(settings.copyWithToggledAdhan(value));
                  },
                ),

                SizedBox(height: tokens.spaceMedium),
                const Divider(),
                SizedBox(height: tokens.spaceMedium),

                _PrayerAlertTile(
                  title: context.l10n.fajr,
                  notificationEnabled: settings.fajrNotification.enabled,
                  adhanEnabled: settings.fajrNotification.playAdhan,
                  onNotificationChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert(
                      'fajr',
                      notificationEnabled: value,
                    ),
                  ),
                  onAdhanChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert('fajr', adhanEnabled: value),
                  ),
                  notificationIdentifier:
                      PrayerNotificationSemanticsIds.fajrToggle,
                ),

                _PrayerAlertTile(
                  title: context.l10n.sunrise,
                  notificationEnabled: settings.sunriseNotification.enabled,
                  adhanEnabled: false,
                  supportsAdhan: false,
                  onNotificationChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert(
                      'sunrise',
                      notificationEnabled: value,
                    ),
                  ),
                  onAdhanChanged: (_) {},
                ),

                _PrayerAlertTile(
                  title: context.l10n.dhuhr,
                  notificationEnabled: settings.dhuhrNotification.enabled,
                  adhanEnabled: settings.dhuhrNotification.playAdhan,
                  onNotificationChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert(
                      'dhuhr',
                      notificationEnabled: value,
                    ),
                  ),
                  onAdhanChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert('dhuhr', adhanEnabled: value),
                  ),
                  notificationIdentifier:
                      PrayerNotificationSemanticsIds.dhuhrToggle,
                ),

                _PrayerAlertTile(
                  title: context.l10n.asr,
                  notificationEnabled: settings.asrNotification.enabled,
                  adhanEnabled: settings.asrNotification.playAdhan,
                  onNotificationChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert(
                      'asr',
                      notificationEnabled: value,
                    ),
                  ),
                  onAdhanChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert('asr', adhanEnabled: value),
                  ),
                  notificationIdentifier:
                      PrayerNotificationSemanticsIds.asrToggle,
                ),

                _PrayerAlertTile(
                  title: context.l10n.maghrib,
                  notificationEnabled: settings.maghribNotification.enabled,
                  adhanEnabled: settings.maghribNotification.playAdhan,
                  onNotificationChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert(
                      'maghrib',
                      notificationEnabled: value,
                    ),
                  ),
                  onAdhanChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert(
                      'maghrib',
                      adhanEnabled: value,
                    ),
                  ),
                  notificationIdentifier:
                      PrayerNotificationSemanticsIds.maghribToggle,
                ),

                _PrayerAlertTile(
                  title: context.l10n.isha,
                  notificationEnabled: settings.ishaNotification.enabled,
                  adhanEnabled: settings.ishaNotification.playAdhan,
                  onNotificationChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert(
                      'isha',
                      notificationEnabled: value,
                    ),
                  ),
                  onAdhanChanged: (value) => _updateSettings(
                    settings.updatePrayerAlert('isha', adhanEnabled: value),
                  ),
                  notificationIdentifier:
                      PrayerNotificationSemanticsIds.ishaToggle,
                ),

                /// TODO: Remove this code block when releasing the app
                // if (kDebugMode || kProfileMode) ...[
                //   SizedBox(height: tokens.spaceLarge),
                //   const Divider(),
                //   SizedBox(height: tokens.spaceMedium),
                //   Center(
                //     child: TextButton.icon(
                //       onPressed: () {
                //         getIt<IPrayerAdhanNotificationService>()
                //             .debugScheduleTestAdhan();
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           const SnackBar(
                //             content: Text(
                //               'Adhan test scheduled for +10s. Close the app now!',
                //             ),
                //             duration: Duration(seconds: 5),
                //           ),
                //         );
                //       },
                //       icon: const Icon(Icons.bug_report_outlined),
                //       label: const Text('Test Adhan After 10 Seconds'),
                //       style: TextButton.styleFrom(
                //         foregroundColor: theme.colorScheme.error,
                //       ),
                //     ),
                //   ),
                //   SizedBox(height: tokens.spaceMedium),
                // ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Private helper widgets (reused from common patterns)

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.onDone,
    required this.tokens,
    required this.theme,
  });
  final VoidCallback onDone;
  final TilawaDesignTokens tokens;
  final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          identifier: PrayerNotificationSemanticsIds.notificationsSection,
          header: true,
          child: Text(
            context.l10n.prayerNotifications,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onDone,
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.identifier,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? identifier;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget tile = SwitchListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
    if (identifier != null) {
      return Semantics(identifier: identifier, child: tile);
    }
    return tile;
  }
}

class _PrayerAlertTile extends StatelessWidget {
  const _PrayerAlertTile({
    required this.title,
    required this.notificationEnabled,
    required this.adhanEnabled,
    required this.onNotificationChanged,
    required this.onAdhanChanged,
    this.supportsAdhan = true,
    this.notificationIdentifier,
  });

  final String title;
  final bool notificationEnabled;
  final bool adhanEnabled;
  final bool supportsAdhan;
  final ValueChanged<bool> onNotificationChanged;
  final ValueChanged<bool> onAdhanChanged;
  final String? notificationIdentifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Semantics(
            identifier: notificationIdentifier,
            child: TilawaIconToggle(
              icon: Icons.notifications_active_outlined,
              activeIcon: Icons.notifications_active,
              value: notificationEnabled,
              onChanged: onNotificationChanged,
              semanticLabel: context.l10n.prayerNotifications,
            ),
          ),
          if (supportsAdhan) ...[
            SizedBox(width: tokens.spaceSmall),
            TilawaIconToggle(
              icon: Icons.volume_mute_outlined,
              activeIcon: Icons.volume_up,
              value: adhanEnabled,
              onChanged: onAdhanChanged,
              semanticLabel: context.l10n.playAdhan,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.message,
    required this.onTap,
    required this.tokens,
    required this.theme,
  });
  final String message;
  final VoidCallback onTap;
  final TilawaDesignTokens tokens;
  final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: tokens.spaceSmall),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Row(
        spacing: tokens.spaceSmall,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onTertiaryContainer,
          ),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          TilawaButton(
            text: context.l10n.openSettings,
            variant: TilawaButtonVariant.ghost,
            size: TilawaButtonSize.small,
            shrinkWrapTapTarget: true,
            onPressed: onTap,
            foregroundColor: colorScheme.onTertiaryContainer,
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
            textStyle: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
    required this.tokens,
    required this.theme,
  });
  final String message;
  final TilawaDesignTokens tokens;
  final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: tokens.spaceSmall),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Row(
        spacing: tokens.spaceSmall,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSecondaryContainer,
          ),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
