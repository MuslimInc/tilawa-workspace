import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_analytics.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'settings_widgets.dart';

/// Canonical Profile / Settings entry for teacher onboarding (Option D).
class SettingsTeachingOnMemuslimTile extends StatefulWidget {
  const SettingsTeachingOnMemuslimTile({super.key, this.showDivider = true});

  final bool showDivider;

  @override
  State<SettingsTeachingOnMemuslimTile> createState() =>
      _SettingsTeachingOnMemuslimTileState();
}

class _SettingsTeachingOnMemuslimTileState
    extends State<SettingsTeachingOnMemuslimTile> {
  TeacherApplicationStatus _status = TeacherApplicationStatus.none;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final config = quranSessionsFeatureConfig();
    if (!config.showProfileTeacherEntry) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    final userId = quranSessionsCurrentUserId(getIt);
    if (userId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    final result = await getIt<GetTeacherApplicationStatusUseCase>()(userId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _status = result.fold(
        (_) => TeacherApplicationStatus.none,
        (application) => application.status,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = quranSessionsFeatureConfig();
    if (!config.showProfileTeacherEntry || _loading) {
      return const SizedBox.shrink();
    }

    final l10n = context.quranSessionsL10n;
    final analytics = quranSessionsAnalyticsCallbacks();

    final ({String title, String? subtitle}) copy = switch (_status) {
      TeacherApplicationStatus.none => (
        title: l10n.teachingOnMemuslimApply,
        subtitle: null,
      ),
      TeacherApplicationStatus.draft => (
        title: l10n.teachingOnMemuslimContinue,
        subtitle: null,
      ),
      TeacherApplicationStatus.pending => (
        title: l10n.teachingOnMemuslimViewStatus,
        subtitle: l10n.teachingOnMemuslimPendingSubtitle,
      ),
      TeacherApplicationStatus.approved => (
        title: l10n.teachingOnMemuslimOpenDashboard,
        subtitle: l10n.teachingOnMemuslimApprovedSubtitle,
      ),
      TeacherApplicationStatus.rejected => (
        title: l10n.teachingOnMemuslimViewStatus,
        subtitle: l10n.teachingOnMemuslimRejectedSubtitle,
      ),
      TeacherApplicationStatus.suspended => (
        title: l10n.teachingOnMemuslimViewStatus,
        subtitle: l10n.teachingOnMemuslimSuspendedSubtitle,
      ),
      TeacherApplicationStatus.revoked => (
        title: l10n.teachingOnMemuslimViewStatus,
        subtitle: l10n.teachingOnMemuslimRevokedSubtitle,
      ),
    };

    return TilawaSettingsTile(
      title: copy.title,
      subtitle: copy.subtitle,
      trailing: settingsPickerTrailing(context, value: copy.title),
      onTap: () => _onTap(analytics),
      showDivider: widget.showDivider,
    );
  }

  void _onTap(QuranSessionsAnalyticsCallbacks analytics) {
    analytics.onTeacherApplyEntrySeen?.call();

    switch (_status) {
      case TeacherApplicationStatus.none:
      case TeacherApplicationStatus.draft:
      case TeacherApplicationStatus.rejected:
        analytics.onTeacherApplyStarted?.call();
        context.push(QuranSessionsRoutes.teacherApply);
      case TeacherApplicationStatus.pending:
      case TeacherApplicationStatus.suspended:
      case TeacherApplicationStatus.revoked:
        analytics.onTeacherApplicationStatusViewed?.call();
        context.push(QuranSessionsRoutes.teacherApplicationStatus);
      case TeacherApplicationStatus.approved:
        analytics.onTeacherDashboardOpened?.call();
        context.push(QuranSessionsRoutes.teacherDashboard);
    }
  }
}
