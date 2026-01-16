import 'package:flutter/material.dart';

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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Font size slider
              Row(
                children: [
                  Icon(
                    Icons.text_fields,
                    size: 16,
                    color: theme.colorScheme.primary,
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
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onPreviousSurah,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                    style: TextButton.styleFrom(
                      foregroundColor: onPreviousSurah != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  Text(
                    'Surah $surahNumber / 114',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onNextSurah,
                    icon: const Text('Next'),
                    label: const Icon(Icons.chevron_right),
                    style: TextButton.styleFrom(
                      foregroundColor: onNextSurah != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
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
