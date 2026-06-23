import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_footer.dart';

/// Home dashboard card linking to the "تعلم قراءة القرآن الآن" feature.
///
/// Displays an experimental badge to signal MVP status to users.
///
/// Checks [UserProfile.isComplete] before navigating. Incomplete profiles are
/// redirected to [QuranSessionsRoutes.profileCompletion] first; on success the
/// user continues to [QuranSessionsRoutes.home].
class HomeSessionsEntryCard extends StatelessWidget {
  const HomeSessionsEntryCard({super.key});

  Future<void> _onTap(BuildContext context) async {
    await openHomeQuranSessions(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final colorScheme = theme.colorScheme;

    return TilawaCard(
      onTap: () => _onTap(context),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          children: [
            // Icon container
            Container(
              width: tokens.minInteractiveDimension,
              height: tokens.minInteractiveDimension,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: colorScheme.onPrimaryContainer,
                size: tokens.iconSizeMedium,
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
                          context.l10n.homeSessionsTitle,
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
                    context.l10n.homeSessionsSubtitle,
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
