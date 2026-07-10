import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/booking_block_reason.dart';
import '../blocs/teacher_list/teacher_list_bloc.dart';
import '../blocs/teacher_list/teacher_list_event.dart';
import '../blocs/teacher_list/teacher_list_state.dart';
import '../config/quran_sessions_analytics_callbacks.dart';
import '../config/quran_sessions_feature_config.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../widgets/quran_sessions_page_header.dart';
import '../widgets/quran_sessions_scaffold.dart';
import '../widgets/quran_sessions_student_empty_state.dart';
import '../widgets/teacher_card.dart';
import '../widgets/teacher_card_compact_skeleton.dart';

/// Feature entry point — shows a compact teacher list with a "See all" link.
class QuranSessionsHomeScreen extends StatefulWidget {
  const QuranSessionsHomeScreen({
    super.key,
    required this.featureConfig,
    this.analytics,
    this.onSeeAllTeachers,
    this.onTeacherTapped,
    this.onMySessions,
    this.onWallet,
    this.onBecomeTeacher,
    this.onNotifyInterest,
    this.onChangeCity,
    this.showTeacherApplyEntry = true,
  });

  final QuranSessionsFeatureConfig featureConfig;
  final QuranSessionsAnalyticsCallbacks? analytics;
  final VoidCallback? onSeeAllTeachers;
  final void Function(String teacherId)? onTeacherTapped;
  final VoidCallback? onMySessions;
  final VoidCallback? onWallet;
  final VoidCallback? onBecomeTeacher;
  final VoidCallback? onNotifyInterest;
  final VoidCallback? onChangeCity;

  /// When false, hides teacher apply entry even if flags allow it (e.g. pending).
  final bool showTeacherApplyEntry;

  @override
  State<QuranSessionsHomeScreen> createState() =>
      _QuranSessionsHomeScreenState();
}

class _QuranSessionsHomeScreenState extends State<QuranSessionsHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherListBloc>().add(const LoadTeachersRequested());
  }

  void _onTeacherApplyTapped() {
    widget.analytics?.onTeacherApplyEntrySeen?.call();
    widget.onBecomeTeacher?.call();
  }

  void _onNotifyInterest() {
    widget.analytics?.onQuranSessionsNotifyInterestSubmitted?.call();
    widget.onNotifyInterest?.call();
    if (!mounted) return;
    TilawaFeedback.showToast(
      context,
      message: context.quranSessionsL10n.notifyInterestSubmitted,
      variant: TilawaFeedbackVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return QuranSessionsScaffold(
      title: l10n.teacherListAppBarTitle,
      actions: [
        if (widget.onWallet != null)
          QuranSessionsAppBarLink(
            label: l10n.walletEntryAction,
            onPressed: widget.onWallet!,
          ),
        if (widget.onMySessions != null)
          QuranSessionsAppBarLink(
            label: l10n.mySessionsTitle,
            onPressed: widget.onMySessions!,
          ),
      ],
      body: BlocBuilder<TeacherListBloc, TeacherListState>(
        builder: (context, state) => switch (state) {
          TeacherListInitial() || TeacherListLoading() => TilawaSkeleton(
            semanticLabel: l10n.teacherListLoadingLabel,
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (_, _) => const TeacherCardCompactSkeleton(),
            ),
          ),
          TeacherListEmpty() => QuranSessionsStudentEmptyState(
            featureConfig: widget.featureConfig,
            showTeacherApplyEntry: widget.showTeacherApplyEntry,
            onNotifyInterest: _onNotifyInterest,
            onChangeCity: widget.onChangeCity,
            onTeacherApplyEntry: widget.onBecomeTeacher != null
                ? _onTeacherApplyTapped
                : null,
            onEmptyStateSeen: widget.analytics?.onQuranSessionsEmptyStateSeen,
          ),
          TeacherListNoBookableTeachers(:final primaryBlockReason) =>
            _NoBookableTeachersEmptyState(
              onRetry: () => context.read<TeacherListBloc>().add(
                const LoadTeachersRequested(),
              ),
              blockReason: primaryBlockReason,
            ),
          TeacherListFailure(:final failure) => Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(failure.toLocalizedMessage(context)),
                  SizedBox(height: tokens.spaceSmall),
                  TilawaButton(
                    text: l10n.retry,
                    onPressed: () => context.read<TeacherListBloc>().add(
                      const LoadTeachersRequested(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // "See all teachers" lives in the sticky bottom action bar below —
          // see [bottomNavigationBar] — so it stays thumb-reachable instead of
          // trailing off the end of the scroll list.
          TeacherListSuccess(:final teachers, :final pricingQuote) =>
            ListView.builder(
              itemCount: teachers.take(3).length + 1,
              itemBuilder: (context, i) {
                final preview = teachers.take(3).toList();
                if (i == 0) {
                  return Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      tokens.spaceMedium,
                      tokens.spaceSmall,
                      tokens.spaceMedium,
                      tokens.spaceExtraSmall,
                    ),
                    child: QuranSessionsPageHeader(
                      subtitle: l10n.teacherListSubtitle,
                      compact: true,
                    ),
                  );
                }
                final teacherIndex = i - 1;
                return TeacherCard(
                  teacher: preview[teacherIndex],
                  onTap: () =>
                      widget.onTeacherTapped?.call(preview[teacherIndex].id),
                  pricing: pricingQuote,
                );
              },
            ),
        },
      ),
      bottomNavigationBar: widget.onSeeAllTeachers == null
          ? null
          : BlocBuilder<TeacherListBloc, TeacherListState>(
              builder: (context, state) {
                if (state is! TeacherListSuccess) {
                  return const SizedBox.shrink();
                }
                return TilawaBottomActionArea(
                  child: TilawaButton(
                    text: l10n.seeAllTeachers,
                    onPressed: widget.onSeeAllTeachers,
                    variant: TilawaButtonVariant.ghost,
                    size: TilawaButtonSize.large,
                    isFullWidth: true,
                  ),
                );
              },
            ),
    );
  }
}

