import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_application.dart';
import '../blocs/teacher_application/teacher_application_bloc.dart';
import '../blocs/teacher_application/teacher_application_event.dart';
import '../blocs/teacher_application/teacher_application_state.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';

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
  @override
  void initState() {
    super.initState();
    context.read<TeacherApplicationBloc>().add(
      TeacherApplicationLoadRequested(userId: widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حالة طلب التسجيل')),
      body: BlocConsumer<TeacherApplicationBloc, TeacherApplicationState>(
        listener: (context, state) {
          if (state is TeacherApplicationStatusLoaded &&
              state.application.isApproved) {
            widget.onApproved();
          }
          if (state is TeacherApplicationFailureState) {
            TilawaFeedback.showToast(
              context,
              message: state.failure.toLocalizedMessage(context),
              variant: TilawaFeedbackVariant.error,
            );
            context.read<TeacherApplicationBloc>()
            // ignore: invalid_use_of_visible_for_testing_member
            .emit(state.previousState);
          }
        },
        builder: (context, state) => switch (state) {
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
            ),
          _ => const Center(child: Text('حالة غير معروفة')),
        },
      ),
    );
  }
}

// ── Status body ───────────────────────────────────────────────────────────────

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.application,
    required this.isSimulatingApproval,
  });

  final TeacherApplication application;
  final bool isSimulatingApproval;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(status: application.status),
          const SizedBox(height: 24),
          _MetaSection(application: application),

          // ── DEBUG: Simulate Approval ─────────────────────────────────────
          // This block is completely absent in release builds.
          if (kDebugMode && application.isPending) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
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
    final (icon, color, title, subtitle) = _content(status, scheme);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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
  ) => switch (status) {
    TeacherApplicationStatus.pending => (
      Icons.hourglass_top_rounded,
      scheme.primary,
      'طلبك قيد المراجعة',
      'يقوم فريق تلاوة بمراجعة طلبك. سنتواصل معك قريبًا.',
    ),
    TeacherApplicationStatus.approved => (
      Icons.verified_rounded,
      Colors.green,
      'تهانينا! تمت الموافقة',
      'أصبحت محفظًا معتمدًا على منصة تلاوة.',
    ),
    TeacherApplicationStatus.rejected => (
      Icons.cancel_outlined,
      scheme.error,
      'لم تتم الموافقة على الطلب',
      'يمكنك إعادة التقديم بعد مراجعة ملاحظات الفريق.',
    ),
    TeacherApplicationStatus.suspended => (
      Icons.pause_circle_outline,
      Colors.orange,
      'الحساب موقوف مؤقتًا',
      'تواصل مع الدعم للاستفسار عن سبب التوقف.',
    ),
    TeacherApplicationStatus.revoked => (
      Icons.block,
      scheme.error,
      'تم إلغاء الحساب',
      'لا يمكنك التقديم مجددًا. تواصل مع الدعم للمزيد.',
    ),
    _ => (
      Icons.help_outline,
      scheme.onSurfaceVariant,
      'حالة غير معروفة',
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
    final dateFmt = DateFormat('d MMMM y، h:mm a', 'ar');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (application.submittedAt != null)
          _MetaRow(
            label: 'تاريخ الإرسال',
            value: dateFmt.format(application.submittedAt!),
          ),
        if (application.reviewedAt != null)
          _MetaRow(
            label: 'تاريخ المراجعة',
            value: dateFmt.format(application.reviewedAt!),
          ),
        if (application.rejectionReason != null)
          _MetaRow(
            label: 'السبب',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
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
                'وضع التطوير',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'هذا الزر للاختبار الداخلي فقط ولا يظهر في نسخة الإنتاج. '
            'يحاكي موافقة المشرف دون الحاجة إلى واجهة إدارة.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('محاكاة موافقة المشرف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade800,
                    side: const BorderSide(color: Colors.amber),
                  ),
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
