import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../data/datasources/tasbeeh_local_datasource.dart';
import '../../data/repositories/tasbeeh_repository_impl.dart';
import '../../domain/constants/tasbeeh_constants.dart';
import '../../domain/services/tasbeeh_target_feedback_service.dart';
import '../../domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import '../../domain/usecases/get_saved_tasbeeh_use_case.dart';
import '../../domain/usecases/increment_tasbeeh_count_use_case.dart';
import '../../domain/usecases/reset_tasbeeh_count_use_case.dart';
import '../../domain/usecases/save_custom_tasbeeh_use_case.dart';
import '../../domain/usecases/set_tasbeeh_target_count_use_case.dart';
import '../cubit/tasbeeh_cubit.dart';
import '../cubit/tasbeeh_state.dart';
import '../services/haptic_tasbeeh_target_feedback_service.dart';
import '../widgets/athkar_ambient_background.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key, this.cubit});

  final TasbeehCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TasbeehCubit>(
      create: (_) => cubit ?? _buildCubit()
        ..loadSavedDhikr(),
      child: const _TasbeehView(),
    );
  }

  TasbeehCubit _buildCubit() {
    final localDataSource = TasbeehLocalDataSourceImpl(Hive);
    final repository = TasbeehRepositoryImpl(localDataSource);
    final TasbeehTargetFeedbackService feedbackService =
        HapticTasbeehTargetFeedbackService();
    return TasbeehCubit(
      getSavedTasbeeh: GetSavedTasbeehUseCase(repository),
      saveCustomTasbeeh: SaveCustomTasbeehUseCase(repository),
      incrementTasbeehCount: IncrementTasbeehCountUseCase(repository),
      resetTasbeehCount: ResetTasbeehCountUseCase(repository),
      setTasbeehTargetCount: SetTasbeehTargetCountUseCase(repository),
      deleteTasbeehDhikr: DeleteTasbeehDhikrUseCase(repository),
      feedbackService: feedbackService,
    );
  }
}

