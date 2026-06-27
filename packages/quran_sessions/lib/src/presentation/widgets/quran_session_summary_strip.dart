import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';
import '../theme/quran_sessions_theme.dart';
import 'quran_sessions_surface_card.dart';

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
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;

    final nextLabel = nextUpcoming == null
        ? null
        : l10n.sessionsSummaryNextSession(
            _formatNextSession(context, nextUpcoming!.startsAt),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        feature.screenPaddingHorizontal,
        feature.sectionGap,
        feature.screenPaddingHorizontal,
        feature.sectionGap,
      ),
      child: QuranSessionsSurfaceCard(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: feature.cardPadding,
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
                  background: feature.statusScheduledBackground,
                  foreground: feature.statusScheduledForeground,
                ),
                _SummaryPill(
                  label: l10n.sessionsSummaryPast(pastCount),
                  background: feature.accentSoftBackground,
                  foreground: feature.helperTextColor,
                ),
              ],
            ),
            if (nextLabel != null) ...[
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                nextLabel,
                style: feature.cardMetaStyle,
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
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: feature.listItemGap,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(feature.chipRadius),
      ),
      child: Text(
        label,
        style: feature.chipLabelStyle.copyWith(color: foreground),
      ),
    );
  }
}
