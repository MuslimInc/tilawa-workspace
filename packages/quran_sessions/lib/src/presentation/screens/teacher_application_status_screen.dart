import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_application.dart';
import '../blocs/teacher_application/teacher_application_bloc.dart';
import '../blocs/teacher_application/teacher_application_event.dart';
import '../blocs/teacher_application/teacher_application_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/quran_sessions_scaffold.dart';

/// Displays the current status of a teacher's application.
///
/// Covers: pending, approved, rejected, suspended, revoked.
///
/// [onApproved] is called when the application status reaches `approved`
/// (either via real backend or debug simulation) — the host app navigates
/// to the teacher dashboard.
class TeacherApplicationStatusScreen extends StatefulWidget {
  const TeacherApplicationStatusScreen({
    super.key,
    required this.userId,
    required this.onApproved,
  });

  final String userId;
  final VoidCallback onApproved;

  @override
  State<TeacherApplicationStatusScreen> createState() =>
      _TeacherApplicationStatusScreenState();
}

class _TeacherApplicationStatusScreenState
    extends State<TeacherApplicationStatusScreen> {
  TeacherApplicationState? _previousBlocState;
  var _approvedNavigationHandled = false;

  @override
  void initState() {
    super.initState();
    context.read<TeacherApplicationBloc>().add(
      TeacherApplicationLoadRequested(userId: widget.userId),
    );
  }

  bool _shouldNavigateOnApproval(
    TeacherApplicationState state,
    TeacherApplicationState? previous,
  ) {
    if (_approvedNavigationHandled) return false;
    if (state is! TeacherApplicationStatusLoaded ||
        !state.application.isApproved) {
      return false;
    }

    // Only navigate when approval happens during this visit (pending → approved
    // or debug simulate), not when reopening an already-approved application.
    final transitionedFromPending =
        previous is TeacherApplicationStatusLoaded &&
        previous.application.isPending;
    final finishedDebugSimulation =
        previous is TeacherApplicationStatusLoaded &&
        previous.isSimulatingApproval;

    return transitionedFromPending || finishedDebugSimulation;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return QuranSessionsScaffold(
      title: l10n.applicationStatusTitle,
      body: MultiBlocListener(
        listeners: [
          BlocListener<TeacherApplicationBloc, TeacherApplicationState>(
            listenWhen: (_, current) =>
                current is TeacherApplicationFailureState,
            listener: (context, state) {
              if (state is! TeacherApplicationFailureState) return;
              TilawaFeedback.showToast(
                context,
                message: state.failure.toLocalizedMessage(context),
                variant: TilawaFeedbackVariant.error,
              );
              context.read<TeacherApplicationBloc>()
              // ignore: invalid_use_of_visible_for_testing_member
              .emit(state.previousState);
            },
          ),
        ],
        child: BlocConsumer<TeacherApplicationBloc, TeacherApplicationState>(
          listenWhen: (previous, current) =>
              _shouldNavigateOnApproval(current, previous),
          listener: (context, state) {
            if (!_shouldNavigateOnApproval(state, _previousBlocState)) {
              return;
            }
            _approvedNavigationHandled = true;
            widget.onApproved();
          },
          builder: (context, state) {
            _previousBlocState = state;
            return switch (state) {
              TeacherApplicationInitial() ||
              TeacherApplicationLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              TeacherApplicationStatusLoaded(
                :final application,
                :final isSimulatingApproval,
              ) =>
                _StatusBody(
                  application: application,
                  isSimulatingApproval: isSimulatingApproval,
                  onApprovedContinue: widget.onApproved,
                ),
              _ => Center(child: Text(l10n.unknownStatus)),
            };
          },
        ),
      ),
    );
  }
}

