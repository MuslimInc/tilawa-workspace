import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/services/adhan_qa_service.dart';
import 'package:tilawa/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../bloc/prayer_times_bloc.dart';

/// A bottom sheet for managing prayer time settings.
class PrayerSettingsSheet extends StatefulWidget {
  const PrayerSettingsSheet({super.key});

  @override
  State<PrayerSettingsSheet> createState() => _PrayerSettingsSheetState();
}

class _PrayerSettingsSheetState extends State<PrayerSettingsSheet> {
  @override
  void initState() {
    super.initState();
    if (AdhanQAService.isEnabled) {
      AdhanQAService().init();
    }
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
    final settings = context.select(
      (PrayerTimesBloc bloc) => bloc.state.settings,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radiusExtraLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TilawaSheetHandle(),
              _SheetHeader(onClose: _close, tokens: tokens, theme: theme),
              const TilawaDivider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(tokens.spaceLarge),
                  children: [
                    _SectionTitle(
                      title: context.l10n.calculationMethod,
                      tokens: tokens,
                      theme: theme,
                    ),
                    _SettingsDropdown<CalculationMethod>(
                      value: settings.calculationMethod,
                      items: CalculationMethod.values,
                      labelBuilder: (method) => method.localize(context.l10n),
                      onChanged: (method) {
                        if (method != null) {
                          _updateSettings(
                            settings.copyWith(calculationMethod: method),
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
                      value: settings.asrJuristicMethod,
                      items: AsrJuristicMethod.values,
                      labelBuilder: (method) => method.localize(context.l10n),
                      onChanged: (method) {
                        if (method != null) {
                          _updateSettings(
                            settings.copyWith(asrJuristicMethod: method),
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
                      value: settings.use24HourFormat,
                      onChanged: (value) {
                        _updateSettings(
                          settings.copyWith(use24HourFormat: value),
                        );
                      },
                    ),
                    _SettingsSwitch(
                      title: context.l10n.showSunrise,
                      value: settings.showSunrise,
                      onChanged: (value) {
                        _updateSettings(settings.copyWith(showSunrise: value));
                      },
                    ),
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, appSettings) {
                        return _SettingsSwitch(
                          title: context.l10n.showPrayerTimesAlertChipLabels,
                          value: appSettings.showPrayerTimesAlertChipLabels,
                          onChanged: (value) {
                            context
                                .read<SettingsCubit>()
                                .setShowPrayerTimesAlertChipLabels(value);
                          },
                        );
                      },
                    ),
                    // TODO: Re-enable Time Adjustments after the Prayer Times
                    // UX stabilizes. The feature is intentionally hidden for
                    // now to keep settings simple and avoid advanced controls.
                    if (AdhanQAService.isEnabled) ...[
                      SizedBox(height: tokens.spaceLarge),
                      const _QASection(),
                      SizedBox(height: tokens.spaceLarge),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.onClose,
    required this.tokens,
    required this.theme,
  });

  final VoidCallback onClose;
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
            onPressed: onClose,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
            ),
            child: Text(
              context.l10n.done,
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
      key: ValueKey<Object?>(value),
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
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

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

    return tile;
  }
}

class _QASection extends StatefulWidget {
  const _QASection();

  @override
  State<_QASection> createState() => _QASectionState();
}

class _QASectionState extends State<_QASection> {
  final AdhanQAService _qaService = AdhanQAService();
  bool _isLoading = false;

  Future<void> _schedule(int minutes) async {
    setState(() => _isLoading = true);
    try {
      await _qaService.scheduleTestAdhan(delayMinutes: minutes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scheduled Adhan in $minutes minutes')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _isLoading = true);
    try {
      await _qaService.cancelTestAdhan();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cancelled test Adhan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewLogs() async {
    final logs = await _qaService.getLogs();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adhan QA Logs'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              logs,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _qaService.clearLogs();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'QA TOOLS (Adhan Native)',
          tokens: tokens,
          theme: theme,
        ),
        Container(
          padding: EdgeInsets.all(tokens.spaceMedium),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: tokens.spaceSmall,
                runSpacing: tokens.spaceSmall,
                children: [
                  FilledButton.tonal(
                    onPressed: _isLoading ? null : () => _schedule(2),
                    child: const Text('Schedule 2m'),
                  ),
                  FilledButton.tonal(
                    onPressed: _isLoading ? null : () => _schedule(5),
                    child: const Text('Schedule 5m'),
                  ),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _cancel,
                    child: const Text('Cancel Test'),
                  ),
                  TextButton.icon(
                    onPressed: _viewLogs,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Logs'),
                  ),
                ],
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 8),
              Text(
                'Tests real AlarmManager pipeline. Close app/lock device to verify.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
