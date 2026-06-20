import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home dashboard card linking to the "تعلم قراءة القرآن الآن" feature.
///
/// Displays an experimental badge to signal MVP status to users.
class HomeSessionsEntryCard extends StatelessWidget {
  const HomeSessionsEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final colorScheme = theme.colorScheme;

    return TilawaCard(
      onTap: () => context.push(QuranSessionsRoutes.home),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            SizedBox(width: tokens.spaceMedium),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'تعلم قراءة القرآن الآن',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.spaceSmall),
                      TilawaExperimentalBadge(
                        label: context.l10n.experimentalBadgeLabel,
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    'احجز جلسات مع معلمين معتمدين',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