// ── Status body ───────────────────────────────────────────────────────────────

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.application,
    required this.isSimulatingApproval,
    required this.onApprovedContinue,
  });

  final TeacherApplication application;
  final bool isSimulatingApproval;
  final VoidCallback onApprovedContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceExtraLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(status: application.status),
          SizedBox(height: tokens.spaceExtraLarge),
          _MetaSection(application: application),
          if (application.isApproved) ...[
            SizedBox(height: tokens.spaceExtraLarge),
            TilawaButton(
              text: l10n.applicationStatusApprovedContinue,
              isFullWidth: true,
              size: TilawaButtonSize.large,
              onPressed: onApprovedContinue,
            ),
          ],

          // ── DEBUG: Simulate Approval ─────────────────────────────────────
          // This block is completely absent in release builds.
          if (kDebugMode && application.isPending) ...[
            SizedBox(height: tokens.spaceXXL),
            const Divider(),
            SizedBox(height: tokens.spaceSmall),
            _DebugApprovalBanner(
              application: application,
              isLoading: isSimulatingApproval,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final TeacherApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final l10n = context.quranSessionsL10n;
    final (icon, color, title, subtitle) = _content(status, scheme, l10n);

    return Container(
      padding: EdgeInsets.all(tokens.spaceExtraLarge),
      decoration: BoxDecoration(
        color: color.withValues(alpha: tokens.opacitySubtle),
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(
          color: color.withValues(alpha: tokens.opacityShadowStrong),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: tokens.iconSizeLargePlus, color: color),
          SizedBox(height: tokens.spaceLarge),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String) _content(
    TeacherApplicationStatus status,
    ColorScheme scheme,
    QuranSessionsLocalizations l10n,
  ) => switch (status) {
    TeacherApplicationStatus.pending => (
      Icons.hourglass_top_rounded,
      scheme.primary,
      l10n.applicationStatusPendingTitle,
      l10n.applicationStatusPendingSubtitle,
    ),
    TeacherApplicationStatus.approved => (
      Icons.verified_rounded,
      scheme.tertiary,
      l10n.applicationStatusApprovedTitle,
      l10n.applicationStatusApprovedSubtitle,
    ),
    TeacherApplicationStatus.rejected => (
      Icons.cancel_outlined,
      scheme.error,
      l10n.applicationStatusRejectedTitle,
      l10n.applicationStatusRejectedSubtitle,
    ),
    TeacherApplicationStatus.suspended => (
      Icons.pause_circle_outline,
      scheme.secondary,
      l10n.applicationStatusSuspendedTitle,
      l10n.applicationStatusSuspendedSubtitle,
    ),
    TeacherApplicationStatus.revoked => (
      Icons.block,
      scheme.error,
      l10n.applicationStatusRevokedTitle,
      l10n.applicationStatusRevokedSubtitle,
    ),
    _ => (
      Icons.help_outline,
      scheme.onSurfaceVariant,
      l10n.unknownStatus,
      '',
    ),
  };
}

// ── Meta section ──────────────────────────────────────────────────────────────

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.application});

  final TeacherApplication application;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('d MMMM y، h:mm a', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (application.submittedAt != null)
          _MetaRow(
            label: l10n.submittedAtLabel,
            value: dateFmt.format(application.submittedAt!),
          ),
        if (application.reviewedAt != null)
          _MetaRow(
            label: l10n.reviewedAtLabel,
            value: dateFmt.format(application.reviewedAt!),
          ),
        if (application.rejectionReason != null)
          _MetaRow(
            label: l10n.reasonLabel,
            value: application.rejectionReason!,
          ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.labelWithColon(label),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ── Debug approval banner ─────────────────────────────────────────────────────

/// Visible only when [kDebugMode] is true and the application is pending.
///
/// This banner must never appear in production — it is guarded by [kDebugMode]
/// which is evaluated at compile time and tree-shaken in release builds.
class _DebugApprovalBanner extends StatelessWidget {
  const _DebugApprovalBanner({
    required this.application,
    required this.isLoading,
  });

  final TeacherApplication application;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.debugModeTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.debugApprovalDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            TilawaButton(
              // icon: Icons.check_circle_outline,
              text: l10n.simulateAdminApproval,
              onPressed: () => context.read<TeacherApplicationBloc>().add(
                TeacherApplicationDebugSimulateApproval(
                  applicationId: application.id,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
