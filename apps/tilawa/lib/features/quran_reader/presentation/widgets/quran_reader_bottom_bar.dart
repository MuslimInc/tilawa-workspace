import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';

class QuranReaderBottomBar extends StatelessWidget {
  const QuranReaderBottomBar({
    super.key,
    required this.surahNumber,
    required this.settings,
    required this.onFontSizeChanged,
    this.onPreviousSurah,
    this.onNextSurah,
  });

  final int surahNumber;
  final ReaderSettingsEntity settings;
  final void Function(double) onFontSizeChanged;
  final VoidCallback? onPreviousSurah;
  final VoidCallback? onNextSurah;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: tokens.opacityShadow),
            blurRadius: tokens.blurShadow,
            offset: tokens.shadowOffsetSmall,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceSmall,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Font size slider
              Row(
                children: [
                  Icon(
                    Icons.text_fields,
                    size: tokens.iconSizeSmall,
                    color: colorScheme.primary,
                  ),
                  Expanded(
                    child: Slider(
                      value: settings.fontSize,
                      min: 16,
                      max: 40,
                      divisions: 12,
                      onChanged: onFontSizeChanged,
                    ),
                  ),
                  Icon(
                    Icons.text_fields,
                    size: tokens.iconSizeLarge,
                    color: colorScheme.primary,
                  ),
                ],
              ),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TilawaButton(
                    text: context.l10n.previous,
                    variant: TilawaButtonVariant.ghost,
                    size: TilawaButtonSize.small,
                    leadingIcon: const Icon(Icons.chevron_left),
                    onPressed: onPreviousSurah,
                  ),
                  Text(
                    context.l10n.surahProgress(surahNumber, 114),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TilawaButton(
                    text: context.l10n.next,
                    variant: TilawaButtonVariant.ghost,
                    size: TilawaButtonSize.small,
                    trailingIcon: const Icon(Icons.chevron_right),
                    onPressed: onNextSurah,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
