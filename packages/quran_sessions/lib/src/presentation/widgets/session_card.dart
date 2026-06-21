import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/quran_session.dart';

/// Card showing session time, teacher name, and status badge.
/// Used in [MySessionsScreen] and [TeacherDashboardScreen].
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.teacherName,
    this.onJoin,
    this.onCancel,
  });

  final QuranSession session;

  /// Optional resolved teacher name (fetched by host from store).
  final String? teacherName;

  final VoidCallback? onJoin;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFmt = DateFormat('EEEE، d MMMM y', 'ar');
    final timeFmt = DateFormat('h:mm a', 'ar');
    final localStart = session.startsAt.toLocal();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                _StatusBadge(status: session.status, scheme: scheme),
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
                      child: const Text('إلغاء'),
                    ),
                  if (onJoin != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: onJoin,
                      child: const Text('انضمام'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.scheme});

  final QuranSessionStatus status;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      QuranSessionStatus.scheduled => (
        'مجدول',
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      QuranSessionStatus.inProgress => (
        'جارٍ الآن',
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      QuranSessionStatus.completed => (
        'مكتمل',
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      QuranSessionStatus.cancelledByStudent ||
      QuranSessionStatus.cancelledByTeacher => (
        'ملغى',
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      QuranSessionStatus.noShow => (
        'غائب',
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
