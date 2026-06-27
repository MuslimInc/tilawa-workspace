import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../theme/quran_sessions_status_colors.dart';

/// Compact upcoming/past counts and next session hint for My Sessions.
class QuranSessionSummaryStrip extends StatelessWidget {
  const QuranSessionSummaryStrip({
    super.key,
    required this.upcomingCount,
    required this.pastCount,
    this.nextUpcoming,
  });

  final int upcomingCount;
  final int pastCount;
  final QuranSession? nextUpcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.quranSessionsStatus;
    final tokens = theme.tokens;

    final nextLabel = nextUpcoming == null
        ? null
        : l10n.sessionsSummaryNextSession(
            _formatNextSession(context, nextUpcoming!.startsAt),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceMedium,
        tokens.spaceSmall,
        tokens.spaceMedium,
        tokens.spaceSmall,
      ),
      child: TilawaCard(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: tokens.spaceSmall,
              runSpacing: tokens.spaceExtraSmall,
              children: [
                _SummaryPill(
                  label: l10n.sessionsSummaryUpcoming(upcomingCount),
                  background: status.scheduledBackground,
                  foreground: status.scheduledForeground,
                ),
                _SummaryPill(
                  label: l10n.sessionsSummaryPast(pastCount),
                  background: scheme.primaryContainer,
                  foreground: scheme.onSurfaceVariant,
                ),
              ],
            ),
            if (nextLabel != null) ...[
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                nextLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNextSession(BuildContext context, DateTime startsAt) {
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('EEEE h:mm a', locale);
    return fmt.format(startsAt.toLocal());
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TilawaChip(
      label: label,
      backgroundColor: background,
      foregroundColor: foreground,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      textStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );
  }
}
