import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/khatma_plan_boundaries.dart';
import '../formatters/khatma_wird_text.dart';

class KhatmaCurrentWirdCard extends StatelessWidget {
  const KhatmaCurrentWirdCard({
    super.key,
    required this.startPage,
    required this.endPage,
  });

  final int startPage;
  final int endPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final locale = Localizations.localeOf(context);
    final l10n = context.l10n;
    final int? juz = juzForPage(startPage);
    final startVerse = KhatmaPlanBoundaries.firstVerseOnPage(startPage);
    final endVerse = KhatmaPlanBoundaries.lastVerseOnPage(endPage);
    final preview = openingVersePreview(startPage);

    return TilawaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceMedium,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.khatmaFromHisWords,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (juz != null)
                Text(
                  l10n.khatmaJuzLabel(juz),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          if (preview != null)
            Text(
              preview,
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          if (startVerse != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatKhatmaSurahAyah(
                      l10n,
                      locale,
                      startVerse.surah,
                      startVerse.ayah,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  l10n.khatmaPageLabel(startPage),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          if (endVerse != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatKhatmaSurahAyah(
                      l10n,
                      locale,
                      endVerse.surah,
                      endVerse.ayah,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  l10n.khatmaPageLabel(endPage),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
