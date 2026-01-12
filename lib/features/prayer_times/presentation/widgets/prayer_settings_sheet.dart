import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions.dart';
import '../../domain/entities/entities.dart';
import '../bloc/prayer_times_bloc.dart';

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
    final ThemeData theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      context.l10n.prayerSettings,
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saveSettings,
                      child: Text(context.l10n.save),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Settings list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Calculation method
                    _buildSectionTitle(context, context.l10n.calculationMethod),
                    _buildDropdown<CalculationMethod>(
                      value: _settings.calculationMethod,
                      items: CalculationMethod.values,
                      labelBuilder: (method) => method.displayName,
                      onChanged: (method) {
                        if (method != null) {
                          _updateSettings(
                            _settings.copyWith(calculationMethod: method),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Asr calculation
                    _buildSectionTitle(context, context.l10n.asrCalculation),
                    _buildDropdown<AsrJuristicMethod>(
                      value: _settings.asrJuristicMethod,
                      items: AsrJuristicMethod.values,
                      labelBuilder: (method) =>
                          method == AsrJuristicMethod.shafii
                          ? "Shafi'i, Maliki, Hanbali"
                          : 'Hanafi',
                      onChanged: (method) {
                        if (method != null) {
                          _updateSettings(
                            _settings.copyWith(asrJuristicMethod: method),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Display options
                    _buildSectionTitle(context, context.l10n.displayOptions),
                    SwitchListTile(
                      title: Text(context.l10n.use24HourFormat),
                      value: _settings.use24HourFormat,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(use24HourFormat: value),
                        );
                      },
                    ),
                    SwitchListTile(
                      title: Text(context.l10n.showSunrise),
                      value: _settings.showSunrise,
                      onChanged: (value) {
                        _updateSettings(_settings.copyWith(showSunrise: value));
                      },
                    ),

                    const SizedBox(height: 24),

                    // Time adjustments
                    _buildSectionTitle(context, context.l10n.timeAdjustments),
                    _buildAdjustmentSlider(
                      label: 'Fajr',
                      value: _settings.fajrAdjustment,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(fajrAdjustment: value.round()),
                        );
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'Dhuhr',
                      value: _settings.dhuhrAdjustment,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(dhuhrAdjustment: value.round()),
                        );
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'Asr',
                      value: _settings.asrAdjustment,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(asrAdjustment: value.round()),
                        );
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'Maghrib',
                      value: _settings.maghribAdjustment,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(maghribAdjustment: value.round()),
                        );
                      },
                    ),
                    _buildAdjustmentSlider(
                      label: 'Isha',
                      value: _settings.ishaAdjustment,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(ishaAdjustment: value.round()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(labelBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildAdjustmentSlider({
    required String label,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: -30,
            max: 30,
            divisions: 60,
            label: '$value min',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '$value min',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
