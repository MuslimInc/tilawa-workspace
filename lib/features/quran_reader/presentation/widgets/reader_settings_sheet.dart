import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../domain/entities/entities.dart';

class ReaderSettingsSheet extends StatefulWidget {
  const ReaderSettingsSheet({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final ReaderSettingsEntity settings;
  final void Function(ReaderSettingsEntity) onSettingsChanged;

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late ReaderSettingsEntity _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSettings(ReaderSettingsEntity newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.readerSettings,
                  style: theme.textTheme.titleLarge,
                ),
              ),

              const Divider(height: 1),

              // Settings list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Font size
                    _buildSectionTitle(context, context.l10n.fontSize),
                    Slider(
                      value: _settings.fontSize,
                      min: 16,
                      max: 40,
                      divisions: 12,
                      label: _settings.fontSize.round().toString(),
                      onChanged: (value) {
                        _updateSettings(_settings.copyWith(fontSize: value));
                      },
                    ),

                    const SizedBox(height: 16),

                    // Line height
                    _buildSectionTitle(context, context.l10n.lineHeight),
                    Slider(
                      value: _settings.lineHeight,
                      min: 1.2,
                      max: 2.5,
                      divisions: 13,
                      label: _settings.lineHeight.toStringAsFixed(1),
                      onChanged: (value) {
                        _updateSettings(_settings.copyWith(lineHeight: value));
                      },
                    ),

                    const SizedBox(height: 16),

                    // Font type
                    _buildSectionTitle(context, context.l10n.fontType),
                    SegmentedButton<QuranFontType>(
                      segments: QuranFontType.values.map((type) {
                        return ButtonSegment(
                          value: type,
                          label: Text(type.displayName),
                        );
                      }).toList(),
                      selected: {_settings.fontType},
                      onSelectionChanged: (selection) {
                        _updateSettings(
                          _settings.copyWith(fontType: selection.first),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Display options
                    _buildSectionTitle(context, context.l10n.displayOptions),
                    SwitchListTile(
                      title: Text(context.l10n.showTranslation),
                      value: _settings.showTranslation,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(showTranslation: value),
                        );
                      },
                    ),
                    SwitchListTile(
                      title: Text(context.l10n.showAyahNumbers),
                      value: _settings.showAyahNumbers,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(showAyahNumbers: value),
                        );
                      },
                    ),
                    SwitchListTile(
                      title: Text(context.l10n.showTransliteration),
                      value: _settings.showTransliteration,
                      onChanged: (value) {
                        _updateSettings(
                          _settings.copyWith(showTransliteration: value),
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
}
