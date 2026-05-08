import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/services/adhan_qa_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../bloc/prayer_permissions_cubit.dart';
import '../bloc/prayer_times_bloc.dart';

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
    context.read<PrayerPermissionsCubit>().checkCapability();
    if (AdhanQAService.isEnabled) {
      AdhanQAService().init();
    }
  }

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
                const TilawaDivider(height: 1),
                Flexible(
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
