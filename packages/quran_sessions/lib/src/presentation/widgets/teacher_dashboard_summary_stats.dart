import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Glance metrics row for [TeacherDashboardScreen].
///
/// Counts are pre-computed from [TeacherDashboardSuccess] in the screen.
/// Pending requests carry the single primary (ink) emphasis lane because they
/// are the only metric that demands teacher action; the other tiles stay on
/// supporting manuscript tints.
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
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spaceLarge,
        tokens.spaceMedium,
        tokens.spaceLarge,
        tokens.spaceSmall,
      ),
      // IntrinsicHeight keeps the three tiles equal-height while the sliver
      // parent provides unbounded height (stretch alone would blow up).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: [
            Expanded(
              child: _SummaryStatTile(
                value: pendingRequestsCount,
                label: pendingRequestsLabel,
                icon: Icons.inbox_outlined,
                tint: TilawaSemanticTint.ink,
              ),
            ),
            Expanded(
              child: _SummaryStatTile(
                value: upcomingSessionsCount,
                label: upcomingSessionsLabel,
                icon: Icons.event_outlined,
                tint: TilawaSemanticTint.scholar,
              ),
            ),
            Expanded(
              child: _SummaryStatTile(
                value: bookableSlotsCount,
                label: bookableSlotsLabel,
                icon: Icons.schedule_outlined,
                tint: TilawaSemanticTint.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
  });

  final int value;
  final String label;
  final IconData icon;
  final TilawaSemanticTint tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return TilawaCard(
      padding: EdgeInsets.all(tokens.spaceSmall + tokens.spaceExtraSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TilawaIconBox(
            icon: icon,
            variant: TilawaIconBoxVariant.tinted,
            semanticTint: tint,
            size: tokens.iconSizeSmall,
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.1,
            ),
          ),
          SizedBox(height: tokens.spaceTiny),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}