class _NoBookableTeachersEmptyState extends StatelessWidget {
  const _NoBookableTeachersEmptyState({
    required this.onRetry,
    this.blockReason,
  });

  final VoidCallback onRetry;
  final BookingBlockReason? blockReason;

  ({String title, String subtitle}) _resolveCopy(
    QuranSessionsLocalizations l10n,
  ) {
    return switch (blockReason) {
      BookingBlockReason.paymentProviderUnavailable => (
        title: l10n.bookingPaidUnavailableTitle,
        subtitle: l10n.bookingPaidUnavailableSubtitle,
      ),
      BookingBlockReason.bookingDisabledByAdmin => (
        title: l10n.bookingDisabledByAdminTitle,
        subtitle: l10n.bookingDisabledByAdminSubtitle,
      ),
      BookingBlockReason.pricingConfigMissing => (
        title: l10n.pricingConfigIncompleteTitle,
        subtitle: l10n.pricingConfigIncompleteSubtitle,
      ),
      BookingBlockReason.marketDisabled => (
        title: l10n.marketDisabledBookingTitle,
        subtitle: l10n.marketDisabledBookingSubtitle,
      ),
      BookingBlockReason.teacherNotBookable => (
        title: l10n.teacherNotBookableTitle,
        subtitle: l10n.teacherNotBookableSubtitle,
      ),
      _ => (
        title: l10n.noTeachersAvailableRightNow,
        subtitle: l10n.sessionsEmptySubtitle,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final copy = _resolveCopy(l10n);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Theme.of(context).tokens.spaceLarge),
        child: TilawaIllustratedState(
          icon: Icons.hourglass_disabled_outlined,
          title: copy.title,
          subtitle: copy.subtitle,
          semanticLabel: copy.title,
          primaryAction: TilawaButton(
            text: l10n.retry,
            variant: TilawaButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ),
      ),
    );
  }
}
