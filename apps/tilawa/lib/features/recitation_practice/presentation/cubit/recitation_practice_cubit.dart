import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/recitation_comparison_result.dart';
import '../../domain/entities/recitation_session_config.dart';
import '../../domain/entities/recitation_target.dart';
import '../../domain/entities/speech_recognition_update.dart';
import '../../domain/repositories/speech_recognition_repository.dart';
import '../../domain/usecases/compare_recitation_use_case.dart';
import '../../domain/usecases/get_page_recitation_targets_use_case.dart';
import '../../domain/usecases/request_microphone_permission_use_case.dart';
import 'recitation_practice_state.dart';

@injectable
class RecitationPracticeCubit extends Cubit<RecitationPracticeState> {
  RecitationPracticeCubit(
    this._getPageTargets,
    this._compareRecitation,
    this._requestMicrophonePermission,
    this._speechRecognition,
  ) : super(const RecitationPracticeState());

  static const RecitationSessionConfig _sessionConfig =
      RecitationSessionConfig.defaults;

  final GetPageRecitationTargetsUseCase _getPageTargets;
  final CompareRecitationUseCase _compareRecitation;
  final RequestMicrophonePermissionUseCase _requestMicrophonePermission;
  final SpeechRecognitionRepository _speechRecognition;

  StreamSubscription<SpeechRecognitionUpdate>? _updateSubscription;
  bool _isAdvancingAyah = false;
  String _bestSpokenTranscript = '';
  double _bestScoreThisAyah = 0;

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
    if (state.isSessionActive ||
        state.selectedTarget == null ||
        state.isInitializing) {
      return;
    }

    final bool ready = await _ensureSpeechReady();
    if (!ready) {
      return;
    }

    await _updateSubscription?.cancel();
    _updateSubscription = _speechRecognition.watchRecognitionUpdates().listen(
      _onRecognitionUpdate,
    );
    _resetAyahTranscriptTracking();

