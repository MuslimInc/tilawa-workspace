import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../config/quran_sessions_feature_config.dart';

/// Student-first empty state for Learn Quran when no teachers are available.
class QuranSessionsStudentEmptyState extends StatefulWidget {
  const QuranSessionsStudentEmptyState({
    super.key,
    required this.featureConfig,
    this.showTeacherApplyEntry = false,
    this.onNotifyInterest,
    this.onChangeCity,
    this.onTeacherApplyEntry,
    this.onEmptyStateSeen,
  });

  final QuranSessionsFeatureConfig featureConfig;
  final bool showTeacherApplyEntry;
  final VoidCallback? onNotifyInterest;
  final VoidCallback? onChangeCity;
  final VoidCallback? onTeacherApplyEntry;
  final VoidCallback? onEmptyStateSeen;

  @override
  State<QuranSessionsStudentEmptyState> createState() =>
      _QuranSessionsStudentEmptyStateState();
}

class _QuranSessionsStudentEmptyStateState
    extends State<QuranSessionsStudentEmptyState> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onEmptyStateSeen?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final Widget primaryAction = TilawaButton(
      text: l10n.sessionsEmptyNotifyMe,
      onPressed: widget.onNotifyInterest,
      isFullWidth: true,
    );

    final Widget? secondaryAction = widget.onChangeCity != null
        ? TilawaButton(
            text: l10n.sessionsEmptyChangeCity,
            variant: TilawaButtonVariant.outline,
            onPressed: widget.onChangeCity,
            isFullWidth: true,
          )
        : null;

    final bool showTeacherLink =
        widget.showTeacherApplyEntry &&
        widget.featureConfig.showEmptyStateTeacherEntry &&
        widget.onTeacherApplyEntry != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TilawaIllustratedState(
          icon: Icons.person_search_outlined,
          title: l10n.sessionsEmptyTitle,
          subtitle: l10n.sessionsEmptySubtitle,
          semanticLabel: l10n.sessionsEmptyTitle,
          primaryAction: primaryAction,
          secondaryAction: secondaryAction,
        ),
        if (showTeacherLink)
          Padding(
            padding: EdgeInsets.only(top: tokens.spaceMedium),
            child: _TeacherApplyLink(
              question: l10n.sessionsEmptyInterestedTeaching,
              action: l10n.sessionsEmptyJoinAsTeacher,
              onTap: widget.onTeacherApplyEntry!,
            ),
          ),
      ],
    );
  }
}

class _TeacherApplyLink extends StatelessWidget {
  const _TeacherApplyLink({
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return TilawaInteractiveSurface(
      onTap: onTap,
      semanticLabel: '$question $action',
      borderRadius: BorderRadius.circular(tokens.radiusSmall),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceExtraSmall,
        ),
        child: Column(
          children: [
            Text(
              question,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceExtraSmall),
            Text(
              action,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
