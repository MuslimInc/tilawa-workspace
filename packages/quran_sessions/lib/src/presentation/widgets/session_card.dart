import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/quran_session.dart';

/// Card showing session time, teacher name, and status badge.
/// Used in [MySessionsScreen] and [TeacherDashboardScreen].
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.teacherName,
    this.onTap,
    this.onJoin,
    this.onCancel,
  });

  final QuranSession session;

  /// Optional resolved teacher name (fetched by host from store).
  final String? teacherName;

  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('EEEE، d MMMM y', locale);
    final timeFmt = DateFormat('h:mm a', locale);
    final localStart = session.startsAt.toLocal();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (teacherName != null)
                          Text(
                            teacherName!,
                            style: textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          dateFmt.format(localStart),
                          style: textTheme.bodyMedium,
                        ),
                        Text(
                          timeFmt.format(localStart),
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    status: session.status,
                    scheme: scheme,
                    l10n: l10n,
                  ),
                ],
              ),
              if (onJoin != null || onCancel != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                        ),
                        onPressed: onCancel,
                        child: Text(l10n.cancel),
                      ),
                    if (onJoin != null) ...[
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: onJoin,
                        child: Text(l10n.joinSession),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.scheme,
    required this.l10n,
  });

  final QuranSessionStatus status;
  final ColorScheme scheme;
  final QuranSessionsLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      QuranSessionStatus.scheduled => (
        l10n.sessionStatusScheduled,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      QuranSessionStatus.inProgress => (
        l10n.sessionStatusInProgress,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      QuranSessionStatus.completed => (
        l10n.sessionStatusCompleted,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      QuranSessionStatus.cancelledByStudent ||
      QuranSessionStatus.cancelledByTeacher => (
        l10n.sessionStatusCancelled,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      QuranSessionStatus.noShow => (
        l10n.sessionStatusNoShow,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };

    final tokens = Theme.of(context).tokens;
    final badgeRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.chip,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(badgeRadius),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