class _TasbeehView extends StatelessWidget {
  const _TasbeehView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehCubit, TasbeehState>(
      builder: (context, state) {
        final cubit = context.read<TasbeehCubit>();
        late final Widget content;
        Widget? bottomActions;

        switch (state.viewMode) {
          case TasbeehViewMode.options:
          case TasbeehViewMode.counting:
            content = _TasbeehCountingView(cubit: cubit, state: state);
            bottomActions = _TasbeehCountingActions(cubit: cubit, state: state);
          case TasbeehViewMode.create:
            content = _TasbeehCreateView(cubit: cubit, state: state);
            bottomActions = _TasbeehCreateActions(cubit: cubit, state: state);
          case TasbeehViewMode.history:
            content = _TasbeehHistoryView(cubit: cubit, state: state);
        }

        final bool isSubView =
            state.viewMode == TasbeehViewMode.create ||
            state.viewMode == TasbeehViewMode.history;

        return Scaffold(
          appBar: TilawaCatalogAppBar(
            preferredHeight:
                TilawaAppBarConfig.catalogTitleOnlyHeight(context),
            title: context.l10n.tasbeehCategory,
            leading: isSubView
                ? TilawaBackButton(
                    compact: true,
                    onPressed: cubit.startCounting,
                  )
                : context.canPop()
                ? TilawaBackButton(
                    compact: true,
                    onPressed: () => context.pop(),
                  )
                : null,
          ),
          body: Stack(
            children: [
              const Positioned.fill(child: AthkarAmbientBackground()),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        child: content,
                      ),
                    ),
                    if (bottomActions != null)
                      _TasbeehBottomActionArea(child: bottomActions),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Counting view ────────────────────────────────────────────────────────────

class _TasbeehCountingView extends StatelessWidget {
  const _TasbeehCountingView({required this.cubit, required this.state});

  final TasbeehCubit cubit;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final selected = state.selectedDhikr;
    final displayCount = selected != null ? state.selectedCount : state.freeCount;
    final progress = selected == null || selected.targetCount <= 0
        ? 0.0
        : (state.selectedCount / selected.targetCount).clamp(0.0, 1.0);

    return _TasbeehContentBounds(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action row
            Row(
              children: [
                Expanded(
                  child: TilawaButton(
                    text: context.l10n.tasbeehAddNewOptionTitle,
                    leadingIcon: const Icon(Icons.add_rounded),
                    variant: TilawaButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: cubit.showCreateView,
                  ),
                ),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: TilawaButton(
                    text: context.l10n.tasbeehViewHistoryOptionTitle,
                    leadingIcon: const Icon(Icons.history_rounded),
                    variant: TilawaButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: cubit.showHistoryView,
                  ),
                ),
              ],
            ),

            SizedBox(height: tokens.spaceMedium),

            // Target chip — only when a saved dhikr is active
            if (selected != null) ...[
              TilawaStatusChip(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceMedium,
                  vertical: tokens.spaceSmall,
                ),
                icon: Icons.flag_rounded,
                label: context.l10n.tasbeehCurrentTarget(selected.targetCount),
              ),
              SizedBox(height: tokens.spaceMedium),
            ],

            // Counter card (tappable area)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: selected != null
                    ? cubit.incrementSelected
                    : cubit.incrementFreeCount,
                child: _ShakeOnTrigger(
                  trigger: state.vibrationEventCount,
                  child: TilawaCard(
                    borderRadius: tokens.radiusExtraLarge,
                    surface: TilawaCardSurface.raised,
                    backgroundColor: colorScheme.surface,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Count circle
                          Container(
                            padding: EdgeInsets.all(tokens.spaceExtraLarge),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary.withValues(
                                alpha: tokens.opacitySubtle,
                              ),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: tokens.opacityMedium,
                                ),
                                width: tokens.borderWidthThin,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: tokens.opacityShadow * 0.35,
                                  ),
                                  blurRadius: tokens.blurShadow,
                                  offset: tokens.shadowOffsetSmall,
                                ),
                              ],
                            ),
                            child: Text(
                              '$displayCount',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),

                          SizedBox(height: tokens.spaceLarge),

                          // Progress bar — only when target is active
                          if (selected != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                tokens.radiusExtraLarge,
                              ),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: tokens.progressHeight,
                                backgroundColor:
                                    colorScheme.outlineVariant.withValues(
                                      alpha: tokens.opacitySubtle,
                                    ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(height: tokens.spaceMedium),
                          ],

                          Text(
                            context.l10n.tasbeehTapToCount,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create view ──────────────────────────────────────────────────────────────

class _TasbeehCreateView extends StatelessWidget {
  const _TasbeehCreateView({required this.cubit, required this.state});

  final TasbeehCubit cubit;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return _TasbeehContentBounds(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spaceLarge),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: TilawaCard(
                borderRadius: tokens.radiusExtraLarge,
                surface: TilawaCardSurface.raised,
                backgroundColor: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.tasbeehAddNewOptionTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: tokens.spaceMedium),
                    TilawaTextField(
                      hintText: context.l10n.tasbeehInputHint,
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      onChanged: cubit.updateDraftText,
                      maxLength: TasbeehConstants.maxTextLength,
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    TilawaTextField(
                      hintText: '${TasbeehConstants.defaultTargetCount}',
                      prefixIcon: const Icon(Icons.flag_rounded),
                      onChanged: cubit.updateDraftTargetText,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── History view ─────────────────────────────────────────────────────────────

class _TasbeehHistoryView extends StatelessWidget {
  const _TasbeehHistoryView({required this.cubit, required this.state});

  final TasbeehCubit cubit;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return _TasbeehContentBounds(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.savedDhikr.isNotEmpty) ...[
              Text(
                context.l10n.tasbeehChooseSavedDhikr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
            ],
            Expanded(
              child: state.savedDhikr.isEmpty
                  ? TilawaIllustratedState(
                      visual: const TilawaStateVisual(
                        icon: Icons.history_toggle_off_rounded,
                        tone: TilawaStateVisualTone.tertiary,
                      ),
                      title: context.l10n.tasbeehHistoryEmpty,
                      semanticLabel: context.l10n.tasbeehHistoryEmpty,
                    )
                  : ListView.separated(
                      itemCount: state.savedDhikr.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: tokens.spaceSmall),
                      itemBuilder: (context, index) {
                        final item = state.savedDhikr[index];
                        // The delete button must live OUTSIDE the TilawaCard.
                        // TilawaCard's onTap is a Positioned.fill InkWell
                        // overlay (last in the Stack = on top), so any
                        // interactive widget placed inside the card content is
                        // never reached by hit-testing.
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TilawaCard(
                                onTap: () =>
                                    cubit.selectDhikrAndStartCounting(item.id),
                                borderRadius: tokens.radiusLarge,
                                borderColor: theme.colorScheme.primary.withValues(
                                  alpha: tokens.opacitySubtle,
                                ),
                                backgroundColor: theme.colorScheme.surface.withValues(
                                  alpha: tokens.opacityGlass,
                                ),
                                child: Row(
                                  children: [
                                    TilawaIconBox(
                                      icon: Icons.radio_button_checked_rounded,
                                      iconColor: theme.colorScheme.primary,
                                      backgroundColor: theme.colorScheme.primary
                                          .withValues(alpha: tokens.opacitySubtle),
                                      borderRadius: tokens.radiusLarge,
                                    ),
                                    SizedBox(width: tokens.spaceMedium),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.text,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          SizedBox(height: tokens.spaceExtraSmall),
                                          Text(
                                            context.l10n.tasbeehCurrentTarget(
                                              item.targetCount,
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: tokens.spaceSmall),
                            TilawaIconActionButton(
                              icon: Icons.delete_outline_rounded,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHigh,
                              onTap: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) =>
                                      _TasbeehDeleteConfirmationDialog(
                                        tasbeehText: item.text,
                                      ),
                                );
                                if (shouldDelete == true) {
                                  await cubit.removeDhikr(item.id);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared structural widgets ─────────────────────────────────────────────────

class _TasbeehContentBounds extends StatelessWidget {
  const _TasbeehContentBounds({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tokens.contentMaxWidthSettings),
        child: child,
      ),
    );
  }
}

class _TasbeehBottomActionArea extends StatelessWidget {
  const _TasbeehBottomActionArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        tokens.spaceLarge,
      ),
      child: child,
    );
  }
}

// ── Bottom action bars ────────────────────────────────────────────────────────

class _TasbeehCreateActions extends StatelessWidget {
  const _TasbeehCreateActions({required this.cubit, required this.state});

  final TasbeehCubit cubit;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final errorText = _resolveTasbeehErrorText(context, state);
    final canSave =
        state.draftText.trim().isNotEmpty &&
        state.draftTargetText.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null) ...[
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
        ],
        TilawaButton(
          text: context.l10n.tasbeehGoToCounting,
          onPressed: canSave ? cubit.saveDraftDhikr : null,
          variant: TilawaButtonVariant.primary,
          isFullWidth: true,
        ),
      ],
    );
  }
}

class _TasbeehCountingActions extends StatelessWidget {
  const _TasbeehCountingActions({required this.cubit, required this.state});

  final TasbeehCubit cubit;
  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final errorText = _resolveTasbeehErrorText(context, state);
    final selected = state.selectedDhikr;
    final canReset =
        selected != null ? true : state.freeCount > 0;
    final onReset = selected != null
        ? cubit.resetSelected
        : cubit.resetFreeCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null) ...[
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
        ],
        TilawaButton(
          text: context.l10n.reset,
          variant: TilawaButtonVariant.outline,
          isFullWidth: true,
          onPressed: canReset ? onReset : null,
        ),
      ],
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

class _TasbeehDeleteConfirmationDialog extends StatelessWidget {
  const _TasbeehDeleteConfirmationDialog({required this.tasbeehText});

  final String tasbeehText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.delete),
      content: Text(context.l10n.tasbeehDeleteConfirmationMessage(tasbeehText)),
      actions: [
        TilawaButton(
          text: context.l10n.cancel,
          variant: TilawaButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TilawaButton(
          text: context.l10n.delete,
          variant: TilawaButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

// ── Shake animation ───────────────────────────────────────────────────────────

class _ShakeOnTrigger extends StatelessWidget {
  const _ShakeOnTrigger({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(trigger),
      tween: Tween<double>(begin: 0, end: trigger == 0 ? 0 : 1),
      // Bespoke shake-feedback timing: chrome tokens would dampen the visible
      // tasbeeh-count snap. Hand-tuned with the haptic pulse.
      duration: const Duration(milliseconds: 420),
      builder: (context, value, animatedChild) {
        final offsetX = math.sin(value * math.pi * 6) * 10 * (1 - value);
        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: animatedChild,
        );
      },
      child: child,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _resolveTasbeehErrorText(BuildContext context, TasbeehState state) {
  final failure = state.failure;
  if (failure is ValidationFailure) {
    return context.l10n.validationError;
  }
  return state.errorMessage ?? failure?.message;
}
