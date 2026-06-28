import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// CTA to open Tilawa Quran reader for session revision surah context.
class SessionRevisionPracticeCard extends StatelessWidget {
  const SessionRevisionPracticeCard({
    super.key,
    required this.surahNumber,
    this.ayahNumber,
    required this.onPracticeTapped,
    this.isCompletedSession = false,
  });

  final int surahNumber;
  final int? ayahNumber;
  final VoidCallback onPracticeTapped;
  final bool isCompletedSession;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return TilawaCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: tokens.iconSizeMedium,
                  color: scheme.primary,
                ),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompletedSession
                            ? l10n.sessionRevisionPracticeCompletedTitle
                            : l10n.sessionRevisionPracticeUpcomingTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        l10n.sessionRevisionPracticeBody(surahNumber),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceMedium),
            TilawaButton(
              text: l10n.sessionRevisionPracticeAction,
              variant: TilawaButtonVariant.secondary,
              isFullWidth: true,
              onPressed: onPracticeTapped,
            ),
          ],
        ),
      ),
    );
  }
}
