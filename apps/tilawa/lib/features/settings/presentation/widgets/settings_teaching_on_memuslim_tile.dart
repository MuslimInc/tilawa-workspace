import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_analytics.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'settings_teacher_capability_scope.dart';
import 'settings_widgets.dart';

/// Canonical Profile / Settings entry for teacher onboarding (Option D).
class SettingsTeachingOnMemuslimTile extends StatelessWidget {
  const SettingsTeachingOnMemuslimTile({super.key, this.showDivider = true});

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final config = quranSessionsFeatureConfig();
    if (!config.showProfileTeacherEntry ||
        SettingsTeacherCapabilityScope.isLoadingOf(context)) {
      return const SizedBox.shrink();
    }

    final capability = SettingsTeacherCapabilityScope.maybeOf(context);
    if (capability == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.quranSessionsL10n;
    final analytics = quranSessionsAnalyticsCallbacks();
    final badgeLabel = capability.statusBadgeLabel(l10n);

    return TilawaSettingsTile(
      title: capability.teachingSectionActionTitle(l10n),
      subtitle: capability.teachingSectionSubtitle(l10n),
      trailing: _TeachingSectionTrailing(
        badgeLabel: badgeLabel,
        actionTitle: capability.teachingSectionActionTitle(l10n),
      ),
      onTap: () => _onTap(context, capability, analytics),
      showDivider: showDivider,
    );
  }

  void _onTap(
    BuildContext context,
    TeacherCapability capability,
    QuranSessionsAnalyticsCallbacks analytics,
  ) {
    analytics.onTeacherApplyEntrySeen?.call();

    switch (capability.navigationTarget) {
      case TeacherCapabilityNavigationTarget.apply:
        analytics.onTeacherApplyStarted?.call();
        context.push(QuranSessionsRoutes.teacherApply);
      case TeacherCapabilityNavigationTarget.applicationStatus:
        analytics.onTeacherApplicationStatusViewed?.call();
        context.push(QuranSessionsRoutes.teacherApplicationStatus);
      case TeacherCapabilityNavigationTarget.completeTeacherProfile:
        context.push(QuranSessionsRoutes.completeTeacherProfile);
      case TeacherCapabilityNavigationTarget.teacherDashboard:
        analytics.onTeacherDashboardOpened?.call();
        context.push(QuranSessionsRoutes.teacherDashboard);
    }
  }
}

class _TeachingSectionTrailing extends StatelessWidget {
  const _TeachingSectionTrailing({
    required this.badgeLabel,
    required this.actionTitle,
  });

  final String? badgeLabel;
  final String actionTitle;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    if (badgeLabel == null) {
      return settingsPickerTrailing(context, value: actionTitle);
    }

    final theme = Theme.of(context);
    final groupTokens = theme.componentTokens.settingsGroup;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: TilawaStatusChip(label: badgeLabel!),
        ),
        SizedBox(width: tokens.spaceSmall),
        Icon(
          FluentIcons.chevron_right_20_regular,
          size: groupTokens.tileTrailingSize,
          color: theme.colorScheme.onSurfaceVariant.withValues(
            alpha: (groupTokens.tileTrailingOpacity * 1.35).clamp(0.45, 0.72),
          ),
        ),
      ],
    );
  }
}
