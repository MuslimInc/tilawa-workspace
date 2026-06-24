import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Banner for pending reschedule — counterparty actions or requester wait state.
class PendingRescheduleBanner extends StatelessWidget {
  const PendingRescheduleBanner({
    super.key,
    required this.request,
    required this.canRespond,
    required this.isAwaitingCounterparty,
    required this.respondInProgress,
    required this.onAccept,
    required this.onReject,
  });

  final PendingRescheduleRequest request;
  final bool canRespond;
  final bool isAwaitingCounterparty;
  final bool respondInProgress;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    if (!canRespond && !isAwaitingCounterparty) {
      return const SizedBox.shrink();
    }

    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final localStart = request.newStartsAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final proposedDateTime =
        '${material.formatFullDate(localStart)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(localStart))}';

    return TilawaCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: [
            Text(
              l10n.reschedulePendingTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.primary,
              ),
            ),
            Text(l10n.reschedulePendingProposedTime(proposedDateTime)),
            if (request.reason.trim().isNotEmpty)
              Text(l10n.reschedulePendingReason(request.reason.trim())),
            if (isAwaitingCounterparty)
              Text(
                l10n.rescheduleAwaitingCounterparty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (canRespond) ...[
              TilawaButton(
                text: l10n.rescheduleAcceptAction,
                isFullWidth: true,
                isLoading: respondInProgress,
                onPressed: respondInProgress ? null : onAccept,
              ),
              TilawaButton(
                text: l10n.rescheduleRejectAction,
                variant: TilawaButtonVariant.outline,
                isFullWidth: true,
                isLoading: respondInProgress,
                onPressed: respondInProgress ? null : onReject,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
