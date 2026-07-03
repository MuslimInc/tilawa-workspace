import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact schedule-editing action for the bookable-times section header.
///
/// Rendered as [TutorDashboardSection.trailing] so "view slots" and "edit
/// template" read as one zone — the weekly template generates these slots.
class TeacherDashboardScheduleSection extends StatelessWidget {
  const TeacherDashboardScheduleSection({
    super.key,
    required this.actionLabel,
    required this.onManageSchedule,
  });

  final String actionLabel;
  final VoidCallback onManageSchedule;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return TilawaButton(
      text: actionLabel,
      variant: TilawaButtonVariant.ghost,
      size: TilawaButtonSize.small,
      leadingIcon: Icon(
        Icons.edit_calendar_outlined,
        size: tokens.iconSizeSmall,
      ),
      onPressed: onManageSchedule,
    );
  }
}
