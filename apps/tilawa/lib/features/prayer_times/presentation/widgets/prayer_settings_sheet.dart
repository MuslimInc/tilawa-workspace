import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../bloc/prayer_times_bloc.dart';
import '../prayer_notification_semantics_ids.dart';

/// A bottom sheet for managing prayer time settings.
class PrayerSettingsSheet extends StatefulWidget {
  const PrayerSettingsSheet({super.key});

  @override
  State<PrayerSettingsSheet> createState() => _PrayerSettingsSheetState();
}

class _PrayerSettingsSheetState extends State<PrayerSettingsSheet> {
  late PrayerSettingsEntity _settings;

  @override
  void initState() {
    super.initState();
    _settings = context.read<PrayerTimesBloc>().state.settings;
    context.read<PrayerTimesBloc>().add(
      const PrayerTimesEvent.checkAlarmCapability(),
    );
  }

  bool get _allNotificationsEnabled =>
      _settings.fajrNotification.enabled &&
      _settings.dhuhrNotification.enabled &&
      _settings.asrNotification.enabled &&
      _settings.maghribNotification.enabled &&
      _settings.ishaNotification.enabled;

  int get _globalMinutesBefore => _settings.fajrNotification.minutesBefore;

  bool get _globalPlayAdhan => _settings.fajrNotification.playAdhan;

