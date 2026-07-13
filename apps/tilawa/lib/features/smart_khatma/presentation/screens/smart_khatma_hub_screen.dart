import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/khatma_plan.dart';
import '../bloc/khatma_plan_bloc.dart';
import '../bloc/khatma_plan_event.dart';
import '../bloc/khatma_plan_state.dart';
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
            KhatmaPlanCreationReview(:final plan) => _KhatmaCreationReviewBody(
              plan: plan,
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
    final tokens = context.tokens;
    return ListView(
      padding: EdgeInsets.all(tokens.spaceLarge),
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
  int _startSurah = 1;
  int _endSurah = 114;
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
    _KhatmaBoundaryMode.surah => getPageNumber(_startSurah, 1),
    _KhatmaBoundaryMode.page => int.tryParse(_startPageController.text),
  };

  int? get _targetPage => switch (_mode) {
    _KhatmaBoundaryMode.surah =>
      _endSurah == 114
          ? KhatmaPlan.lastQuranPage
          : getPageNumber(_endSurah + 1, 1) - 1,
    _KhatmaBoundaryMode.page => int.tryParse(_endPageController.text),
  };

  bool get _hasValidBoundaries {
    final int? start = _startPage;
    final int? end = _targetPage;
    return start != null &&
        end != null &&
        start >= KhatmaPlan.firstQuranPage &&
        end <= KhatmaPlan.lastQuranPage &&
        start <= end;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bool isLoading = context.select<KhatmaPlanBloc, bool>(
      (bloc) => bloc.state is KhatmaPlanLoading,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceMedium,
        tokens.spaceSection,
        tokens.spaceMedium,
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
          SegmentedButton<_KhatmaBoundaryMode>(
            segments: [
              ButtonSegment(
                value: _KhatmaBoundaryMode.surah,
                label: Text(context.l10n.khatmaBoundaryBySurah),
              ),
              ButtonSegment(
                value: _KhatmaBoundaryMode.page,
                label: Text(context.l10n.khatmaBoundaryByPage),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) =>
                setState(() => _mode = selection.single),
          ),
          SizedBox(height: tokens.spaceLarge),
          if (_mode == _KhatmaBoundaryMode.surah)
            _KhatmaSurahBoundaryFields(
              startSurah: _startSurah,
              endSurah: _endSurah,
              onStartChanged: (value) => setState(() {
                _startSurah = value;
                if (_endSurah < value) _endSurah = value;
              }),
              onEndChanged: (value) => setState(() => _endSurah = value),
            )
          else
            _KhatmaPageBoundaryFields(
              startController: _startPageController,
              endController: _endPageController,
              onChanged: () => setState(() {}),
            ),
          SizedBox(height: tokens.spaceLarge),
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
                      : () => context.read<KhatmaPlanBloc>().add(
                          KhatmaPlanPreviewRequested(
                            durationDays: days,
                            startPage: _startPage!,
                            targetPage: _targetPage!,
                          ),
                        ),
                ),
            ],
          ),
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

class _KhatmaSurahBoundaryFields extends StatelessWidget {
  const _KhatmaSurahBoundaryFields({
    required this.startSurah,
    required this.endSurah,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final int startSurah;
  final int endSurah;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  @override
  Widget build(BuildContext context) {
    final bool arabic = Localizations.localeOf(context).languageCode == 'ar';
    String name(int surah) =>
        arabic ? getSurahNameArabic(surah) : getSurahNameEnglish(surah);
    return Column(
      spacing: context.tokens.spaceMedium,
      children: [
        DropdownButtonFormField<int>(
          initialValue: startSurah,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.khatmaStartSurah),
          items: [
            for (int surah = 1; surah <= 114; surah++)
              DropdownMenuItem(
                value: surah,
                child: Text('$surah. ${name(surah)}'),
              ),
          ],
          onChanged: (value) {
            if (value != null) onStartChanged(value);
          },
        ),
        DropdownButtonFormField<int>(
          key: ValueKey<int>(startSurah),
          initialValue: endSurah,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.l10n.khatmaEndSurah),
          items: [
            for (int surah = startSurah; surah <= 114; surah++)
              DropdownMenuItem(
                value: surah,
                child: Text('$surah. ${name(surah)}'),
              ),
          ],
          onChanged: (value) {
            if (value != null) onEndChanged(value);
          },
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
  const _KhatmaCreationReviewBody({required this.plan});

  final KhatmaPlan plan;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListView(
      padding: EdgeInsets.all(tokens.spaceLarge),
      children: [
        Text(
          context.l10n.khatmaReviewPlanTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: tokens.spaceLarge),
        TilawaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceMedium,
            children: [
              Text(
                context.l10n.khatmaRangePages(
                  plan.assignmentStartPage,
                  plan.assignmentEndPage,
                ),
              ),
              Text(context.l10n.khatmaDailyPages(plan.assignedTodayPages)),
              Text(context.l10n.khatmaTotalPages(plan.totalPages)),
              Text(context.l10n.khatmaStartPage(plan.startPage)),
              Text(context.l10n.khatmaTargetPage(plan.targetPage)),
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
          text: context.l10n.khatmaConfirmPlanAction,
          onPressed: () => context.read<KhatmaPlanBloc>().add(
            KhatmaPlanCreationConfirmed(plan),
          ),
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
          footer: _KhatmaHubProgressBar(
            value: plan.progress,
            percent: progressPercent,
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
                Text(context.l10n.khatmaRangePages(startPage, endPage)),
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
                icon: Icons.menu_book_rounded,
                title: plan.confirmedTodayPages == 0
                    ? context.l10n.khatmaStartTodayAction
                    : context.l10n.khatmaResumeTodayAction,
                subtitle: context.l10n.khatmaRangePages(startPage, endPage),
                semanticTint: TilawaSemanticTint.ink,
                onTap: () => openKhatmaReaderAndRefresh(context, plan),
              ),
            TilawaNavigationRow(
              icon: Icons.restart_alt_rounded,
              title: context.l10n.khatmaResetAction,
              subtitle: context.l10n.khatmaHubResetSubtitle,
              semanticTint: TilawaSemanticTint.neutral,
              onTap: () => confirmKhatmaPlanReset(context),
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _KhatmaHubProgressBar extends StatelessWidget {
  const _KhatmaHubProgressBar({
    required this.value,
    required this.percent,
  });

  final double value;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              tokens.resolveRadius(
                family: TilawaRadiusFamily.decorative,
                height: 6,
              ),
            ),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(width: tokens.spaceSmall),
        Text(
          '$percent%',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
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
    return Padding(
      padding: EdgeInsets.all(context.tokens.spaceLarge),
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
            text: context.l10n.khatmaResetCorruptAction,
            variant: TilawaButtonVariant.outline,
            onPressed: () => confirmKhatmaPlanReset(context),
          ),
        ],
      ),
    );
  }
}
