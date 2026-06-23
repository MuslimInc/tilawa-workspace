import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/core/extensions.dart';
import '../cubit/quran_settings_cubit.dart';
import '../../domain/constants/quran_translation_catalog.dart';
import '../../domain/entities/entities.dart';

Future<void> showReaderSettingsSheet({
  required BuildContext context,
  required QuranSettingsCubit settingsCubit,
}) {
  final ThemeData theme = Theme.of(context);

  return showTilawaModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (sheetContext) {
      return BlocProvider<QuranSettingsCubit>.value(
        value: settingsCubit,
        child: BlocBuilder<QuranSettingsCubit, ReaderSettingsEntity>(
          builder: (context, settings) {
            return ReaderSettingsSheet(
              settings: settings,
              onSettingsChanged: settingsCubit.update,
            );
          },
        ),
      );
    },
  );
}

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

  @override
  void didUpdateWidget(ReaderSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  void _updateSettings(ReaderSettingsEntity newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: context.viewportHeight * 0.86,
      ),
      child: SafeArea(
        top: false,
        child: TilawaBottomSheetScaffold(
          topBar: Text(
            context.l10n.readerSettings,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          betweenTopBarAndBody: const [TilawaDivider(height: 1)],
          footer: TilawaBottomSheetActions(
            primaryLabel: context.l10n.done,
            onPrimary: _close,
          ),
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
                children: [
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
                  _buildSectionTitle(context, context.l10n.fontType),
                  TilawaSegmentedControl<QuranFontType>(
                    selectedValue: _settings.fontType,
                    onValueChanged: (value) {
                      _updateSettings(_settings.copyWith(fontType: value));
                    },
                    segments: QuranFontType.values
                        .map(
                          (type) => TilawaSegment(
                            value: type,
                            label: type.displayName,
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: tokens.spaceExtraLarge),
                  _buildSectionTitle(context, context.l10n.displayOptions),
                  TilawaCatalogSettingsSwitchRow(
                    title: context.l10n.showTranslation,
                    value: _settings.showTranslation,
                    onChanged: (value) {
                      _updateSettings(
                        _settings.copyWith(showTranslation: value),
                      );
                    },
                  ),
                  if (_settings.showTranslation &&
                      QuranTranslationCatalog.hasBundledTranslation(
                        _settings.translationLanguage,
                      ))
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        tokens.spaceMedium,
                        0,
                        tokens.spaceMedium,
                        tokens.spaceSmall,
                      ),
                      child: Text(
                        context.l10n.quranTranslationAttribution(
                          QuranTranslationCatalog.translationName(
                            _settings.translationLanguage,
                          ),
                          QuranTranslationCatalog.qulSourceName,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  TilawaCatalogSettingsSwitchRow(
                    title: context.l10n.showAyahNumbers,
                    value: _settings.showAyahNumbers,
                    onChanged: (value) {
                      _updateSettings(
                        _settings.copyWith(showAyahNumbers: value),
                      );
                    },
                  ),
                  TilawaCatalogSettingsSwitchRow(
                    title: context.l10n.showTransliteration,
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
      ),
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
