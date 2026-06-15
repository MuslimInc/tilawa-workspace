import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/compared_word.dart';
import '../../domain/entities/recitation_target.dart';
import '../../domain/entities/word_match_status.dart';
import '../cubit/recitation_practice_cubit.dart';
import '../cubit/recitation_practice_state.dart';

class RecitationTranscriptView extends StatelessWidget {
  const RecitationTranscriptView({
    super.key,
    required this.words,
  });

  final List<ComparedWord> words;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color correctColor = theme.colorScheme.tertiary;
    final Color missingColor = theme.colorScheme.error;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: tokens.spaceExtraSmall,
        runSpacing: tokens.spaceExtraSmall,
        alignment: WrapAlignment.center,
        children: words
            .map((ComparedWord word) {
              final Color color = switch (word.status) {
                WordMatchStatus.correct => correctColor,
                WordMatchStatus.incorrect => missingColor,
                WordMatchStatus.missing => missingColor,
              };
              return Text(
                word.word,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class RecitationPracticePanel extends StatelessWidget {
  const RecitationPracticePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecitationPracticeCubit, RecitationPracticeState>(
      buildWhen: (previous, current) =>
          previous.isPanelOpen != current.isPanelOpen ||
          previous.phase != current.phase ||
          previous.selectedTarget != current.selectedTarget ||
          previous.selectedTargetIndex != current.selectedTargetIndex ||
          previous.targets != current.targets ||
          previous.liveTranscript != current.liveTranscript ||
          previous.comparisonResult != current.comparisonResult ||
          previous.failure != current.failure ||
          previous.isInitializing != current.isInitializing,
      builder: (context, state) {
        if (!state.isPanelOpen || state.selectedTarget == null) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final tokens = theme.tokens;
        final cubit = context.read<RecitationPracticeCubit>();
        final target = state.selectedTarget!;
        final l10n = context.l10n;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              left: tokens.spaceMedium,
              right: tokens.spaceMedium,
              bottom: context.floatingBottomPadding + tokens.spaceLarge,
            ),
            child: Material(
              color: theme.colorScheme.surface.withValues(alpha: 0.96),
              elevation: theme.cardTheme.elevation ?? 1,
              borderRadius: BorderRadius.circular(tokens.radiusLarge),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceMedium),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.recitationPracticeTitle(
                              target.surahNumber,
                              target.ayahNumber,
                            ),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: cubit.closePanel,
                          tooltip: l10n.close,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    if (state.targets.length > 1) ...[
                      SizedBox(height: tokens.spaceSmall),
                      _AyahTargetSelector(
                        targets: state.targets,
                        selectedIndex: state.selectedTargetIndex,
                        onSelected: cubit.selectTarget,
                      ),
                    ],
                    SizedBox(height: tokens.spaceSmall),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        target.displayText,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                    if (state.liveTranscript.isNotEmpty &&
                        state.phase == RecitationPracticePhase.listening &&
                        state.comparisonResult == null) ...[
                      SizedBox(height: tokens.spaceSmall),
                      Text(
                        state.liveTranscript,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (state.comparisonResult != null) ...[
                      SizedBox(height: tokens.spaceSmall),
                      RecitationTranscriptView(
                        words: state.comparisonResult!.words,
                      ),
                      SizedBox(height: tokens.spaceSmall),
                      LinearProgressIndicator(
                        value: state.comparisonResult!.score,
                        borderRadius: BorderRadius.circular(tokens.radiusSmall),
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        l10n.recitationPracticeScore(
                          (state.comparisonResult!.score * 100).round(),
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                    if (state.failure != null) ...[
                      SizedBox(height: tokens.spaceSmall),
                      Text(
                        state.failure!.message ?? l10n.error,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    SizedBox(height: tokens.spaceMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.phase == RecitationPracticePhase.feedback)
                          TilawaButton(
                            text: l10n.retry,
                            variant: TilawaButtonVariant.secondary,
                            onPressed: cubit.retry,
                          ),
                        if (state.phase == RecitationPracticePhase.feedback)
                          SizedBox(width: tokens.spaceSmall),
                        if (state.phase == RecitationPracticePhase.feedback)
                          TilawaButton(
                            text: l10n.recitationPracticeNextAyah,
                            variant: TilawaButtonVariant.secondary,
                            onPressed: () {
                              cubit.selectNextTarget();
                              unawaited(cubit.startListening());
                            },
                          ),
                        if (state.phase != RecitationPracticePhase.feedback)
                          FilledButton.icon(
                            onPressed: state.isInitializing
                                ? null
                                : () {
                                    if (state.phase ==
                                        RecitationPracticePhase.listening) {
                                      unawaited(cubit.stopListening());
                                    } else {
                                      unawaited(cubit.startListening());
                                    }
                                  },
                            icon: Icon(
                              state.phase == RecitationPracticePhase.listening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                            ),
                            label: Text(
                              state.phase == RecitationPracticePhase.listening
                                  ? l10n.recitationPracticeStop
                                  : l10n.recitationPracticeStart,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AyahTargetSelector extends StatelessWidget {
  const _AyahTargetSelector({
    required this.targets,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RecitationTarget> targets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(targets.length, (int index) {
          final RecitationTarget target = targets[index];
          final bool isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(
              right: index == targets.length - 1 ? 0 : tokens.spaceExtraSmall,
            ),
            child: ChoiceChip(
              label: Text('${target.surahNumber}:${target.ayahNumber}'),
              selected: isSelected,
              onSelected: (_) => onSelected(index),
            ),
          );
        }),
      ),
    );
  }
}
