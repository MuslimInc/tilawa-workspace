import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/khatma_session.dart';
import '../formatters/khatma_page_range_text.dart';
import '../formatters/khatma_wird_text.dart';

class KhatmaSessionsListScreen extends StatelessWidget {
  const KhatmaSessionsListScreen({
    super.key,
    required this.title,
    required this.sessions,
  });

  final String title;
  final List<KhatmaSession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final locale = Localizations.localeOf(context);
    final l10n = context.l10n;

    return TilawaShellChildScaffold(
      appBar: TilawaCatalogAppBar.titleOnly(
        title: title,
        automaticallyImplyLeading: true,
        onBackPressed: () => context.pop(),
      ),
      body: ListView.separated(
        padding: EdgeInsetsDirectional.fromSTEB(
          theme.componentTokens.settingsGroup.groupHorizontalPadding,
          tokens.spaceLarge,
          theme.componentTokens.settingsGroup.groupHorizontalPadding,
          tokens.spaceHuge,
        ),
        itemCount: sessions.length,
        separatorBuilder: (_, _) => SizedBox(height: tokens.spaceMedium),
        itemBuilder: (context, index) {
          final session = sessions[index];
          final startVerse = session.startVerse;
          final endVerse = session.endVerse;

          return TilawaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceSmall,
              children: [
                Text(
                  l10n.khatmaSessionNumber(session.index),
                  style: theme.textTheme.titleMedium,
                ),
                if (startVerse != null && endVerse != null)
                  Text(
                    '${formatKhatmaSurahAyah(l10n, locale, startVerse.surah, startVerse.ayah)} — '
                    '${formatKhatmaSurahAyah(l10n, locale, endVerse.surah, endVerse.ayah)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                Text(
                  formatKhatmaPageRange(
                    l10n,
                    session.startPage,
                    session.endPage,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