  void _updateSettings(PrayerSettingsEntity newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  void _saveSettings() {
    context.read<PrayerTimesBloc>().add(
      PrayerTimesEvent.updateSettings(_settings),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return BlocListener<PrayerTimesBloc, PrayerTimesState>(
          listenWhen: (previous, current) =>
              previous.settings != current.settings,
          listener: (context, state) {
            setState(() {
              _settings = state.settings;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(tokens.radiusExtraLarge),
              ),
            ),
            child: Column(
              children: [
                _SheetHandle(tokens: tokens, colorScheme: colorScheme),
                _SheetHeader(
                  onSave: _saveSettings,
                  tokens: tokens,
                  theme: theme,
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.all(tokens.spaceLarge),
                    children: [
                      _SectionTitle(
                        title: context.l10n.calculationMethod,
                        tokens: tokens,
                        theme: theme,
                      ),
                      _SettingsDropdown<CalculationMethod>(
                        value: _settings.calculationMethod,
                        items: CalculationMethod.values,
                        labelBuilder: (method) => method.localize(context.l10n),
                        onChanged: (method) {
                          if (method != null) {
                            _updateSettings(
                              _settings.copyWith(calculationMethod: method),
                            );
                          }
                        },
                      ),
                      SizedBox(height: tokens.spaceLarge),
                      _SectionTitle(
                        title: context.l10n.asrCalculation,
                        tokens: tokens,
                        theme: theme,
                      ),
                      _SettingsDropdown<AsrJuristicMethod>(
                        value: _settings.asrJuristicMethod,
                        items: AsrJuristicMethod.values,
                        labelBuilder: (method) => method.localize(context.l10n),
                        onChanged: (method) {
                          if (method != null) {
                            _updateSettings(
                              _settings.copyWith(asrJuristicMethod: method),
                            );
                          }
                        },
                      ),
                      SizedBox(height: tokens.spaceLarge),
                      _SectionTitle(
                        title: context.l10n.displayOptions,
                        tokens: tokens,
                        theme: theme,
                      ),
                      _SettingsSwitch(
                        title: context.l10n.use24HourFormat,
                        value: _settings.use24HourFormat,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(use24HourFormat: value),
                          );
                        },
                      ),
                      _SettingsSwitch(
                        title: context.l10n.showSunrise,
                        value: _settings.showSunrise,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(showSunrise: value),
                          );
                        },
                      ),
                      SizedBox(height: tokens.spaceLarge),
                      _SectionTitle(
                        title: context.l10n.timeAdjustments,
                        tokens: tokens,
                        theme: theme,
                      ),
                      _AdjustmentSlider(
                        label: context.l10n.fajr,
                        value: _settings.fajrAdjustment,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(fajrAdjustment: value.round()),
                          );
                        },
                      ),
                      _AdjustmentSlider(
                        label: context.l10n.dhuhr,
                        value: _settings.dhuhrAdjustment,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(dhuhrAdjustment: value.round()),
                          );
                        },
                      ),
                      _AdjustmentSlider(
                        label: context.l10n.asr,
                        value: _settings.asrAdjustment,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(asrAdjustment: value.round()),
                          );
                        },
                      ),
                      _AdjustmentSlider(
                        label: context.l10n.maghrib,
                        value: _settings.maghribAdjustment,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(
                              maghribAdjustment: value.round(),
                            ),
                          );
                        },
                      ),
                      _AdjustmentSlider(
                        label: context.l10n.isha,
                        value: _settings.ishaAdjustment,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(ishaAdjustment: value.round()),
                          );
                        },
                      ),
                      SizedBox(height: tokens.spaceLarge),
                      Semantics(
                        identifier:
                            PrayerNotificationSemanticsIds.notificationsSection,
                        child: _SectionTitle(
                          title: context.l10n.prayerNotifications,
                          tokens: tokens,
                          theme: theme,
                        ),
                      ),
                      BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
                        buildWhen: (p, c) =>
                            p.alarmCapability != c.alarmCapability,
                        builder: (context, state) {
                          final capability = state.alarmCapability;
                          if (capability == null) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              if (!capability.hasNotificationPermission)
                                _PermissionBanner(
                                  message: context
                                      .l10n
                                      .notificationPermissionRequired,
                                  onTap: () => context.read<PrayerTimesBloc>().add(
                                    const PrayerTimesEvent.requestNotificationPermission(),
                                  ),
                                  tokens: tokens,
                                  theme: theme,
                                ),
                              if (capability.hasNotificationPermission &&
                                  !capability.canScheduleExact)
                                _PermissionBanner(
                                  message:
                                      context.l10n.exactAlarmPermissionRequired,
                                  onTap: () => context.read<PrayerTimesBloc>().add(
                                    const PrayerTimesEvent.requestExactAlarmPermission(),
                                  ),
                                  tokens: tokens,
                                  theme: theme,
                                ),
                            ],
                          );
                        },
                      ),
                      _SettingsSwitch(
                        title: context.l10n.prayerNotificationsEnabledAll,
                        value: _allNotificationsEnabled,
                        identifier: PrayerNotificationSemanticsIds.globalToggle,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(
                              fajrNotification: _settings.fajrNotification
                                  .copyWith(enabled: value),
                              dhuhrNotification: _settings.dhuhrNotification
                                  .copyWith(enabled: value),
                              asrNotification: _settings.asrNotification
                                  .copyWith(enabled: value),
                              maghribNotification: _settings.maghribNotification
                                  .copyWith(enabled: value),
                              ishaNotification: _settings.ishaNotification
                                  .copyWith(enabled: value),
                            ),
                          );
                        },
                      ),
                      _SettingsSwitch(
                        title: context.l10n.fajr,
                        value: _settings.fajrNotification.enabled,
                        identifier: PrayerNotificationSemanticsIds.fajrToggle,
                        onChanged: (value) => _updateSettings(
                          _settings.copyWith(
                            fajrNotification: _settings.fajrNotification
                                .copyWith(enabled: value),
                          ),
                        ),
                      ),
                      _SettingsSwitch(
                        title: context.l10n.dhuhr,
                        value: _settings.dhuhrNotification.enabled,
                        identifier: PrayerNotificationSemanticsIds.dhuhrToggle,
                        onChanged: (value) => _updateSettings(
                          _settings.copyWith(
                            dhuhrNotification: _settings.dhuhrNotification
                                .copyWith(enabled: value),
                          ),
                        ),
                      ),
                      _SettingsSwitch(
                        title: context.l10n.asr,
                        value: _settings.asrNotification.enabled,
                        identifier: PrayerNotificationSemanticsIds.asrToggle,
                        onChanged: (value) => _updateSettings(
                          _settings.copyWith(
                            asrNotification: _settings.asrNotification.copyWith(
                              enabled: value,
                            ),
                          ),
                        ),
                      ),
                      _SettingsSwitch(
                        title: context.l10n.maghrib,
                        value: _settings.maghribNotification.enabled,
                        identifier:
                            PrayerNotificationSemanticsIds.maghribToggle,
                        onChanged: (value) => _updateSettings(
                          _settings.copyWith(
                            maghribNotification: _settings.maghribNotification
                                .copyWith(enabled: value),
                          ),
                        ),
                      ),
                      _SettingsSwitch(
                        title: context.l10n.isha,
                        value: _settings.ishaNotification.enabled,
                        identifier: PrayerNotificationSemanticsIds.ishaToggle,
                        onChanged: (value) => _updateSettings(
                          _settings.copyWith(
                            ishaNotification: _settings.ishaNotification
                                .copyWith(enabled: value),
                          ),
                        ),
                      ),
                      if (_allNotificationsEnabled) ...[
                        SizedBox(height: tokens.spaceSmall),
                        Semantics(
                          identifier:
                              PrayerNotificationSemanticsIds.minutesBefore,
                          child: _MinutesBeforePicker(
                            value: _globalMinutesBefore,
                            onChanged: (newValue) {
                              _updateSettings(
                                _settings.copyWith(
                                  fajrNotification: _settings.fajrNotification
                                      .copyWith(minutesBefore: newValue),
                                  dhuhrNotification: _settings.dhuhrNotification
                                      .copyWith(minutesBefore: newValue),
                                  asrNotification: _settings.asrNotification
                                      .copyWith(minutesBefore: newValue),
                                  maghribNotification: _settings
                                      .maghribNotification
                                      .copyWith(minutesBefore: newValue),
                                  ishaNotification: _settings.ishaNotification
                                      .copyWith(minutesBefore: newValue),
                                ),
                              );
                            },
                            tokens: tokens,
                            theme: theme,
                          ),
                        ),
                      ],
                      _SettingsSwitch(
                        title: context.l10n.playAdhan,
                        value: _globalPlayAdhan,
                        identifier: PrayerNotificationSemanticsIds.soundToggle,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(
                              fajrNotification: _settings.fajrNotification
                                  .copyWith(playAdhan: value),
                              dhuhrNotification: _settings.dhuhrNotification
                                  .copyWith(playAdhan: value),
                              asrNotification: _settings.asrNotification
                                  .copyWith(playAdhan: value),
                              maghribNotification: _settings.maghribNotification
                                  .copyWith(playAdhan: value),
                              ishaNotification: _settings.ishaNotification
                                  .copyWith(playAdhan: value),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.tokens, required this.colorScheme});

  final TilawaDesignTokens tokens;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: tokens.spaceSmall),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: tokens.opacityMedium),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.onSave,
    required this.tokens,
    required this.theme,
  });

  final VoidCallback onSave;
  final TilawaDesignTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLarge),
      child: Row(
        children: [
          Text(
            context.l10n.prayerSettings,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSave,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
            ),
            child: Text(
              context.l10n.save,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.tokens,
    required this.theme,
  });

  final String title;
  final TilawaDesignTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSmall),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: tokens.opacityMedium,
            ),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: tokens.opacityMedium,
            ),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(labelBuilder(item), style: theme.textTheme.bodyMedium),
        );
      }).toList(),
      onChanged: onChanged,
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

  /// Optional [Semantics.identifier] for E2E test targeting via Maestro.
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
    if (identifier case final String id) {
      return Semantics(identifier: id, child: tile);
    }
    return tile;
  }
}

