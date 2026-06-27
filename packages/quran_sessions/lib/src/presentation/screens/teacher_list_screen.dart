import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../failure_ui/quran_sessions_failure_ui.dart';
import '../../domain/entities/quran_teacher.dart';
import '../blocs/teacher_list/teacher_list_bloc.dart';
import '../blocs/teacher_list/teacher_list_event.dart';
import '../blocs/teacher_list/teacher_list_state.dart';
import '../config/quran_sessions_feature_config.dart';
import '../models/teacher_availability_summary.dart';
import '../widgets/quran_sessions_student_empty_state.dart';
import '../widgets/quran_sessions_page_header.dart';
import '../widgets/quran_sessions_scaffold.dart';
import '../widgets/teacher_card.dart';
import '../widgets/teacher_card_compact_skeleton.dart';
import '../widgets/teacher_list_filter_bar.dart';
import '../widgets/teacher_list_filter_logic.dart';

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
  final _searchController = TextEditingController();
  TeacherListFilter _selectedFilter = TeacherListFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<TeacherListBloc>().add(const LoadTeachersRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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

  void _onFilterSelected(TeacherListFilter filter) {
    setState(() => _selectedFilter = filter);
    if (!filter.isClientSideOnly) {
      context.read<TeacherListBloc>().add(
        TeacherFilterChanged(specialization: filter.specializationCode),
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _onSearchClear() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return QuranSessionsScaffold(
      title: l10n.teacherListAppBarTitle,
      body: BlocBuilder<TeacherListBloc, TeacherListState>(
        builder: (context, state) => switch (state) {
          TeacherListInitial() || TeacherListLoading() => ListView(
            children: [
              _TeacherListHeader(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onSearchClear: _onSearchClear,
              ),
              TeacherListFilterBar(
                selected: _selectedFilter,
                onSelected: _onFilterSelected,
              ),
              SizedBox(height: tokens.spaceSmall),
              for (var i = 0; i < 4; i++) const TeacherCardCompactSkeleton(),
            ],
          ),
          TeacherListEmpty(
            :final activeSpecialization,
            :final activeLanguage,
          ) =>
            activeSpecialization != null || activeLanguage != null
                ? _FilteredEmptyView(
                    specialization: activeSpecialization,
                    language: activeLanguage,
                    onClearFilters: () {
                      setState(() => _selectedFilter = TeacherListFilter.all);
                      context.read<TeacherListBloc>().add(
                        const TeacherFilterChanged(),
                      );
                    },
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
            :final availabilitySummaries,
            :final isLoadingMore,
          ) =>
            _buildSuccessList(
              context,
              teachers: teachers,
              availabilitySummaries: availabilitySummaries,
              isLoadingMore: isLoadingMore,
            ),
        },
      ),
    );
  }

  Widget _buildSuccessList(
    BuildContext context, {
    required List<QuranTeacher> teachers,
    required Map<String, TeacherAvailabilitySummary> availabilitySummaries,
    required bool isLoadingMore,
  }) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final filtered = applyTeacherListClientFilter(
      teachers,
      _selectedFilter,
      availabilitySummaries,
    );
    final visible = filterTeachersByNameQuery(filtered, _searchQuery);
    final showClientEmpty =
        (_selectedFilter.isClientSideOnly && filtered.isEmpty) ||
        (_searchQuery.trim().isNotEmpty && visible.isEmpty);

    return RefreshIndicator(
      onRefresh: () async => _retry(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount:
            2 +
            (showClientEmpty ? 1 : visible.length) +
            (isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _TeacherListHeader(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onSearchClear: _onSearchClear,
            );
          }
          if (i == 1) {
            return TeacherListFilterBar(
              selected: _selectedFilter,
              onSelected: _onFilterSelected,
            );
          }

          final dataIndex = i - 2;
          if (showClientEmpty) {
            return Padding(
              padding: EdgeInsets.all(tokens.spaceLarge),
              child: Text(
                _emptyListMessage(l10n),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (dataIndex == visible.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceMedium),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final teacher = visible[dataIndex];
          return TeacherCard(
            teacher: teacher,
            onTap: () => _onTeacherTapped(teacher.id),
            availabilitySummary: availabilitySummaries[teacher.id],
          );
        },
      ),
    );
  }

  void _retry() =>
      context.read<TeacherListBloc>().add(const LoadTeachersRequested());

  void _onTeacherTapped(String teacherId) {
    widget.onTeacherTapped?.call(teacherId);
  }

  String _emptyListMessage(QuranSessionsLocalizations l10n) {
    if (_searchQuery.trim().isNotEmpty) {
      return l10n.noTeachersForSearchQuery(_searchQuery.trim());
    }
    return _selectedFilter == TeacherListFilter.availableToday
        ? l10n.noTeachersForAvailabilityFilter
        : l10n.noTeachersAvailableRightNow;
  }
}

class _TeacherListHeader extends StatelessWidget {
  const _TeacherListHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranSessionsPageHeader(
          title: l10n.teacherListTitle,
          subtitle: l10n.teacherListSubtitle,
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spaceMedium,
            0,
            tokens.spaceMedium,
            tokens.spaceSmall,
          ),
          child: TilawaSearchField(
            controller: searchController,
            hintText: l10n.teacherSearchHint,
            onChanged: onSearchChanged,
            onClear: onSearchClear,
            variant: TilawaSearchFieldVariant.standard,
          ),
        ),
      ],
    );
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
