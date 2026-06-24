import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// In-app Friday nudge to review next week's projected availability.
class FridayReviewReminderBanner extends StatelessWidget {
  const FridayReviewReminderBanner({
    super.key,
    required this.onReview,
    required this.onDismiss,
  });

  final VoidCallback onReview;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceMedium,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        surface: TilawaCardSurface.flat,
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.fridayReviewBannerMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: tokens.spaceSmall),
            Row(
              children: [
                TilawaButton(
                  text: l10n.fridayReviewBannerDismiss,
                  variant: TilawaButtonVariant.ghost,
                  size: TilawaButtonSize.small,
                  onPressed: onDismiss,
                ),
                const Spacer(),
                TilawaButton(
                  text: l10n.fridayReviewBannerAction,
                  variant: TilawaButtonVariant.secondary,
                  size: TilawaButtonSize.small,
                  onPressed: onReview,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
