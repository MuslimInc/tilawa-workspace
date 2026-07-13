import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/khatma_plan.dart';
import '../../domain/khatma_plan_boundaries.dart';
import '../bloc/khatma_plan_bloc.dart';
import '../bloc/khatma_plan_event.dart';
import '../bloc/khatma_plan_state.dart';
import '../formatters/khatma_page_range_text.dart';
import '../widgets/smart_khatma_plan_actions.dart';

/// Feature hub for Smart Khatma — hero summary, plan actions, and navigation.
class SmartKhatmaHubScreen extends StatelessWidget {
  const SmartKhatmaHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TilawaCatalogAppBar.titleOnly(
        title: context.l10n.khatmaHubTitle,
        automaticallyImplyLeading: true,
        onBackPressed: () => context.pop(),
      ),
      body: BlocBuilder<KhatmaPlanBloc, KhatmaPlanState>(
        builder: (context, state) {
          return switch (state) {
            KhatmaPlanLoaded(:final plan, :final todayTarget) =>
              plan == null
                  ? const _KhatmaHubEmptyBody()
                  : plan.isCompleted
                  ? const _KhatmaHubCompletedBody()
                  : _KhatmaHubActiveBody(plan: plan, todayTarget: todayTarget),
            KhatmaPlanCreationReview(:final plan, :final isEditing) =>
              _KhatmaCreationReviewBody(
                plan: plan,
                isEditing: isEditing,
              ),
            KhatmaPlanFailure() => const _KhatmaHubErrorBody(),
            _ => const Center(child: TilawaLoadingIndicator()),
          };
        },
      ),
    );
  }
}

class _KhatmaHubCompletedBody extends StatelessWidget {
  const _KhatmaHubCompletedBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceLarge,
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceLarge,
      ),
      children: [
        TilawaHeroSummaryCard(
          label: context.l10n.khatmaCompletedTitle,
          metric: context.l10n.khatmaProgressCompleteMetric,
          badges: const [],
        ),
        SizedBox(height: tokens.spaceLarge),
        Text(
          context.l10n.khatmaCompletedSubtitle,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.spaceLarge),
        TilawaButton(
          text: context.l10n.khatmaStartAnotherAction,
          onPressed: () => context.read<KhatmaPlanBloc>().add(
            const KhatmaPlanResetRequested(),
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        TilawaButton(
          text: context.l10n.khatmaReturnToQuranAction,
          variant: TilawaButtonVariant.outline,
          onPressed: () => const QuranIndexRoute().go(context),
        ),
      ],
    );
  }
}

class _KhatmaHubEmptyBody extends StatefulWidget {
  const _KhatmaHubEmptyBody();

  @override
  State<_KhatmaHubEmptyBody> createState() => _KhatmaHubEmptyBodyState();
}

