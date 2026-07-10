import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Caps long tutor session lists on [TeacherDashboardScreen] with expand/collapse.
///
/// Keeps bookable availability reachable without scrolling through every card.
/// Expansion state is owned by the parent screen so it survives sliver rebuilds.
class TeacherDashboardCollapsibleSessionList extends StatelessWidget {
  const TeacherDashboardCollapsibleSessionList({
    super.key,
    required this.sectionKey,
    required this.itemCount,
    required this.itemBuilder,
    required this.expanded,
    required this.onToggleExpanded,
    this.previewCount = defaultPreviewCount,
  });

  static const defaultPreviewCount = 3;

  final String sectionKey;

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final canExpand = itemCount > previewCount;
    final visibleCount = expanded || !canExpand ? itemCount : previewCount;

    return SliverMainAxisGroup(
      slivers: [
        SliverList.builder(
          itemCount: visibleCount,
          itemBuilder: itemBuilder,
        ),
        if (canExpand)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spaceLarge,
                end: tokens.spaceLarge,
                bottom: tokens.spaceSmall,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: ValueKey(
                    expanded
                        ? 'teacher-dashboard-$sectionKey-sessions-collapse'
                        : 'teacher-dashboard-$sectionKey-sessions-expand',
                  ),
                  onPressed: onToggleExpanded,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceExtraSmall,
                      vertical: tokens.spaceExtraSmall,
                    ),
                    minimumSize: Size(
                      tokens.minInteractiveDimension,
                      tokens.minInteractiveDimension,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    expanded
                        ? l10n.teacherDashboardShowLessSessions
                        : l10n.teacherDashboardShowAllSessions(itemCount),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
