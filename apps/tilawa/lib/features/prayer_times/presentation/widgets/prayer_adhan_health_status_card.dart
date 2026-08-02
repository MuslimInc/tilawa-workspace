import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/value_objects/prayer_alarm_capability.dart';
import '../bloc/prayer_permissions_cubit.dart';

/// Read-only Adhan readiness summary with contextual system-settings actions.
///
/// Does not re-enable the battery-optimization wizard or restricted permission
/// request — battery/OEM actions open app settings only.
class PrayerAdhanHealthStatusCard extends StatelessWidget {
  const PrayerAdhanHealthStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final l10n = context.l10n;

    return BlocBuilder<PrayerPermissionsCubit, PrayerPermissionsState>(
      buildWhen: (PrayerPermissionsState p, PrayerPermissionsState c) =>
          p.capability != c.capability,
      builder: (BuildContext context, PrayerPermissionsState state) {
        final PrayerAlarmCapability? capability = state.capability;
        if (capability == null) {
          return const SizedBox.shrink();
        }

        return TilawaSettingsGroupPanel(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spaceMedium,
                tokens.spaceMedium,
                tokens.spaceMedium,
                tokens.spaceSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.prayerAdhanHealthTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    l10n.prayerAdhanHealthSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _HealthRow(
              label: l10n.prayerAdhanHealthNotificationsLabel,
              ready: capability.hasNotificationPermission,
              actionLabel: capability.hasNotificationPermission
                  ? null
                  : l10n.prayerAdhanHealthFixAction,
              onAction: capability.hasNotificationPermission
                  ? null
                  : () => context
                        .read<PrayerPermissionsCubit>()
                        .requestNotificationPermission(),
            ),
            _HealthRow(
              label: l10n.prayerAdhanHealthExactAlarmLabel,
              ready: capability.canScheduleExact,
              actionLabel: capability.canScheduleExact
                  ? null
                  : l10n.prayerAdhanHealthFixAction,
              onAction: capability.canScheduleExact
                  ? null
                  : () => context
                        .read<PrayerPermissionsCubit>()
                        .requestExactAlarmPermission(),
            ),
            _HealthRow(
              label: l10n.prayerAdhanHealthBatteryLabel,
              ready: capability.isIgnoringBatteryOptimizations,
              actionLabel: capability.isIgnoringBatteryOptimizations
                  ? null
                  : l10n.prayerAdhanHealthOpenSettingsAction,
              onAction: capability.isIgnoringBatteryOptimizations
                  ? null
                  : openAppSettings,
            ),
            _HealthRow(
              label: l10n.prayerAdhanHealthOemLabel,
              ready: !capability.oemRequiresAutostart,
              actionLabel: capability.oemRequiresAutostart
                  ? l10n.prayerAdhanHealthOpenSettingsAction
                  : null,
              onAction: capability.oemRequiresAutostart
                  ? openAppSettings
                  : null,
              showDivider: false,
              oemGuidance: capability.oemRequiresAutostart
                  ? l10n.prayerAlertsPermissionOemAutostartBody
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.label,
    required this.ready,
    this.actionLabel,
    this.onAction,
    this.showDivider = true,
    this.oemGuidance,
  });

  final String label;
  final bool ready;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showDivider;
  final String? oemGuidance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;
    final bool isReady = ready;
    final IconData icon = isReady
        ? Icons.check_circle_rounded
        : Icons.error_outline_rounded;
    final Color iconColor = isReady ? scheme.primary : scheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: tokens.iconSizeMedium),
              SizedBox(width: tokens.spaceSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (oemGuidance != null) ...[
                      SizedBox(height: tokens.spaceExtraSmall / 2),
                      Text(
                        oemGuidance!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TilawaButton(
                  text: actionLabel!,
                  variant: TilawaButtonVariant.ghost,
                  size: TilawaButtonSize.small,
                  onPressed: onAction,
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: tokens.spaceMedium,
            endIndent: tokens.spaceMedium,
          ),
      ],
    );
  }
}