    final startResult = await _speechRecognition.startListening();
    startResult.fold(
      (Failure failure) => emit(
        state.copyWith(
          isInitializing: false,
          failure: failure,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isInitializing: false,
          isSessionActive: true,
          phase: RecitationPracticePhase.listening,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> endSession({bool closePanel = false}) async {
    _isAdvancingAyah = false;
    await _stopListeningInternal();
    if (closePanel) {
      emit(const RecitationPracticeState());
      return;
    }
    emit(
      state.copyWith(
        isSessionActive: false,
        phase: RecitationPracticePhase.idle,
        liveTranscript: '',
        clearComparisonResult: true,
      ),
    );
  }

  Future<bool> _ensureSpeechReady() async {
    emit(
      state.copyWith(
        isInitializing: true,
        clearFailure: true,
        clearComparisonResult: true,
        liveTranscript: '',
      ),
    );

    final permissionResult = await _requestMicrophonePermission();
    final bool permissionGranted = permissionResult.fold(
      (Failure failure) {
        emit(
          state.copyWith(
            isInitializing: false,
            failure: failure,
          ),
        );
        return false;
      },
      (bool granted) => granted,
    );
    if (!permissionGranted) {
      if (state.failure == null) {
        emit(
          state.copyWith(
            isInitializing: false,
            failure: Failure.permissionDenied(
              'Microphone permission is required.',
            ),
          ),
        );
      }
      return false;
    }

    final initResult = await _speechRecognition.initialize();
    return initResult.fold(
      (Failure failure) {
        emit(
          state.copyWith(
            isInitializing: false,
            failure: failure,
          ),
        );
        return false;
      },
      (_) => true,
    );
  }

  void _resetAyahTranscriptTracking() {
    _bestSpokenTranscript = '';
    _bestScoreThisAyah = 0;
  }

  void _onRecognitionUpdate(SpeechRecognitionUpdate update) {
    final String sanitized = _compareRecitation.sanitizeSpokenTranscript(
      update.transcript,
    );
    if (sanitized.isEmpty) {
      return;
    }

    _emitLiveTranscript(sanitized);

    if (!state.isSessionActive ||
        state.phase != RecitationPracticePhase.listening ||
        _isAdvancingAyah) {
      return;
    }

    final RecitationComparisonResult? comparison = state.comparisonResult;
    if (comparison == null) {
      return;
    }

    if (comparison.score > _bestScoreThisAyah) {
      _bestScoreThisAyah = comparison.score;
      _bestSpokenTranscript = sanitized;
    }

    final bool passed =
        comparison.score >= _sessionConfig.passScoreThreshold;
    if (!passed && !update.isFinal) {
      return;
    }

    unawaited(_handleVerseComplete(sanitized));
  }

  Future<void> _handleVerseComplete(String transcript) async {
    if (_isAdvancingAyah || !state.isSessionActive) {
      return;
    }

    final RecitationTarget? target = state.selectedTarget;
    if (target == null) {
      return;
    }

    final String effectiveTranscript = _bestSpokenTranscript.trim().isNotEmpty
        ? _bestSpokenTranscript
        : _compareRecitation.sanitizeSpokenTranscript(transcript);
    if (effectiveTranscript.trim().isEmpty) {
      _isAdvancingAyah = false;
      return;
    }

    _isAdvancingAyah = true;

    final RecitationComparisonResult comparison = _compareRecitation(
      targetText: target.normalText,
      spokenText: effectiveTranscript,
    );

    final bool passed =
        comparison.score >= _sessionConfig.passScoreThreshold;
    final Set<int> completed = Set<int>.from(state.completedTargetIndices);
    if (passed) {
      completed.add(state.selectedTargetIndex);
    }

    emit(
      state.copyWith(
        phase: RecitationPracticePhase.feedback,
        liveTranscript: effectiveTranscript,
        comparisonResult: comparison,
        completedTargetIndices: completed,
        clearFailure: true,
      ),
    );

    if (passed) {
      final bool hasMoreAyahs =
          state.selectedTargetIndex < state.targets.length - 1;
      if (hasMoreAyahs) {
        await Future<void>.delayed(_sessionConfig.verseAdvanceDelay);
        await _advanceToNextAyah();
      } else {
        await Future<void>.delayed(_sessionConfig.verseAdvanceDelay);
        await _stopListeningInternal();
        emit(
          state.copyWith(
            isSessionActive: false,
            phase: RecitationPracticePhase.sessionComplete,
          ),
        );
      }
    } else {
      await Future<void>.delayed(_sessionConfig.retryDelay);
      await _restartListeningForCurrentAyah();
    }

    _isAdvancingAyah = false;
  }

  Future<void> _advanceToNextAyah() async {
    await _speechRecognition.stopListening();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final int nextIndex = state.selectedTargetIndex + 1;
    emit(
      state.copyWith(
        selectedTargetIndex: nextIndex,
        phase: RecitationPracticePhase.listening,
        liveTranscript: '',
        clearComparisonResult: true,
        clearFailure: true,
      ),
    );
    _resetAyahTranscriptTracking();
    await _speechRecognition.startListening();
  }

  Future<void> _restartListeningForCurrentAyah() async {
    await _speechRecognition.stopListening();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    emit(
      state.copyWith(
        phase: RecitationPracticePhase.listening,
        liveTranscript: '',
        clearComparisonResult: true,
        clearFailure: true,
      ),
    );
    _resetAyahTranscriptTracking();
    await _speechRecognition.startListening();
  }

  void _emitLiveTranscript(String transcript) {
    final RecitationTarget? target = state.selectedTarget;
    if (target == null) {
      return;
    }

    final RecitationComparisonResult? liveComparison =
        transcript.trim().isEmpty
        ? null
        : _compareRecitation(
            targetText: target.normalText,
            spokenText: transcript,
          );

    emit(
      state.copyWith(
        liveTranscript: transcript,
        comparisonResult: liveComparison,
        clearComparisonResult: liveComparison == null,
      ),
    );
  }

  Future<void> _stopListeningInternal() async {
    await _updateSubscription?.cancel();
    _updateSubscription = null;
    await _speechRecognition.stopListening();
  }

  @override
  Future<void> close() async {
    await _stopListeningInternal();
    await _speechRecognition.dispose();
    return super.close();
  }
}
