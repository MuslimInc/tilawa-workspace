import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Glance metrics row for [TeacherDashboardScreen].
///
/// Rendered as a read-only [TilawaMetricTileStrip] — a flat summary strip,
/// visually distinct from the raised, tappable category/action cards below.
/// Counts are pre-computed from [TeacherDashboardSuccess] in the screen.
///
/// Pending requests carry the single primary ([TilawaSemanticTint.ink])
/// emphasis lane because they are the only metric that demands teacher
/// action; the other tiles stay on supporting manuscript tints. The
/// *action* itself still lives in the category section — the stat tile keeps
/// no tap affordance.
class TeacherDashboardSummaryStats extends StatelessWidget {
  const TeacherDashboardSummaryStats({
    super.key,
    required this.pendingRequestsCount,
    required this.upcomingSessionsCount,
    required this.bookableSlotsCount,
    required this.pendingRequestsLabel,
    required this.upcomingSessionsLabel,
    required this.bookableSlotsLabel,
  });

  final int pendingRequestsCount;
  final int upcomingSessionsCount;
  final int bookableSlotsCount;
  final String pendingRequestsLabel;
  final String upcomingSessionsLabel;
  final String bookableSlotsLabel;

  @override
  Widget build(BuildContext context) {
    return TilawaMetricTileStrip(
      metrics: [
        TilawaMetricData(
          value: '$pendingRequestsCount',
          label: pendingRequestsLabel,
          icon: Icons.inbox_outlined,
          tint: TilawaSemanticTint.ink,
        ),
        TilawaMetricData(
          value: '$upcomingSessionsCount',
          label: upcomingSessionsLabel,
          icon: Icons.event_outlined,
          tint: TilawaSemanticTint.scholar,
        ),
        TilawaMetricData(
          value: '$bookableSlotsCount',
          label: bookableSlotsLabel,
          icon: Icons.schedule_outlined,
          tint: TilawaSemanticTint.neutral,
        ),
      ],
    );
  }
}
