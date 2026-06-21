import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../quran_sessions/presentation/quran_sessions_user.dart';

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
    final userId = quranSessionsCurrentUserId(getIt);
    if (userId == null) {
      context.push('/login');
      return;
    }

    final result = await getIt<GetUserProfileUseCase>()(userId);
    if (!context.mounted) return;

    final profile = result.fold((_) => null, (p) => p);
    if (profile != null && profile.isComplete) {
      context.push(QuranSessionsRoutes.home);
      return;
    }

    // Profile is missing or incomplete — gate before entering sessions.
    final completed = await context.push<bool>(
      QuranSessionsRoutes.profileCompletion,
    );
    if (!context.mounted) return;
    if (completed == true) {
      context.push(QuranSessionsRoutes.home);
    }
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
