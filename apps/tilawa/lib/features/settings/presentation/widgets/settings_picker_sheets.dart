import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../color_picker/color_picker.dart';
import '../../../localization/presentation/bloc/localization_bloc.dart';
import '../../../theme/domain/primary_color_preset.dart';
import '../../../theme/presentation/cubit/theme_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/settings_cubit.dart';

/// Opens settings-related picker and confirmation sheets.
abstract final class SettingsSheets {
  static void showPrimaryColorPicker(
    BuildContext context, {
    required Color currentColor,
    required PrimaryColorSource currentSource,
    required String? currentPresetId,
  }) {
    showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (sheetContext) => SettingsPrimaryColorSheet(
        currentColor: currentColor,
        currentSource: currentSource,
        currentPresetId: currentPresetId,
        onCustomColorTap: () {
          Navigator.pop(sheetContext);
          SettingsSheets.showCustomPrimaryColorPicker(
            context,
            currentColor: currentColor,
          );
        },
      ),
    );
  }

  static void showCustomPrimaryColorPicker(
    BuildContext context, {
    required Color currentColor,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        var pickerColor = currentColor;
        return AlertDialog(
          title: Text(ctx.l10n.choosePrimaryColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
            ),
          ),
          actions: [
            TilawaButton(
              text: ctx.l10n.cancel,
              variant: TilawaButtonVariant.ghost,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TilawaButton(
              text: ctx.l10n.save,
              variant: TilawaButtonVariant.primary,
              onPressed: () {
                ctx.read<ThemeCubit>().setPrimaryColorArgb(
                  pickerColor.toARGB32(),
                );
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void showLanguagePicker(
    BuildContext context, {
    required Locale currentLocale,
  }) {
    showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (_) => SettingsLanguageSheet(currentLocale: currentLocale),
    );
  }

  static void showConcurrentDownloadsPicker(
    BuildContext context, {
    required int currentValue,
  }) {
    showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (_) => SettingsConcurrentDownloadsSheet(
        currentValue: currentValue,
      ),
    );
  }

  static Future<void> showLogoutConfirmation(BuildContext context) {
    return showTilawaConfirmSheet(
      context: context,
      title: context.l10n.logout,
      message: context.l10n.logoutConfirmation,
      confirmLabel: context.l10n.logout,
      cancelLabel: context.l10n.cancel,
      onConfirm: () {
        Navigator.pop(context, true);
        context.read<AuthBloc>().add(const SignOutEvent());
      },
      onClose: () => Navigator.pop(context, false),
    );
  }
}

class SettingsPrimaryColorSheet extends StatelessWidget {
  const SettingsPrimaryColorSheet({
    super.key,
    required this.currentColor,
    required this.currentSource,
    required this.currentPresetId,
    required this.onCustomColorTap,
  });

  final Color currentColor;
  final PrimaryColorSource currentSource;
  final String? currentPresetId;
  final VoidCallback onCustomColorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = currentSource == PrimaryColorSource.custom;

    return TilawaBottomSheetScaffold(
      topBar: Text(
        context.l10n.choosePrimaryColor,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
            children: [
              ...PrimaryColorPreset.values.map((preset) {
                final isSelected =
                    !isCustom && currentPresetId == preset.id;
                return TilawaSelectionTile(
                  leading: CircleAvatar(
                    backgroundColor: preset.value,
                    radius: TilawaSettingsScreenTokens
                        .primaryPickerPresetSwatchRadius,
                  ),
                  title: _localizedPresetName(context, preset),
                  isSelected: isSelected,
                  onTap: () {
                    context.read<ThemeCubit>().setPrimaryPreset(preset);
                    Navigator.pop(context);
                  },
                );
              }),
              TilawaSelectionTile(
                leading: CircleAvatar(
                  radius: TilawaSettingsScreenTokens
                      .primaryPickerPresetSwatchRadius,
                  backgroundColor: isCustom
                      ? currentColor
                      : theme.colorScheme.surfaceContainerHigh,
                  child: isCustom
                      ? null
                      : Icon(
                          FluentIcons.color_24_regular,
                          size:
                              TilawaSettingsScreenTokens
                                  .primaryPickerCustomSwatchSize *
                              0.5,
                          color: theme.colorScheme.primary,
                        ),
                ),
                title: context.l10n.custom,
                isSelected: isCustom,
                onTap: onCustomColorTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsLanguageSheet extends StatelessWidget {
  const SettingsLanguageSheet({super.key, required this.currentLocale});

  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    return TilawaBottomSheetScaffold(
      topBar: Text(
        context.l10n.chooseLanguage,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
            children: [
              TilawaSelectionTile(
                title: 'العربية',
                isSelected:
                    currentLocale.languageCode == arabicLanguageCode,
                onTap: () {
                  context.read<LocalizationBloc>().add(
                    const ChangeLanguage(Locale(arabicLanguageCode)),
                  );
                  Navigator.pop(context);
                },
              ),
              TilawaSelectionTile(
                title: 'English',
                isSelected:
                    currentLocale.languageCode == englishLanguageCode,
                onTap: () {
                  context.read<LocalizationBloc>().add(
                    const ChangeLanguage(Locale(englishLanguageCode)),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsConcurrentDownloadsSheet extends StatelessWidget {
  const SettingsConcurrentDownloadsSheet({
    super.key,
    required this.currentValue,
  });

  final int currentValue;

  @override
  Widget build(BuildContext context) {
    return TilawaBottomSheetScaffold(
      topBar: Text(
        context.l10n.concurrentDownloads,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
            children: [
              for (
                int i = 1;
                i <=
                    TilawaSettingsScreenTokens
                        .maxConcurrentDownloadsPickerCount;
                i++
              )
                TilawaSelectionTile(
                  title: '$i',
                  isSelected: currentValue == i,
                  onTap: () {
                    context.read<SettingsCubit>().setMaxConcurrentDownloads(i);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _localizedPresetName(BuildContext context, PrimaryColorPreset preset) {
  final l10n = context.l10n;
  return switch (preset) {
    PrimaryColorPreset.coral => l10n.colorCoral,
    PrimaryColorPreset.teal => l10n.colorCyan,
    PrimaryColorPreset.sage => l10n.colorGreen,
    PrimaryColorPreset.gold => l10n.colorGold,
    PrimaryColorPreset.brown => l10n.colorBrown,
    PrimaryColorPreset.purple => l10n.colorPurple,
  };
}