class _AdjustmentSlider extends StatelessWidget {
  const _AdjustmentSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: -30,
              max: 30,
              divisions: 60,
              label: '$value ${context.l10n.minutesShort}',
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${value > 0 ? '+' : ''}$value',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown when a required permission (exact alarm or notification) is
/// not granted. Tapping [onTap] triggers the appropriate permission request.
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
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onTertiaryContainer,
          ),
          SizedBox(width: tokens.spaceSmall),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.openSettings,
              style: theme.textTheme.labelSmall?.copyWith(
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

/// Segmented picker for choosing how many minutes before the prayer time
/// the notification should fire. Options: 0, 5, 10, 15.
class _MinutesBeforePicker extends StatelessWidget {
  const _MinutesBeforePicker({
    required this.value,
    required this.onChanged,
    required this.tokens,
    required this.theme,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final TilawaDesignTokens tokens;
  final ThemeData theme;

  static const List<int> _options = [0, 5, 10, 15];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
      child: SegmentedButton<int>(
        segments: _options.map((minutes) {
          return ButtonSegment<int>(
            value: minutes,
            label: Text(
              minutes == 0
                  ? context.l10n.atPrayerTime
                  : context.l10n.minutesBefore(minutes),
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
        selected: {value},
        onSelectionChanged: (selected) {
          if (selected.isNotEmpty) {
            onChanged(selected.first);
          }
        },
        showSelectedIcon: false,
      ),
    );
  }
}
