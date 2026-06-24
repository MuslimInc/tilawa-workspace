import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../config/quran_sessions_analytics_callbacks.dart';
import '../config/quran_sessions_feature_config.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_list/teacher_list_bloc.dart';
import '../blocs/teacher_list/teacher_list_event.dart';
import '../blocs/teacher_list/teacher_list_state.dart';
import '../widgets/quran_sessions_student_empty_state.dart';
import '../widgets/teacher_card.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quranSessionsHomeTitle),
        actions: [
          if (widget.onWallet != null)
            TextButton(
              onPressed: widget.onWallet,
              child: Text(l10n.walletEntryAction),
            ),
          if (widget.onMySessions != null)
            TextButton(
              onPressed: widget.onMySessions,
              child: Text(l10n.mySessionsTitle),
            ),
        ],
      ),
      body: BlocBuilder<TeacherListBloc, TeacherListState>(
        builder: (context, state) => switch (state) {
          TeacherListInitial() || TeacherListLoading() => const Center(
            child: CircularProgressIndicator(),
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
          TeacherListFailure(:final failure) => Center(
            child: Padding(
              padding: EdgeInsets.all(context.tokens.spaceLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(failure.toLocalizedMessage(context)),
                  SizedBox(height: context.tokens.spaceMedium),
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
          TeacherListSuccess(:final teachers) => ListView.builder(
            padding: EdgeInsets.all(context.tokens.spaceMedium),
            itemCount: teachers.take(3).length + 1,
            itemBuilder: (context, i) {
              final preview = teachers.take(3).toList();
              if (i < preview.length) {
                return TeacherCard(
                  teacher: preview[i],
                  onTap: () => widget.onTeacherTapped?.call(preview[i].id),
                );
              }
              return TextButton(
                onPressed: widget.onSeeAllTeachers,
                child: Text(l10n.seeAllTeachers),
              );
            },
          ),
        },
      ),
    );
  }
}