class _KhatmaHubEmptyBodyState extends State<_KhatmaHubEmptyBody> {
  bool _showCreation = false;
  _KhatmaBoundaryMode _mode = _KhatmaBoundaryMode.surah;
  _KhatmaScheduleMode _scheduleMode = _KhatmaScheduleMode.duration;
  int _startSurah = 1;
  int _startAyah = 1;
  int _endSurah = 114;
  int _endAyah = getVerseCount(114);
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  final TextEditingController _startPageController = TextEditingController(
    text: '1',
  );
  final TextEditingController _endPageController = TextEditingController(
    text: '604',
  );

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    super.dispose();
  }

  int? get _startPage => switch (_mode) {
    _KhatmaBoundaryMode.surah => KhatmaPlanBoundaries.pageForSurahAyah(
      _startSurah,
      _startAyah,
    ),
    _KhatmaBoundaryMode.page => int.tryParse(_startPageController.text),
  };

  int? get _targetPage => switch (_mode) {
    _KhatmaBoundaryMode.surah => KhatmaPlanBoundaries.pageForSurahAyah(
      _endSurah,
      _endAyah,
    ),
    _KhatmaBoundaryMode.page => int.tryParse(_endPageController.text),
  };

  bool get _hasValidBoundaries {
    final int? start = _startPage;
    final int? end = _targetPage;
    if (start == null || end == null) return false;
    if (_mode == _KhatmaBoundaryMode.surah) {
      return KhatmaPlanBoundaries.isOrderedSurahRange(
        startSurah: _startSurah,
        startAyah: _startAyah,
        endSurah: _endSurah,
        endAyah: _endAyah,
      );
    }
    return KhatmaPlanBoundaries.isValidPageRange(start, end);
  }

  int? _durationDaysForPreview() {
    if (_scheduleMode == _KhatmaScheduleMode.duration) return null;
    final int days = KhatmaPlanBoundaries.durationDaysFromTargetDate(
      startDate: DateTime.now(),
      targetDate: _targetDate,
    );
    return days.clamp(1, 365);
  }

  void _requestPreview(int durationDays) {
    final int? start = _startPage;
    final int? end = _targetPage;
    if (start == null || end == null) return;
    context.read<KhatmaPlanBloc>().add(
      KhatmaPlanPreviewRequested(
        durationDays: durationDays,
        startPage: start,
        targetPage: end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bool isLoading = context.select<KhatmaPlanBloc, bool>(
      (bloc) => bloc.state is KhatmaPlanLoading,
    );

    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceSection,
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceHuge,
      ),
      children: [
        TilawaHeroSummaryCard(
          label: context.l10n.khatmaEmptyTitle,
          metric: '—',
          badges: const [],
        ),
        SizedBox(height: tokens.spaceLarge),
        Text(
          context.l10n.khatmaEmptySubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        if (!_showCreation)
          TilawaButton(
            text: context.l10n.khatmaCreateAction,
            onPressed: () => setState(() => _showCreation = true),
          )
        else ...[
          TilawaSegmentedControl<_KhatmaBoundaryMode>(
            segments: [
              TilawaSegment(
                value: _KhatmaBoundaryMode.surah,
                label: context.l10n.khatmaBoundaryBySurah,
              ),
              TilawaSegment(
                value: _KhatmaBoundaryMode.page,
                label: context.l10n.khatmaBoundaryByPage,
              ),
            ],
            selectedValue: _mode,
            onValueChanged: (selection) => setState(() => _mode = selection),
          ),
          SizedBox(height: tokens.spaceLarge),
          if (_mode == _KhatmaBoundaryMode.surah)
            _KhatmaSurahBoundaryFields(
              startSurah: _startSurah,
              startAyah: _startAyah,
              endSurah: _endSurah,
              endAyah: _endAyah,
              onStartChanged: (surah, ayah) => setState(() {
                _startSurah = surah;
                _startAyah = ayah;
                if (_endSurah < surah ||
                    (_endSurah == surah && _endAyah < ayah)) {
                  _endSurah = surah;
                  _endAyah = ayah;
                }
              }),
              onEndChanged: (surah, ayah) => setState(() {
                _endSurah = surah;
                _endAyah = ayah;
              }),
            )
          else
            _KhatmaPageBoundaryFields(
              startController: _startPageController,
              endController: _endPageController,
              onChanged: () => setState(() {}),
            ),
          SizedBox(height: tokens.spaceLarge),
          TilawaSegmentedControl<_KhatmaScheduleMode>(
            segments: [
              TilawaSegment(
                value: _KhatmaScheduleMode.duration,
                label: context.l10n.khatmaScheduleByDuration,
              ),
              TilawaSegment(
                value: _KhatmaScheduleMode.targetDate,
                label: context.l10n.khatmaScheduleByTargetDate,
              ),
            ],
            selectedValue: _scheduleMode,
            onValueChanged: (selection) =>
                setState(() => _scheduleMode = selection),
          ),
          SizedBox(height: tokens.spaceLarge),
          if (_scheduleMode == _KhatmaScheduleMode.duration) ...[
            Text(
              context.l10n.khatmaChooseDuration,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spaceSmall),
            Wrap(
              spacing: tokens.spaceSmall,
              runSpacing: tokens.spaceSmall,
              children: [
                for (final days in const [7, 15, 30, 60])
                  TilawaButton(
                    text: context.l10n.khatmaDurationDays(days),
                    variant: TilawaButtonVariant.outline,
                    onPressed: isLoading || !_hasValidBoundaries
                        ? null
                        : () => _requestPreview(days),
                  ),
              ],
            ),
          ] else ...[
            Text(
              context.l10n.khatmaChooseTargetDate,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spaceSmall),
            TilawaButton(
              text: MaterialLocalizations.of(context).formatMediumDate(
                _targetDate,
              ),
              variant: TilawaButtonVariant.outline,
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _targetDate = picked);
                }
              },
            ),
            SizedBox(height: tokens.spaceSmall),
            TilawaButton(
              text: context.l10n.khatmaPreviewPlanAction,
              onPressed: isLoading || !_hasValidBoundaries
                  ? null
                  : () {
                      final int? days = _durationDaysForPreview();
                      if (days != null) _requestPreview(days);
                    },
            ),
          ],
          SizedBox(height: tokens.spaceSmall),
          TilawaButton(
            text: context.l10n.cancel,
            variant: TilawaButtonVariant.outline,
            onPressed: () => setState(() => _showCreation = false),
          ),
        ],
      ],
    );
  }
}

