import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../bloc/prayer_permissions_cubit.dart';
import '../bloc/prayer_times_bloc.dart';
import '../prayer_alerts_permission_navigation.dart';
import '../prayer_alerts_setup_pending_steps.dart';
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
    final basePadding = TilawaBottomSheetScaffold.resolvedBodyPadding(context);
    final scrollPadding = basePadding;

    final settings = context.select(
      (PrayerTimesBloc bloc) => bloc.state.settings,
    );

    return TilawaBottomSheetScaffold(
      topBar: Semantics(
        identifier: PrayerNotificationSemanticsIds.notificationsSection,
        header: true,
        child: Text(
          context.l10n.prayerNotifications,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      footer: TilawaBottomSheetActions(
        primaryLabel: context.l10n.done,
        onPrimary: _close,
      ),
      betweenTopBarAndBody: const [Divider(height: 1)],
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: scrollPadding,
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                BlocBuilder<PrayerPermissionsCubit, PrayerPermissionsState>(
                  buildWhen: (p, c) => p.capability != c.capability,
                  builder: (context, state) {
                    final bool hasPendingSetup = prayerAlertsSetupPendingSteps(
                      hasLocationPermission: state.hasLocationPermission,
                      capability: state.capability,
                    ).isNotEmpty;
                    if (!hasPendingSetup) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceMedium),
                      child: _PermissionSetupCard(
                        onSetUp: () =>
                            PrayerAlertsPermissionNavigation.show(context),
                        tokens: tokens,
                        theme: theme,
                      ),
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

                if (settings.fajrNotification.playAdhan ||
                    settings.dhuhrNotification.playAdhan ||
                    settings.asrNotification.playAdhan ||
                    settings.maghribNotification.playAdhan ||
                    settings.ishaNotification.playAdhan) ...[
                  SizedBox(height: tokens.spaceMedium),
                  _GlobalSoundSelector(
                    currentSound: settings.dhuhrNotification.adhanSound,
                    onSoundSelected: (sound) {
                      _updateSettings(settings.copyWithGlobalAdhanSound(sound));
                    },
                  ),
                ],

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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Private helper widgets (reused from common patterns)

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
    final Widget tile = TilawaSettingsSwitchTile(
      title: title,
      value: value,
      onChanged: onChanged,
      showDivider: false,
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

class _PermissionSetupCard extends StatelessWidget {
  const _PermissionSetupCard({
    required this.onSetUp,
    required this.tokens,
    required this.theme,
  });

  final VoidCallback onSetUp;
  final MeMuslimDesignTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spaceMedium),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceSmall,
        children: <Widget>[
          Text(
            context.l10n.prayerAlertsPermissionSetupRequired,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TilawaButton(
              text: context.l10n.prayerAlertsPermissionSetupAction,
              variant: TilawaButtonVariant.ghost,
              size: TilawaButtonSize.small,
              shrinkWrapTapTarget: true,
              onPressed: onSetUp,
              foregroundColor: colorScheme.onTertiaryContainer,
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalSoundSelector extends StatelessWidget {
  const _GlobalSoundSelector({
    required this.currentSound,
    required this.onSoundSelected,
  });

  final String currentSound;
  final ValueChanged<String> onSoundSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    // Use default adhan if empty or unexpected
    final normalizedSound =
        ['adhan_1', 'adhan_2', 'adhan_3'].contains(currentSound)
        ? currentSound
        : 'adhan_1';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.playAdhan, // Reusing localized string
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'adhan_1',
                label: Text(context.l10n.adhanSound1),
              ),
              ButtonSegment<String>(
                value: 'adhan_2',
                label: Text(context.l10n.adhanSound2),
              ),
              ButtonSegment<String>(
                value: 'adhan_3',
                label: Text(context.l10n.adhanSound3),
              ),
            ],
            selected: {normalizedSound},
            onSelectionChanged: (Set<String> newSelection) {
              onSoundSelected(newSelection.first);
            },
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
