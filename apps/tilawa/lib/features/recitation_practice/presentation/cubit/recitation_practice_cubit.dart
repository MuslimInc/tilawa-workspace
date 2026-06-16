import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../core/voice_recitation_log.dart';
import '../../domain/entities/recitation_comparison_result.dart';
import '../../domain/entities/recitation_session_config.dart';
import '../../domain/entities/recitation_target.dart';
import '../../domain/repositories/recitation_audio_verification_repository.dart';
import '../../domain/usecases/get_page_recitation_targets_use_case.dart';
import 'recitation_practice_state.dart';

@injectable
class RecitationPracticeCubit extends Cubit<RecitationPracticeState> {
  RecitationPracticeCubit(
    this._getPageTargets,
    this._audioVerification,
  ) : super(const RecitationPracticeState());

  static const RecitationSessionConfig _sessionConfig =
      RecitationSessionConfig.defaults;

  final GetPageRecitationTargetsUseCase _getPageTargets;
  final RecitationAudioVerificationRepository _audioVerification;

  bool _isCompletingAyah = false;

  Future<void> openForPage(int pageNumber) async {
    await _openWithTargets(_getPageTargets(pageNumber));
  }

  Future<void> openForAyah({
    required int pageNumber,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final List<RecitationTarget> targets = _getPageTargets(pageNumber);
    if (targets.isEmpty) {
      return;
    }

    final int selectedIndex = targets.indexWhere(
      (RecitationTarget target) =>
          target.surahNumber == surahNumber && target.ayahNumber == ayahNumber,
    );

    await _openWithTargets(
      targets,
      selectedTargetIndex: selectedIndex >= 0 ? selectedIndex : 0,
    );
  }

  Future<void> _openWithTargets(
    List<RecitationTarget> targets, {
    int selectedTargetIndex = 0,
  }) async {
    if (targets.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        isPanelOpen: true,
        targets: targets,
        selectedTargetIndex: selectedTargetIndex.clamp(0, targets.length - 1),
        phase: RecitationPracticePhase.idle,
        liveTranscript: '',
        clearComparisonResult: true,
        clearFailure: true,
        isSessionActive: false,
        clearCompletedTargetIndices: true,
      ),
    );

    await startSession();
  }

  void closePanel() {
    VoiceRecitationLog.i('closePanel');
    unawaited(endSession(closePanel: true));
  }

  void selectTarget(int index) {
    if (state.isSessionActive || index < 0 || index >= state.targets.length) {
      return;
    }

    emit(
      state.copyWith(
        selectedTargetIndex: index,
        phase: RecitationPracticePhase.idle,
        liveTranscript: '',
        clearComparisonResult: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> startSession() async {
    final RecitationTarget? target = state.selectedTarget;
    if (state.isSessionActive || target == null || state.isInitializing) {
      return;
    }

    emit(
      state.copyWith(
        isInitializing: true,
        clearFailure: true,
        clearComparisonResult: true,
        liveTranscript: '',
      ),
    );

    final startResult = await _audioVerification.startRecording(target);
    startResult.fold(
      (Failure failure) {
        VoiceRecitationLog.w('recording start failed ${failure.message}');
        emit(
          state.copyWith(
            isInitializing: false,
            isSessionActive: false,
            failure: failure,
          ),
        );
      },
      (_) {
        VoiceRecitationLog.i(
          'recording started surah=${target.surahNumber} '
          'ayah=${target.ayahNumber}',
        );
        emit(
          state.copyWith(
            isInitializing: false,
            isSessionActive: true,
            phase: RecitationPracticePhase.listening,
            clearFailure: true,
          ),
        );
      },
    );
  }

  Future<void> endSession({bool closePanel = false}) async {
    if (closePanel) {
      await _audioVerification.cancel();
      emit(const RecitationPracticeState());
      return;
    }

    if (!state.isSessionActive) {
      emit(
        state.copyWith(
          isSessionActive: false,
          phase: RecitationPracticePhase.idle,
          liveTranscript: '',
          clearComparisonResult: true,
        ),
      );
      return;
    }

    await _verifyCurrentRecording();
  }

  Future<void> _verifyCurrentRecording() async {
    if (_isCompletingAyah) {
      return;
    }

    final RecitationTarget? target = state.selectedTarget;
    if (target == null) {
      return;
    }

    _isCompletingAyah = true;
    emit(state.copyWith(isInitializing: true, clearFailure: true));

    final verificationResult = await _audioVerification.stopAndVerify(target);
    await verificationResult.fold(
      (Failure failure) async {
        VoiceRecitationLog.w('audio verification failed ${failure.message}');
        emit(
          state.copyWith(
            isInitializing: false,
            isSessionActive: false,
            phase: RecitationPracticePhase.feedback,
            failure: failure,
          ),
        );
      },
      (RecitationComparisonResult comparison) async {
        await _handleVerificationResult(comparison);
      },
    );
    _isCompletingAyah = false;
  }

  Future<void> _handleVerificationResult(
    RecitationComparisonResult comparison,
  ) async {
    final bool passed = comparison.score >= _sessionConfig.passScoreThreshold;
    final Set<int> completed = Set<int>.from(state.completedTargetIndices);
    if (passed) {
      completed.add(state.selectedTargetIndex);
    }

    emit(
      state.copyWith(
        isInitializing: false,
        isSessionActive: false,
        phase: passed
            ? RecitationPracticePhase.feedback
            : RecitationPracticePhase.idle,
        comparisonResult: comparison,
        completedTargetIndices: completed,
        clearFailure: true,
      ),
    );

    if (!passed) {
      return;
    }

    final bool hasMoreAyahs =
        state.selectedTargetIndex < state.targets.length - 1;
    if (!hasMoreAyahs) {
      await Future<void>.delayed(_sessionConfig.verseAdvanceDelay);
      emit(
        state.copyWith(
          isSessionActive: false,
          phase: RecitationPracticePhase.sessionComplete,
        ),
      );
      return;
    }

    await Future<void>.delayed(_sessionConfig.verseAdvanceDelay);
    emit(
      state.copyWith(
        selectedTargetIndex: state.selectedTargetIndex + 1,
        phase: RecitationPracticePhase.idle,
        liveTranscript: '',
        clearComparisonResult: true,
        clearFailure: true,
      ),
    );
    await startSession();
  }

  @override
  Future<void> close() async {
    await _audioVerification.cancel();
    await _audioVerification.dispose();
    return super.close();
  }
}
