import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/recitation_comparison_result.dart';
import '../../domain/entities/recitation_target.dart';

enum RecitationPracticePhase {
  idle,
  listening,
  feedback,
  sessionComplete,
}

class RecitationPracticeState extends Equatable {
  const RecitationPracticeState({
    this.isPanelOpen = false,
    this.phase = RecitationPracticePhase.idle,
    this.targets = const <RecitationTarget>[],
    this.selectedTargetIndex = 0,
    this.liveTranscript = '',
    this.comparisonResult,
    this.failure,
    this.isInitializing = false,
    this.isSessionActive = false,
    this.completedTargetIndices = const <int>{},
  });

  final bool isPanelOpen;
  final RecitationPracticePhase phase;
  final List<RecitationTarget> targets;
  final int selectedTargetIndex;
  final String liveTranscript;
  final RecitationComparisonResult? comparisonResult;
  final Failure? failure;
  final bool isInitializing;
  final bool isSessionActive;
  final Set<int> completedTargetIndices;

  RecitationTarget? get selectedTarget {
    if (targets.isEmpty || selectedTargetIndex >= targets.length) {
      return null;
    }
    return targets[selectedTargetIndex];
  }

  int? targetIndexForAyah(int surahNumber, int ayahNumber) {
    final int index = targets.indexWhere(
      (RecitationTarget target) =>
          target.surahNumber == surahNumber && target.ayahNumber == ayahNumber,
    );
    return index >= 0 ? index : null;
  }

  bool isAyahCompleted(int surahNumber, int ayahNumber) {
    final int? index = targetIndexForAyah(surahNumber, ayahNumber);
    return index != null && completedTargetIndices.contains(index);
  }

  RecitationPracticeState copyWith({
    bool? isPanelOpen,
    RecitationPracticePhase? phase,
    List<RecitationTarget>? targets,
    int? selectedTargetIndex,
    String? liveTranscript,
    RecitationComparisonResult? comparisonResult,
    bool clearComparisonResult = false,
    Failure? failure,
    bool clearFailure = false,
    bool? isInitializing,
    bool? isSessionActive,
    Set<int>? completedTargetIndices,
    bool clearCompletedTargetIndices = false,
  }) {
    return RecitationPracticeState(
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
      phase: phase ?? this.phase,
      targets: targets ?? this.targets,
      selectedTargetIndex: selectedTargetIndex ?? this.selectedTargetIndex,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      comparisonResult: clearComparisonResult
          ? null
          : (comparisonResult ?? this.comparisonResult),
      failure: clearFailure ? null : (failure ?? this.failure),
      isInitializing: isInitializing ?? this.isInitializing,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      completedTargetIndices: clearCompletedTargetIndices
          ? const <int>{}
          : (completedTargetIndices ?? this.completedTargetIndices),
    );
  }

  @override
  List<Object?> get props => [
    isPanelOpen,
    phase,
    targets,
    selectedTargetIndex,
    liveTranscript,
    comparisonResult,
    failure,
    isInitializing,
    isSessionActive,
    completedTargetIndices,
  ];
}