enum _KhatmaBoundaryMode { surah, page }

enum _KhatmaScheduleMode { duration, targetDate }

class _KhatmaSurahBoundaryFields extends StatelessWidget {
  const _KhatmaSurahBoundaryFields({
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
  final void Function(int surah, int ayah) onStartChanged;
  final void Function(int surah, int ayah) onEndChanged;

  @override
  Widget build(BuildContext context) {
    final bool arabic = Localizations.localeOf(context).languageCode == 'ar';
    String name(int surah) =>
        arabic ? getSurahNameArabic(surah) : getSurahNameEnglish(surah);
    return Column(
      spacing: context.tokens.spaceMedium,
      children: [
        TilawaDropdownField<int>(
          value: startSurah,
          semanticLabel: context.l10n.khatmaStartSurah,
          items: [
            for (int surah = 1; surah <= 114; surah++)
              TilawaDropdownItem(
                value: surah,
                label: '$surah. ${name(surah)}',
              ),
          ],
          onChanged: (surah) => onStartChanged(surah, 1),
        ),
        TilawaDropdownField<int>(
          key: ValueKey<int>(startSurah),
          value: startAyah,
          semanticLabel: context.l10n.khatmaStartAyah,
          items: [
            for (int ayah = 1; ayah <= getVerseCount(startSurah); ayah++)
              TilawaDropdownItem(
                value: ayah,
                label: context.l10n.khatmaAyahNumber(ayah),
              ),
          ],
          onChanged: (ayah) => onStartChanged(startSurah, ayah),
        ),
        TilawaDropdownField<int>(
          key: ValueKey<int>(startSurah * 1000 + startAyah),
          value: endSurah,
          semanticLabel: context.l10n.khatmaEndSurah,
          items: [
            for (int surah = startSurah; surah <= 114; surah++)
              TilawaDropdownItem(
                value: surah,
                label: '$surah. ${name(surah)}',
              ),
          ],
          onChanged: (surah) => onEndChanged(surah, getVerseCount(surah)),
        ),
        TilawaDropdownField<int>(
          key: ValueKey<int>(endSurah),
          value: endAyah,
          semanticLabel: context.l10n.khatmaEndAyah,
          items: [
            for (
              int ayah = endSurah == startSurah ? startAyah : 1;
              ayah <= getVerseCount(endSurah);
              ayah++
            )
              TilawaDropdownItem(
                value: ayah,
                label: context.l10n.khatmaAyahNumber(ayah),
              ),
          ],
          onChanged: (ayah) => onEndChanged(endSurah, ayah),
        ),
      ],
    );
  }
}

class _KhatmaPageBoundaryFields extends StatelessWidget {
  const _KhatmaPageBoundaryFields({
    required this.startController,
    required this.endController,
    required this.onChanged,
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    spacing: context.tokens.spaceMedium,
    children: [
      TilawaTextField(
        controller: startController,
        keyboardType: TextInputType.number,
        label: context.l10n.khatmaStartPageInput,
        helperText: context.l10n.khatmaPageBoundsHelp,
        onChanged: (_) => onChanged(),
      ),
      TilawaTextField(
        controller: endController,
        keyboardType: TextInputType.number,
        label: context.l10n.khatmaEndPageInput,
        helperText: context.l10n.khatmaPageBoundsHelp,
        onChanged: (_) => onChanged(),
      ),
    ],
  );
}

class _KhatmaCreationReviewBody extends StatelessWidget {
  const _KhatmaCreationReviewBody({
    required this.plan,
    this.isEditing = false,
  });

  final KhatmaPlan plan;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceLarge,
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        tokens.spaceLarge,
      ),
      children: [
        Text(
          isEditing
              ? context.l10n.khatmaEditPlanTitle
              : context.l10n.khatmaReviewPlanTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: tokens.spaceLarge),
        TilawaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceMedium,
            children: [
              Text(
                formatKhatmaPageRange(
                  context.l10n,
                  isEditing ? plan.startPage : plan.assignmentStartPage,
                  isEditing ? plan.targetPage : plan.assignmentEndPage,
                ),
              ),
              if (!isEditing)
                Text(context.l10n.khatmaDailyPages(plan.assignedTodayPages))
              else
                Text(context.l10n.khatmaDailyPages(plan.plannedDailyPages())),
              Text(context.l10n.khatmaTotalPages(plan.totalPages)),
              if (!isEditing) ...[
                Text(context.l10n.khatmaStartPage(plan.startPage)),
                Text(context.l10n.khatmaTargetPage(plan.targetPage)),
              ] else
                Text(context.l10n.khatmaDurationDays(plan.durationDays)),
              Text(
                context.l10n.khatmaExpectedCompletionDate(
                  MaterialLocalizations.of(context).formatMediumDate(
                    plan.expectedCompletionDate,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        TilawaButton(
          text: isEditing
              ? context.l10n.khatmaSavePlanChangesAction
              : context.l10n.khatmaConfirmPlanAction,
          onPressed: () {
            if (isEditing) {
              context.read<KhatmaPlanBloc>().add(
                KhatmaPlanEditConfirmed(
                  plan: plan,
                  durationDays: plan.durationDays,
                ),
              );
            } else {
              context.read<KhatmaPlanBloc>().add(
                KhatmaPlanCreationConfirmed(plan),
              );
            }
          },
        ),
        SizedBox(height: tokens.spaceSmall),
        TilawaButton(
          text: context.l10n.cancel,
          variant: TilawaButtonVariant.outline,
          onPressed: () => context.read<KhatmaPlanBloc>().add(
            const KhatmaPlanStarted(),
          ),
        ),
      ],
    );
  }
}

class _KhatmaHubActiveBody extends StatelessWidget {
  const _KhatmaHubActiveBody({
    required this.plan,
    required this.todayTarget,
  });

  final KhatmaPlan plan;
  final KhatmaTodayTarget? todayTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final now = DateTime.now();
    final progressPercent = (plan.progress * 100).round();
    final targetPages = todayTarget?.pages ?? plan.assignedTodayPages;
    final startPage = todayTarget?.startPage ?? plan.assignmentStartPage;
    final endPage = todayTarget?.endPage ?? plan.assignmentEndPage;
    final missedDays = todayTarget?.missedDays ?? 0;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        0,
        tokens.spaceSection,
        0,
        tokens.spaceHuge + kMeMuslimMinInteractiveDimension,
      ),
      children: [
        TilawaHeroSummaryCard(
          label: context.l10n.khatmaProgressSubtitle(
            plan.currentDay(now),
            plan.durationDays,
          ),
          metric: '$progressPercent%',
          badges: [
            TilawaHeroSummaryBadge(
              label: context.l10n.khatmaPagesShort(targetPages),
              icon: Icons.today_outlined,
              tint: TilawaSemanticTint.ink,
            ),
            TilawaHeroSummaryBadge(
              label: context.l10n.khatmaPagesShort(plan.remainingPages),
              tint: TilawaSemanticTint.parchment,
            ),
            TilawaHeroSummaryBadge(
              label: context.l10n.khatmaDaysShort(plan.remainingDays(now)),
              tint: TilawaSemanticTint.scholar,
            ),
          ],
          footer: TilawaHeroSummaryProgress(
            progress: plan.progress,
            valueLabel: '$progressPercent%',
          ),
        ),
        SizedBox(height: tokens.spaceLarge),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal:
                theme.componentTokens.settingsGroup.groupHorizontalPadding,
          ),
          child: TilawaCard(
            surface: TilawaCardSurface.flat,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spaceSmall,
              children: [
                Text(formatKhatmaPageRange(context.l10n, startPage, endPage)),
                Text(context.l10n.khatmaAssignedPages(targetPages)),
                Text(
                  context.l10n.khatmaConfirmedPages(plan.confirmedTodayPages),
                ),
                Text(
                  context.l10n.khatmaRemainingTodayPages(
                    plan.remainingTodayPages,
                  ),
                ),
                Text(
                  context.l10n.khatmaExpectedCompletionDate(
                    MaterialLocalizations.of(context).formatMediumDate(
                      plan.expectedCompletionDate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (missedDays > 0) ...[
          SizedBox(height: tokens.spaceLarge),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal:
                  theme.componentTokens.settingsGroup.groupHorizontalPadding,
            ),
            child: _KhatmaHubRecoveryPanel(
              onExtend: () {
                unawaited(confirmKhatmaExtension(context, plan));
              },
            ),
          ),
        ],
        SizedBox(height: tokens.spaceLarge),
        if (plan.isTodayCompleted) ...[
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal:
                  theme.componentTokens.settingsGroup.groupHorizontalPadding,
            ),
            child: TilawaCard(
              surface: TilawaCardSurface.flat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spaceSmall,
                children: [
                  Text(
                    context.l10n.khatmaTodayCompletedTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    context.l10n.khatmaTodayCompletedSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
        ],
        TilawaHubNavigationGroup(
          children: [
            if (!plan.isTodayCompleted)
              TilawaNavigationRow(
                emphasis: TilawaNavigationRowEmphasis.primary,
                icon: Icons.menu_book_rounded,
                title: plan.confirmedTodayPages == 0
                    ? context.l10n.khatmaStartTodayAction
                    : context.l10n.khatmaResumeTodayAction,
                subtitle: formatKhatmaPageRange(
                  context.l10n,
                  startPage,
                  endPage,
                ),
                semanticTint: TilawaSemanticTint.ink,
                onTap: () => openKhatmaReaderAndRefresh(context, plan),
              ),
            TilawaNavigationRow(
              emphasis: TilawaNavigationRowEmphasis.secondary,
              icon: Icons.edit_outlined,
              title: context.l10n.khatmaEditPlanAction,
              subtitle: context.l10n.khatmaEditPlanSubtitle,
              semanticTint: TilawaSemanticTint.scholar,
              onTap: () => showKhatmaEditPlanSheet(context, plan),
            ),
            TilawaNavigationRow(
              emphasis: TilawaNavigationRowEmphasis.tertiary,
              icon: Icons.delete_outline_rounded,
              title: context.l10n.khatmaDeletePlanAction,
              subtitle: context.l10n.khatmaHubResetSubtitle,
              semanticTint: TilawaSemanticTint.neutral,
              showsNavigationChevron: false,
              onTap: () => confirmKhatmaPlanReset(context),
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _KhatmaHubRecoveryPanel extends StatelessWidget {
  const _KhatmaHubRecoveryPanel({
    required this.onExtend,
  });

  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TilawaCard(
      surface: TilawaCardSurface.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spaceSmall,
        children: [
          Text(
            context.l10n.khatmaAdjustedPlan,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: tokens.spaceSmall,
            runSpacing: tokens.spaceSmall,
            children: [
              TilawaButton(
                text: context.l10n.khatmaExtendAction,
                variant: TilawaButtonVariant.outline,
                onPressed: onExtend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KhatmaHubErrorBody extends StatelessWidget {
  const _KhatmaHubErrorBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        context.tokens.spaceLarge,
        theme.componentTokens.settingsGroup.groupHorizontalPadding,
        context.tokens.spaceLarge,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: context.tokens.spaceMedium,
        children: [
          Text(
            context.l10n.khatmaUnavailable,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TilawaButton(
            text: context.l10n.retry,
            variant: TilawaButtonVariant.outline,
            onPressed: () => context.read<KhatmaPlanBloc>().add(
              const KhatmaPlanStarted(),
            ),
          ),
          TilawaButton(
            text: context.l10n.khatmaDeletePlanAction,
            variant: TilawaButtonVariant.outline,
            onPressed: () => confirmKhatmaPlanReset(context),
          ),
        ],
      ),
    );
  }
}
