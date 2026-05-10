import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/core/extensions.dart';
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
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(tokens.radiusExtraLarge),
            ),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: tokens.borderWidthThin,
              ),
            ),
          ),
          child: Column(
            children: [
              const TilawaSheetHandle(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceLarge,
                  tokens.spaceSmall,
                  tokens.spaceLarge,
                  tokens.spaceMedium,
                ),
                child: Text(
                  context.l10n.readerSettings,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const TilawaDivider(),

              // Settings list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(tokens.spaceLarge),
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

                    SizedBox(height: tokens.spaceLarge),

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

                    SizedBox(height: tokens.spaceLarge),

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

                    SizedBox(height: tokens.spaceExtraLarge),

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
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSmall),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
