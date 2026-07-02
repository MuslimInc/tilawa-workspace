import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_analytics.dart';
import 'package:tilawa/features/quran_sessions/presentation/teacher_application_entry.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'settings_teacher_capability_scope.dart';
import 'settings_widgets.dart';

bool _suppressTeachingSectionForGoogleFormApply({
  required QuranSessionsFeatureConfig config,
  required TeacherCapability? capability,
  required bool isLoading,
}) {
  if (!config.showTeacherApplicationEntry ||
      config.showInAppTeacherApplicationEntry) {
    return false;
  }
  if (isLoading) {
    return true;
  }
  return capability?.navigationTarget ==
      TeacherCapabilityNavigationTarget.apply;
}

/// Self-contained Settings block for teacher capability — no section header.
///
/// Premium approved states render a standalone [TilawaCapabilityActionCard].
/// Other states keep a single-row [TilawaSettingsGroupPanel] without a title.
class SettingsTeachingOnMemuslimSection extends StatelessWidget {
  const SettingsTeachingOnMemuslimSection({super.key});

  @override
  Widget build(BuildContext context) {
    final config = quranSessionsFeatureConfig();
    if (!config.quranSessionsEnabled) {
      return const SizedBox.shrink();
    }

    if (!SettingsTeacherCapabilityScope.shouldShowTeachingSectionOf(context)) {
      if (SettingsTeacherCapabilityScope.isTeachingSectionLoadingOf(context)) {
        return const SizedBox.shrink();
      }
      return const SizedBox.shrink();
    }

    final isLoading = SettingsTeacherCapabilityScope.isTeachingSectionLoadingOf(
      context,
    );
    if (isLoading) {
      if (_suppressTeachingSectionForGoogleFormApply(
        config: config,
        capability: null,
        isLoading: true,
      )) {
        return const SizedBox.shrink();
      }
      final tokens = Theme.of(context).tokens;
      return Padding(
        padding: EdgeInsetsDirectional.only(
          top: tokens.spaceMedium,
          bottom: tokens.spaceLarge,
        ),
        child: const TilawaSettingsGroupHorizontalInset(
          child: TilawaCapabilityActionCardSkeleton(
            margin: EdgeInsets.zero,
            useGradient: false,
          ),
        ),
      );
    }

    final capability = SettingsTeacherCapabilityScope.maybeCapabilityOf(
      context,
    );
    if (capability == null) {
      return const SizedBox.shrink();
    }

    if (_suppressTeachingSectionForGoogleFormApply(
      config: config,
      capability: capability,
      isLoading: false,
    )) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).tokens;
    final tile = SettingsTeachingOnMemuslimTile(
      showDivider: false,
      standaloneLayout: true,
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: tokens.spaceMedium,
        bottom: tokens.spaceLarge,
      ),
      child: TilawaSettingsGroupHorizontalInset(
        child: capability.showsPremiumSettingsCapabilityCard
            ? tile
            : TilawaSettingsGroupPanel(children: [tile]),
      ),
    );
  }
}

/// Canonical Profile / Settings entry for teacher onboarding (Option D).
class SettingsTeachingOnMemuslimTile extends StatelessWidget {
  const SettingsTeachingOnMemuslimTile({
    super.key,
    this.showDivider = true,
    this.standaloneLayout = false,
  });

  final bool showDivider;

  /// When true, the premium card drops inner group margins so the section
  /// inset controls horizontal alignment.
  final bool standaloneLayout;

  @override
  Widget build(BuildContext context) {
    final config = quranSessionsFeatureConfig();
    if (!config.quranSessionsEnabled) {
      return const SizedBox.shrink();
    }

    if (!SettingsTeacherCapabilityScope.shouldShowTeachingSectionOf(context)) {
      return const SizedBox.shrink();
    }

    final isLoading = SettingsTeacherCapabilityScope.isTeachingSectionLoadingOf(
      context,
    );
    if (isLoading) {
      if (_suppressTeachingSectionForGoogleFormApply(
        config: config,
        capability: null,
        isLoading: true,
      )) {
        return const SizedBox.shrink();
      }
      return TilawaCapabilityActionCardSkeleton(
        margin: standaloneLayout ? EdgeInsets.zero : null,
        useGradient: false,
      );
    }

    final capability = SettingsTeacherCapabilityScope.maybeCapabilityOf(
      context,
    );
    if (capability == null) {
      return const SizedBox.shrink();
    }

    if (_suppressTeachingSectionForGoogleFormApply(
      config: config,
      capability: capability,
      isLoading: false,
    )) {
      return const SizedBox.shrink();
    }

    final l10n = context.quranSessionsL10n;
    final analytics = quranSessionsAnalyticsCallbacks();
    final badgeLabel = capability.statusBadgeLabel(l10n);
    final title = capability.teachingSectionActionTitle(l10n);
    final subtitle = capability.teachingSectionSubtitle(l10n);

    if (capability.showsPremiumSettingsCapabilityCard) {
      return TilawaCapabilityActionCard(
        title: title,
        subtitle: subtitle ?? '',
        leadingIcon: TilawaIcons.teacherCapability,
        badgeLabel: badgeLabel,
        useGradient: false,
        onTap: () => _onTap(context, capability, analytics),
        semanticLabel: subtitle == null ? title : '$title. $subtitle',
        margin: standaloneLayout ? EdgeInsets.zero : null,
      );
    }

    return TilawaSettingsTile(
      title: title,
      trailing: _TeachingSectionTrailing(
        badgeLabel: badgeLabel,
        actionTitle: title,
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

    final config = quranSessionsFeatureConfig();
    if (capability.navigationTarget ==
            TeacherCapabilityNavigationTarget.apply &&
        !config.showInAppTeacherApplicationEntry &&
        config.showTeacherApplicationEntry) {
      showTeacherApplicationEntrySheet(context);
      return;
    }

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
          TilawaIcons.chevronRightSmall,
          size: groupTokens.tileTrailingSize,
          color: theme.colorScheme.onSurfaceVariant.withValues(
            alpha: (groupTokens.tileTrailingOpacity * 1.35).clamp(0.45, 0.72),
          ),
        ),
      ],
    );
  }
}
