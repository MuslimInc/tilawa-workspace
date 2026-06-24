import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_list/teacher_list_bloc.dart';
import '../blocs/teacher_list/teacher_list_event.dart';
import '../blocs/teacher_list/teacher_list_state.dart';
import '../config/quran_sessions_feature_config.dart';
import '../widgets/quran_sessions_student_empty_state.dart';
import '../widgets/teacher_card.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({
    super.key,
    required this.featureConfig,
    this.onTeacherTapped,
    this.onNotifyInterest,
    this.onChangeCity,
    this.onTeacherApplyEntry,
    this.onEmptyStateSeen,
  });

  final QuranSessionsFeatureConfig featureConfig;
  final void Function(String teacherId)? onTeacherTapped;
  final VoidCallback? onNotifyInterest;
  final VoidCallback? onChangeCity;
  final VoidCallback? onTeacherApplyEntry;
  final VoidCallback? onEmptyStateSeen;

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<TeacherListBloc>().add(const LoadTeachersRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TeacherListBloc>().add(const LoadMoreTeachersRequested());
    }
  }

  void _onNotifyInterest() {
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
      appBar: AppBar(title: Text(l10n.teacherListTitle)),
      body: BlocBuilder<TeacherListBloc, TeacherListState>(
        builder: (context, state) => switch (state) {
          TeacherListInitial() || TeacherListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          TeacherListEmpty(
            :final activeSpecialization,
            :final activeLanguage,
          ) =>
            activeSpecialization != null || activeLanguage != null
                ? _FilteredEmptyView(
                    specialization: activeSpecialization,
                    language: activeLanguage,
                    onClearFilters: () => context.read<TeacherListBloc>().add(
                      const TeacherFilterChanged(),
                    ),
                  )
                : QuranSessionsStudentEmptyState(
                    featureConfig: widget.featureConfig,
                    showTeacherApplyEntry: true,
                    onNotifyInterest: _onNotifyInterest,
                    onChangeCity: widget.onChangeCity,
                    onTeacherApplyEntry: widget.onTeacherApplyEntry,
                    onEmptyStateSeen: widget.onEmptyStateSeen,
                  ),
          TeacherListFailure(:final failure) => _ErrorView(
            message: failure.toLocalizedMessage(context),
            onRetry: _retry,
          ),
          TeacherListSuccess(
            :final teachers,
            :final isLoadingMore,
          ) =>
            RefreshIndicator(
              onRefresh: () async => _retry(),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: teachers.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == teachers.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.tokens.spaceMedium,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  return TeacherCard(
                    teacher: teachers[i],
                    onTap: () => _onTeacherTapped(teachers[i].id),
                  );
                },
              ),
            ),
        },
      ),
    );
  }

  void _retry() =>
      context.read<TeacherListBloc>().add(const LoadTeachersRequested());

  void _onTeacherTapped(String teacherId) {
    widget.onTeacherTapped?.call(teacherId);
  }
}

class _FilteredEmptyView extends StatelessWidget {
  const _FilteredEmptyView({
    this.specialization,
    this.language,
    required this.onClearFilters,
  });

  final String? specialization;
  final String? language;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final title = switch ((specialization, language)) {
      (final String spec, _) => l10n.noTeachersForSpecialization(spec),
      (null, final String lang) => l10n.noTeachersForLanguage(lang),
      _ => l10n.noTeachersAvailableRightNow,
    };

    return Center(
      child: TilawaIllustratedState(
        icon: Icons.search_off_outlined,
        title: title,
        semanticLabel: title,
        primaryAction: TilawaButton(
          text: l10n.clearTeacherFilters,
          variant: TilawaButtonVariant.secondary,
          onPressed: onClearFilters,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return Center(
      child: TilawaIllustratedState(
        icon: Icons.error_outline,
        title: message,
        primaryAction: TilawaButton(
          text: l10n.retry,
          onPressed: onRetry,
        ),
      ),
    );
  }
}
