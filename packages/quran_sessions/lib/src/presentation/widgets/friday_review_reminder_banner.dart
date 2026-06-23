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
      child: Material(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
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
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(l10n.fridayReviewBannerDismiss),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: onReview,
                    child: Text(l10n.fridayReviewBannerAction),
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
