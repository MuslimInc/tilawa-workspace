import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../models/prayer_row_view_data.dart';

/// Compact Prayer Times alert state chip.
class PrayerAlertStatusChip extends StatelessWidget {
  const PrayerAlertStatusChip({
    super.key,
    required this.alert,
    this.showLabel = true,
  });

  final PrayerAlertViewData alert;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _alertColors(colorScheme, alert.state);

    return Semantics(
      label: alert.label,
      child: TilawaStatusChip(
        label: alert.label,
        icon: _alertIcon(alert.state),
        backgroundColor: colors.$1,
        foregroundColor: colors.$2,
        showLabel: showLabel,
      ),
    );
  }

  IconData _alertIcon(PrayerAlertViewState state) {
    return switch (state) {
      PrayerAlertViewState.off => Icons.notifications_off_outlined,
      PrayerAlertViewState.notification => Icons.notifications_active_outlined,
      PrayerAlertViewState.adhan => Icons.volume_up_outlined,
    };
  }

  (Color, Color) _alertColors(
    ColorScheme colorScheme,
    PrayerAlertViewState state,
  ) {
    return switch (state) {
      PrayerAlertViewState.off => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      PrayerAlertViewState.notification => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      PrayerAlertViewState.adhan => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
    };
  }
}
